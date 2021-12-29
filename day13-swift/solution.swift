import Foundation

// ********************************************************************************************************************
// Local data and functions

// Simple enum that defines the direction of folds (up or left)
enum FoldDirection: String {
    case FoldUp = "y", FoldLeft = "x"
}

// Input data represented as a liniarized array
var data: [Int8] = []
// (x, y) pairs found in the input file
var input_pairs: [(Int32, Int32)] = []
// (fold_direction, fold_offset) pairs found in the input file
var input_folds: [(FoldDirection, Int32)] = []
// Number of lines and cols in the input data
var lines: Int32 = -1
var cols: Int32 = -1
// Number of lines and cols in the current "view" (changed when folding)
var view_lines: Int32 = 0
var view_cols: Int32 = 0

// Convert an (y, x) coordinate to an index in the "data" array
func crd2idx(y: Int32, x: Int32) -> Int {
    Int(y * cols + x)
}

// Read data and store it for later use. Implemented in an ugly way that modifies global variables
func read_data(_ path: String) {
    // Read all file in memory (I couldn't find a way to read the file line by line, at least not in Linux)
    let temp = try! String.init(contentsOfFile: path)
    // Check each line
    for l in temp.split(separator: "\n") {
        if l.isEmpty {
            continue
        } else if l.firstIndex(of: ",") != nil { // (x, y) pair, parse and add to input data
            let parts = l.split(separator: ",")
            let x = Int32(parts[0])!
            let y = Int32(parts[1])!
            // Also update the maximum line and column number, this will give us the size of the matrix
            lines = y > lines ? y : lines
            cols = x > cols ? x : cols
            input_pairs.append((x, y))
        } else { // this must be a folding instruction
            let plen = "fold along ".count
            let temp = l.suffix(from: l.index(l.startIndex, offsetBy: plen))
            let parts = temp.split(separator: "=")
            input_folds.append((FoldDirection(rawValue: String(parts[0]))!, Int32(parts[1])!))
        }
    }
    // Increment lines and columns since indexes are 0-based
    lines += 1
    cols += 1
}

// Return the element at the given coordinates
func get_at(y: Int32, x: Int32) -> Int8 {
    data[crd2idx(y: y, x: x)]
}

// Set the element at the given coordinates, optionally ORing with the current value
func set_at(y: Int32, x: Int32, v: Int8, orCurrent: Bool = false) {
    let crd = crd2idx(y: y, x: x)
    if (orCurrent) {
        data[crd] |= v
    } else {
        data[crd] = v
    }
}

// Execute a fold up instruction at line "d"
func fold_up(_ d: Int32) {
    // Fold all lines after "d"
    for l in d + 1 ..< view_lines {
        let new_l = 2 * d - l // new line after folding
        if new_l >= 0 { // line still valid, keep on folding
            for c in 0 ..< view_cols { // fold each char on the current line
                set_at(y: new_l, x: c, v: get_at(y: l, x: c), orCurrent: true)
            }
        } else { // out of valid lines, done folding
            break
        }
    }
    // Update the number of lines in the view
    view_lines = d
}

// Execute a fold left instruction at column d
func fold_left(_ d: Int32) {
    // Fold all columns after "d"
    for c in d + 1 ..< view_cols {
        let new_c = 2 * d - c // new column after folding
        if new_c >= 0 { // column still valid, keep folding
            for l in 0 ..< view_lines { // fold each char on the current column
                set_at(y: l, x: new_c, v: get_at(y: l, x: c), orCurrent: true)
            }
        } else { // out of valid columns, done folding
            break
        }
    }
    // Update the number of columns in the view
    view_cols = d
}

// Return the number of 1 elements in the current view of the data
func get_ones() -> Int {
    var crt = 0
    for l in 0..<view_lines {
        for c in 0..<view_cols {
            if get_at(y: l, x: c) == 1 {
                crt += 1
            }
        }
    }
    return crt
}

// Print the current view of the input data
func print_data() {
    for l in 0..<view_lines {
        for c in 0..<view_cols {
            print(data[crd2idx(y: l, x: c)] == 1 ? "#" : ".", terminator: "")
        }
        print("")
    }
    print("")
}

// ********************************************************************************************************************
// Entry point

// Read and parse problem input
read_data("input.txt")

// Set the current view to the whole matrix
view_lines = lines
view_cols = cols
// Initialize input data to 0 for the whole matrix. This is a bit simplistic, but the array is small enough, so no harm done.
data = Array.init(repeating: 0, count: Int(lines * cols))
// Set the 1 values for each input pair
for (x, y) in input_pairs {
    set_at(y: y, x: x, v: 1)
}

// Start folding according to the instructions
var first = true
for (f, d) in input_folds {
    if f == FoldDirection.FoldLeft {
        fold_left(d)
    } else {
        fold_up(d)
    }
    if first { // print the number of elements after the first fold
        print("Part 1: ", get_ones())
        first = false
    }
}
print("Part 2: red the 8 letters below")
print_data()