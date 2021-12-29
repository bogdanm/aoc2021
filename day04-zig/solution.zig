const std = @import("std");
const print = @import("std").debug.print;
const ArrayList = std.ArrayList;
const expect = @import("std").testing.expect;

// A single bingo entry number and a "found" flag
const bingo_cell = struct {
    n: u8,
    found: bool
};

// Definition of a single bingo board
const bingo_board = struct {
    cells: [25]bingo_cell,              // the actual cells
    line_cnt: [5]u32,                   // total elements marked on a line
    col_cnt: [5]u32,                    // total elements marked on a column
    n_added: u32,                       // number of cells added to the board
    win_n: u8,                          // the number that won this board
    last_n: u8,                         // the last number added to this board

    pub fn init() bingo_board {
        // I was today years old when I learned that there's no numeric for in zig.
        // Interesting design choice, but easily solved by a while loop.
        var b: bingo_board = undefined;
        var i: usize = 0;
        // Initialize all counters to 0
        while (i < 5) : (i += 1) {
            b.line_cnt[i] = 0;
            b.col_cnt[i] = 0;
        }
        b.n_added = 0;
        b.last_n = undefined;
        return b;
    }

    // Add the cell with the given number. The cells are added sequentially in column-first order.
    pub fn add_cell(self: *bingo_board, n: u8) void {
        self.cells[self.n_added].n = n;
        self.cells[self.n_added].found = false;
        self.n_added += 1;
    }

    // Return true if this board is a winning board, false otherwise
    pub fn has_won(self: bingo_board) bool {
        var idx: usize = 0;
        var res = false;
        // If we find a single counter that is 5, this board has won
        while (idx < 5) : (idx += 1) {
            if (self.line_cnt[idx] == 5 or self.col_cnt[idx] == 5) {
                res = true;
                break;
            }
        }
        return res;
    }

    // Returns true if this board was fully initialized, false otherwise
    pub fn is_initialized(self: bingo_board) bool {
        return self.n_added == 25;
    }

    // Process the current input by checking if it is part of the board and mark the entry accordingly
    pub fn process(self: *bingo_board, n: u8) void {
        var res = false;
        var idx: usize = 0;

        while (idx < 25) : (idx += 1) {
            if ((self.cells[idx].n == n) and (self.cells[idx].found == false)) {
                self.cells[idx].found = true;
                // Find line/column and update counters accordingy
                var y: usize = idx / 5;
                var x: usize = idx % 5;
                self.line_cnt[y] += 1;
                self.col_cnt[x] += 1;
                self.last_n = n;
            }
        }
    }

    // Return the score of this board
    pub fn score(self: bingo_board) u32 {
        var res: u32 = 0;
        var idx: usize = 0;

        while (idx < 25) : (idx += 1) {
            if (self.cells[idx].found == false) {
                res += self.cells[idx].n;
            }
        }
        return res * self.last_n;
    }

    // Reset the data in this board (all cells unmarked, all counters 0)
    pub fn reset(self: *bingo_board) void {
        var idx: usize = 0;

        while (idx < 25) : (idx += 1) {
            self.cells[idx].found = false;
        }
        idx = 0;
        while (idx < 5) : (idx += 1) {
            self.line_cnt[idx] = 0;
            self.col_cnt[idx] = 0;
        }
        self.last_n = undefined;
    }
};

fn nextLine(reader: anytype, buffer: []u8) !?[]const u8 {
    var line = (try reader.readUntilDelimiterOrEof(buffer, '\n')) orelse return null;
    // trim annoying windows-only carriage return character
    if (std.builtin.os.tag == .windows) {
        line = std.mem.trimRight(u8, line, "\r");
    }
    return line;
}

pub fn main() !void {
    const file = try std.fs.cwd().openFile("input.txt", .{ .read = true });
    defer file.close();
    const allocator = std.testing.allocator;

    // First line contains all the numbers
    var buffer: [400]u8 = undefined;
    var input = (try nextLine(file.reader(), &buffer)).?;
    // Parse the numbers and store them in an array
    var input_data = ArrayList(u8).init(allocator);
    defer input_data.deinit();
    var nums_it = std.mem.split(input, ",");
    while (nums_it.next()) |v| {
        try input_data.append(try std.fmt.parseInt(u8, v, 10));
    }

    // Continue reading until we're out of data
    var table_data: [25]u8 = undefined;
    var crt_board = bingo_board.init();
    var boards = ArrayList(bingo_board).init(allocator);
    defer boards.deinit();
    while (true) {
        input = (try nextLine(file.reader(), &buffer)) orelse break;
        input = std.mem.trim(u8, input, "\r\n ");
        if (input.len > 0) { // This line must define a board line, so parse it and add it to the current board
            var data_it = std.mem.split(input, " ");
            while (data_it.next()) |v| {
                if (v.len > 0) {
                    crt_board.add_cell(try std.fmt.parseInt(u8, v, 10));
                }
            }
        } else { // found an empty line, so save current board and recreate it for the next run
            if (crt_board.is_initialized()) {
                try boards.append(crt_board);
            }
            crt_board = bingo_board.init();
        }
    }
    // Add the last board read from the input (after eof)
    try expect(crt_board.is_initialized());
    try boards.append(crt_board);
    print("Found {d} boards.\n", .{boards.items.len});

    // Part 1: add input sequentially to all boards, stop when a complete board is found
    print("**** Part 1\n", .{});
    outer: for (input_data.items) |i| {
        for (boards.items) |*b, idx| {
            b.process(i);
            if (b.has_won()) {
                print("Board {d} won.\n", .{idx});
                print("Result: {}\n", .{b.score()});
                break :outer;
            }
        }
    }

    // Part 2: remember which board won last and the corresponding input
    print("**** Part 2\n", .{});
    for (boards.items) |*b| {
        b.reset();
    }
    // This time exhaust all input
    var last_win: *const bingo_board = undefined;
    for (input_data.items) |i| {
        for (boards.items) |*b, idx| {
            if (!b.has_won()) { // skip board that are already won
                b.process(i);
                if (b.has_won()) { // remember this win
                    print("{d} ", .{idx});
                    last_win = b;
                }
            }
        }
    }
    print("\nResult: {}\n", .{last_win.score()});
}