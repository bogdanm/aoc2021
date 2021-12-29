import std.algorithm, std.stdio, std.string;
import std.container.array;
import std.conv;

// Simple point structure that keeps two coordinates.
struct Point {
    int y, x;

    // Return all the neighbors of this point. Because of the guards used in struct Data (below),
    // this function should never return a Point at an invalid position.
    public auto neighbors() {
        Point[4] res;

        res[0] = Point(y, x - 1);
        res[1] = Point(y, x + 1);
        res[2] = Point(y - 1, x);
        res[3] = Point(y + 1, x);
        return res;
    }
}

// The data in the array is a byte (the actual height) and a "marked" flag (used for solving part 2)
struct Data {
    byte b;
    bool marked;
}

// Data array used for storing the input
static alias int_array = Array!Data;
// Array of points used to store the positions of lows
static alias lows_array = Array!Point;

// Input data: actual input and its size
struct Input {
    uint lines;                         // number of lines in input
    uint cols;                          // numer of columns in input
    int_array data;                     // actual data is stored in a linearized array
    lows_array lows;                    // position of low points (found in part 1)
    static immutable byte INVALID = 10; // returned for invalid positions

    // Add a single line to the input data. Each char in the line is converted to a byte from 0 to 9.
    public void add_line(char[] l) {
        static bool first = true;

        if (first) { // first invocation: compute number of columns (including the guards) and add the top guard line
            cols = to!uint(l.length) + 2;
            add_guard_line();
            first = false;
        }
        data.insert(Data(INVALID, true)); // left guard
        foreach(c; l) {
            data.insert(Data(to!byte(c - '0'), false));
        }
        data.insert(Data(INVALID, true)); // right guard
        lines ++;
    }

    // Add a single guard line and increment number of lines
    private void add_guard_line() {
        for (uint i = 0; i < cols; i ++) {
            data.insert(Data(INVALID, true));
        }
        lines ++;
    }

    // Called after all the data in the input file was read: add the bottom guard line
    public void finish_input() {
        add_guard_line();
    }

    // Return the linearized index for the (y, x) position
    private auto pos2idx(int y, int x) {
        return to!uint(y) * cols + to!uint(x);
    }

    // Return the data at the given position or INVALID if no data is available
    private auto get_at(Point p) {
        return &data[pos2idx(p.y, p.x)];
    }

    // Same thing for direct y/x coordinates
    private auto get_at(int y, int x) {
        return &data[pos2idx(y, x)];
    }

    // Solve the first part
    public auto part1() {
        uint cnt = 0;

        // Iterate through all lines and columns that are not guards and count low points
        for(int y = 1; y < lines - 1; y ++ ) {
            for (int x = 1; x < cols - 1; x ++) {
                auto p = Point(y, x);
                byte c = get_at(p).b;
                // Consider all neighbors
                int less_cnt = p.neighbors().fold!((a, n) => a + (c < get_at(n).b ? 1 : 0))(0);
                if (less_cnt == 4) { // all neighbors are lower
                    cnt += to!uint(c) + 1;
                    lows.insert(p); // remember this low point for part 2 (below)
                }
            }
        }
        return cnt;
    }

    // Flood fill function for solving the second part
    private uint fill(Point where) {
        Data *d = get_at(where);
        // Invalid position, height 9 or already visited: return 0
        if ((d.b == INVALID) || (d.b == 9) || d.marked) {
            return 0;
        }
        // Mark this point as "visited"
        d.marked = true;
        // And iterate through all neighbors
        return where.neighbors().fold!((a, p) => a + fill(p))(1);
    }

    // Solve the second part
    public auto part2() {
        Array!uint basins; // this keeps the sizes of the basins
        foreach(c; lows) {
            // Unmark all non-guards
            for(int y = 1; y < lines - 1; y ++ ) {
                for (int x = 1; x < cols - 1; x ++) {
                    get_at(y, x).marked = false;
                }
            }
            // Run the flood fill function at the current  low location
            basins.insert(fill(c));
        }
        // Reverse sort the sizes array and return the product of the first 3 entries
        basins[0..$].sort!("a > b");
        return basins[0] * basins[1] * basins[2];
    }
}

// Read the data from file "name" and return it in an Input structure
static auto read_input(string name) {
    auto f = File(name);
    Input i;

    foreach(l; f.byLine()) {
        i.add_line(l);
    }
    i.finish_input();
    return i;
}

void main() {
    // Read and remember data
    Input data = read_input("input.txt");

    writeln("Part 1: ", data.part1());
    writeln("Part 2: ", data.part2());
}