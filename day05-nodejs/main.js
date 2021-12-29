#!/usr/bin/env node

const readline = require('readline');
const fs = require('fs');

// Create and return a point iterator for the given line
function make_line_iterator(sx, sy, ex, ey) {
    if (sx === ex) { // vertical line iterator
        if (sy > ey) { // swap ends to simplify generator
            [sy, ey] = [ey, sy];
        }
        return function() {
            if (sy <= ey) {
                sy += 1;
                return [sx, sy - 1];
            } else {
                return undefined;
            }
        };
    } else { // horizontal/diagonal line iterator
        if (sx > ex) { // swap ends to simplify generator
            [sx, ex] = [ex, sx];
            [sy, ey] = [ey, sy];
        }
        const m = (ey - sy) / (ex - sx);
        const b = sy - m * sx;
        return function() {
            if (sx <= ex) {
                const yn = m * sx + b;
                sx += 1;
                return [sx - 1, yn];
            } else {
                return undefined;
            }
        };
    }
}

// Solve both parts. "first" is true to solve the first part, false to solve the seconds part.
// "mx" (the maximum x encountered while reading the data) is needed to compute a key for each
// point (key = x + y * mx)
function solve(data, mx, first) {
    // We keep all points that we find during processing in an object:
    //    - the key is the coordinate as an (x,y) string
    //    - the value is the number of times that point was found
    let points = {};
    data.forEach(e => {
        const [sx, sy] = e.start;
        const [ex, ey] = e.end;
        // Create an iterator that returns all the points on the line and "undefined"
        // when there are no more points.
        if ((!first) || (sx === ex) || (sy === ey)) { // only h/v lines are allowed in part 1
            const i = make_line_iterator(sx, sy, ex, ey);
            while (true) {
                const v = i();
                if (v === undefined) { // no more points
                    break;
                } else {
                    // The keys are integers (y * mx + x)
                    const key = v[0] + v[1] * mx;
                    // Increment key if found, create it if not found
                    if (points.hasOwnProperty(key)) {
                        points[key] ++;
                    } else {
                        points[key] = 1;
                    }
                }
            }
        }
    });
    // Now count the number of points that we encountered at least twice
    let count = 0;
    Object.keys(points).forEach(key => {
        if (points[key] >= 2) {
            count ++;
        }
    });
    console.log("Part %d: %d", first ? 1 : 2, count);
}

function solution() {
    let mx = 0;
    function parse_pair(s) {
        // Parse an "x,y" pair and return the result as an array of numbers ([x, y])
        // Also update the maximum x (needed later to compute coordinates)
        const parts = s.split(",");
        const x = parseInt(parts[0]);
        if (x > mx) {
            mx = x;
        }
        return [x, parseInt(parts[1])];
    }
    // Read the input first
    // Use the readline module to read each line of the file
    const rl = readline.createInterface({
        input: fs.createReadStream('input.txt'),
        terminal: false,
        crlfDelay: Infinity
    });
    let data = [];
    rl.on('line', (line) => {
        // Parse each side of the -> separator and save the result in "data"
        const parts = line.split(" -> ");
        data.push({start: parse_pair(parts[0]), end: parse_pair(parts[1])});
    });
    rl.on('close', () => {
        // Done reading everything
        solve(data, mx + 1, true);
        solve(data, mx + 1, false);
    });
}

solution();
