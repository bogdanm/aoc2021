package main

import (
    "bufio"
    "fmt"
    "os"
    "strconv"
)

// Struct used to keep every line of the input plus one "active" flag to check if this entry is active or not
// (used for solving the second part)
type Entry struct {
    data   string
    active bool
}

// Count the number of 1 bits in all the elements of "v" in the given position "p". The elements that
// are inactive are skipped
func count_ones_in_vector(v []Entry, p int) int {
    var result int

    for i := 0; i < len(v); i++ {
        if v[i].active && (v[i].data[p] == '1') {
            result += 1
        }
    }

    return result
}

// Reduce the input vector to a single value according to the input rule
func reduce(v []Entry, oxygen bool) int {
    var crt_pos int = 0 // start from the first position

    // Unmask all values first
    total := len(v)
    for i := 0; i < total; i++ {
        v[i].active = true
    }
    for {
        // Compute current number of zeroes and ones (in crt_pos) for all active elements in v
        ones := count_ones_in_vector(v, crt_pos)
        zeroes := total - ones
        // Find what we need to keep according to current criteria (oxygen generator/co2 scrubber rating)
        var must_keep byte = '0'
        if oxygen {
            if ones >= zeroes { // equality: keey ones, otherwise keep most common
                must_keep = '1'
            }
        } else {
            if ones < zeroes { // equality: keep zeroes, otherwise keep least common
                must_keep = '1'
            }
        }
        // Filter according to above condition
        var res_idx int
        for i := 0; i < len(v); i++ {
            if v[i].active {
                if v[i].data[crt_pos] != must_keep { // mask this element since it doesn't have the expected bit value
                    v[i].active = false
                    total--
                } else { // remember the last position of an element that respects the above condition
                    res_idx = i
                }
            }
        }
        if total == 1 { // found our value of interest, which must be as res_idx since there's a single non-masked element in the vector
            res, _ := strconv.ParseInt(v[res_idx].data, 2, 32)
            return int(res)
        }
        // Advance to next bit
        crt_pos++
    }
}

func solve() {
    file, _ := os.Open("input.txt")

    // Read file line by line and keep the lines in the "input" array
    // We know that each entry is 12 bits because we looked at the input :)
    scanner := bufio.NewScanner(file)
    total := 0
    var input []Entry
    for scanner.Scan() {
        line := scanner.Text()
        total += 1                               // count total number of lines in input
        input = append(input, Entry{line, true}) // keep for later use
    }
    file.Close()

    // Part 1: we can now compute gamma / epsilon
    var g, e, mask uint32 = 0, 0, 1 << 11
    for i := 0; i < 12; i++ {
        if count_ones_in_vector(input, i) > total/2 {
            g |= mask
        } else {
            e |= mask
        }
        mask >>= 1
    }
    fmt.Println("Part 1:", g*e)

    // Part 2: compute the two required values (see "reduce" above for more details)
    v1 := reduce(input, true)
    v2 := reduce(input, false)
    fmt.Println("Part 2:", v1*v2)
}

func main() {
    solve()
}
