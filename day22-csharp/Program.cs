// See https://aka.ms/new-console-template for more information

// Read input and return it as an array of (coordinated, kind) tuples
List<(int[], bool)> data = new List<(int[], bool)>();
foreach (var line in File.ReadLines("input.txt")) {
    var t = line.Trim();
    string[] parts;
    bool is_on;
    // Find the kind of this line (on/off) and keep the coordinates substring
    if (t.StartsWith("on ")) {
        parts = t.Substring(3).Split(",");
        is_on = true;
    } else {
        parts = t.Substring(4).Split(",");
        is_on = false;
    }
    // Split each "x/y/z=min..max" pair into an array of coordinates
    int[] coordinates = new int[6];
    int idx = 0;
    foreach(var p in parts) {
        var temp = p.Substring(2).Split("..");
        coordinates[idx ++] = int.Parse(temp[0]);
        coordinates[idx ++] = int.Parse(temp[1]);
    }
    data.Add((coordinates, is_on));
}

Console.WriteLine($"Part 1: {solve(data, false)}");
Console.WriteLine($"Part 1: {solve(data, true)}");

// Finally, the solver!
ulong solve(in List<(int[], bool)> data, bool part2) {
    var cubes = new List<Cube>(); // this keeps the current list of cubes
    foreach(var (ranges, is_on) in data) {
        // We need to consider different ranges in part 1 and part 2
        var ok = true;
        if (!part2) {
            foreach(var e in ranges) {
                if (e < -50 || e > 50) {
                    ok = false;
                    break;
                }
            }
        }
        if (!ok) {
            continue;
        }
        // Create a cube at the given coordinate limits. A subtle point here is that we're using floating point coordinates
        // to create a "bounding box" around the puzzle cubes, since we're working in a continous space and the puzzle contains
        // discrete elements (the puzzle cubes). This way, all intersections between the discrete elements are handled correctly.
        var c = new Cube((double)ranges[0] - 0.25, (double)ranges[1] + 0.25, (double)ranges[2] - 0.25, (double)ranges[3] + 0.25,
                         (double)ranges[4] - 0.25, (double)ranges[5] + 0.25);
        // Get a list of all existing cubes that intersect with this new cube (and a list of cubes that don't intersect)
        var intersections = new List<Cube>();
        var not_intersected = new List<Cube>();
        foreach(var e in cubes) {
            if (e.intersects(c)) {
                intersections.Add(e);
            } else {
                not_intersected.Add(e);
            }
        }
        // If nothing intersects this cube, add it to the list of active cubes if it "on" anc continue
        if (intersections.Count == 0) {
            if (is_on) {
                cubes.Add(c);
            }
        } else { // compute intersections between c and all the cubes that it intersects
            cubes = not_intersected; // Keep the list of not intersected cubes since we'll not touch them
            var new_cubes = new List<Cube>();
            foreach(var other in intersections) {
                var (base_i, z_i) = other.intersection(c); // intersection between the new cube and the current element
                // Add parts to the top and bottom of "c"
                foreach (var new_z in other.z.difference(z_i!)) {
                    new_cubes.Add(Cube.from_base_and_interval(other.b, new_z));
                }
                // Add parts left in the middle (where "c" actually intersects "other")
                foreach (var new_b in other.b.difference(base_i!)) {
                    new_cubes.Add(Cube.from_base_and_interval(new_b, z_i!));
                }
            }
            if (is_on) {
                cubes.Add(c);
            }
            cubes.AddRange(new_cubes); // add the new cubes that appeared after all the intersections
        }
    }
    // Return the sum of all volumes (computed as puzzle elements) of the cubes
    ulong res = 0;
    foreach(var e in cubes) {
        res += e.puzzle_cubes;
    }
    return res;
}

// This class defines a [high, low] interval and methods to work with intervals
class Interval {
    public double high, low;

    public Interval(double l, double h) {
        high = h;
        low = l;
    }

    // Return true if the given interval is contained in (or equal to) this interval
    public bool contains(Interval other) {
        return other.low >= low && other.high <= high;
    }

    // Return the length of this interval
    public double length {
        get { return high - low; }
    }

    // Return the intersection of this interval with the given interval or null if none exists
    public Interval? intersection(in Interval other) {
        if (other.high <= low || other.low >= high) {
            return null;
        } else {
            return new Interval(Math.Max(low, other.low), Math.Min(high, other.high));
        }
    }

    // Return the difference between this interval and the given interval as a list of intervals
    public List<Interval> difference(in Interval other) {
        var res = new List<Interval>();
        // Compute intersections and add only non-empty ones (length > 0)
        var s = new Interval(low, other.low);
        if (s.length > 0) {
            res.Add(s);
        }
        s = new Interval(other.high, high);
        if (s.length > 0) {
            res.Add(s);
        }
        return res;
    }
}

// This class defines a rectangle and methods to work with rectangles
class Rectangle {
    public double left, bottom, right, top;

    public Rectangle(double xs, double ys, double xe, double ye) {
        left = xs;
        right = xe;
        bottom = ys;
        top = ye;
    }

    // Return the area of this rectangle
    public double area {
        get { return (right - left) * (top - bottom); }
    }

    // Return the intersection of this rectangle with the given rectangle or null if no intersection exists
    public Rectangle? intersection(in Rectangle other) {
        if (other.left >= right || other.right <= left || other.bottom >= top || other.top <= bottom) {
            return null; // no intersection
        } else {
            var n_left = Math.Max(other.left, left);
            var n_right = Math.Min(other.right, right);
            var n_bottom = Math.Max(other.bottom, bottom);
            var n_top = Math.Min(other.top, top);
            return new Rectangle(n_left, n_bottom, n_right, n_top);
        }
    }

    // Return true if the given rectangle is contained in (or equal to) this rectangle
    public bool contains(in Rectangle other) {
        return other.left >= left && other.right <= right && other.top <= top && other.bottom >= bottom;
    }

    // Return the difference between this rectangle and the given rectangle as a list of rectangles
    public List<Rectangle> difference(in Rectangle other) {
        var res = new List<Rectangle>();
        // Compute intersections and add only non-empty ones (area > 0)
        var r = new Rectangle(left, other.top, right, top);
        if (r.area > 0) {
            res.Add(r);
        }
        r = new Rectangle(left, bottom, right, other.bottom);
        if (r.area > 0) {
            res.Add(r);
        }
        r = new Rectangle(left, other.bottom, other.left, other.top);
        if (r.area > 0) {
            res.Add(r);
        }
        r = new Rectangle(other.right, other.bottom, right, other.top);
        if (r.area > 0) {
            res.Add(r);
        }
        return res;
    }
}

// A cube is a 3D cube which has a base on the Ox/Oy plane and a height as a (z_min, z_max) interval
class Cube {
    public Rectangle b;
    public Interval z;

    public Cube(double xs, double xe, double ys, double ye, double zs, double ze) {
        b = new Rectangle(xs, ys, xe, ye);
        z = new Interval(zs, ze);
    }

    // Create a Cube from a base and a z interval
    public static Cube from_base_and_interval(in Rectangle b, in Interval zi) {
        return new Cube(b.left, b.right, b.bottom, b.top, zi.low, zi.high);
    }

    // Return the intersection of this cube with the given cube as a (base intersection, z intersection) tuple
    public (Rectangle?, Interval?) intersection(in Cube other) {
        var base_i = b.intersection(other.b);
        var z_i = z.intersection(other.z);
        return (base_i, z_i);
    }

    // Shortcut for intersection above: return true if this cube intersects the given cube, false otherwise
    public bool intersects(in Cube other) {
        var (res_b, res_z) = intersection(other);
        return res_b != null && res_z != null;
    }

    // Return true if the given cube is contained in (or equal to) this cube
    public bool contains(in Cube other) {
        return b.contains(other.b) && z.contains(other.z);
    }

    // Return the number of cubes (in the sense of puzzle units) in this cube
    public ulong puzzle_cubes {
        get {
            var res = (ulong)(Math.Floor(z.high) - Math.Ceiling(z.low) + 1);
            res = res * (ulong)(Math.Floor(b.right) - Math.Ceiling(b.left) + 1);
            res = res * (ulong)(Math.Floor(b.top) - Math.Ceiling(b.bottom) + 1);
            return res;
        }
    }
}
