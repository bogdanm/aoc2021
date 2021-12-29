<?php

// Rotations
const X = 0, Y = 1, Z = 2;
const PLUS = 1, MINUS = -1;

// An orientation contains the definition of an axis and a sign
class Orientation {
    public $axis;
    public $sign;

    public function __construct($axis, $sign) {
        $this->axis = $axis;
        $this->sign = $sign;
    }
};
$X_PLUS = new Orientation(X, PLUS);
$X_MINUS = new Orientation(X, MINUS);
$Y_PLUS = new Orientation(Y, PLUS);
$Y_MINUS = new Orientation(Y, MINUS);
$Z_PLUS = new Orientation(Z, PLUS);
$Z_MINUS = new Orientation(Z, MINUS);

// Yes, I calculated the orientations manually. And yes, I'm aware that they're symmetric.
// It just felt easier to visualize them.
$orientations = array(
    // X
    array($X_PLUS, $Y_PLUS, $Z_PLUS),
    array($X_PLUS, $Z_MINUS, $Y_PLUS),
    array($X_PLUS, $Y_MINUS, $Z_MINUS),
    array($X_PLUS, $Z_PLUS, $Y_MINUS),
    array($X_MINUS, $Y_MINUS, $Z_PLUS),
    array($X_MINUS, $Z_PLUS, $Y_PLUS),
    array($X_MINUS, $Y_PLUS, $Z_MINUS),
    array($X_MINUS, $Z_MINUS, $Y_MINUS),
    // Y
    array($Y_PLUS, $X_MINUS, $Z_PLUS),
    array($Y_PLUS, $Z_MINUS, $X_MINUS),
    array($Y_PLUS, $X_PLUS, $Z_MINUS),
    array($Y_PLUS, $Z_PLUS, $X_PLUS),
    array($Y_MINUS, $X_PLUS, $Z_PLUS),
    array($Y_MINUS, $Z_PLUS, $X_MINUS),
    array($Y_MINUS, $X_MINUS, $Z_MINUS),
    array($Y_MINUS, $Z_MINUS, $X_PLUS),
    // Z
    array($Z_PLUS, $Y_PLUS, $X_MINUS),
    array($Z_PLUS, $X_MINUS, $Y_MINUS),
    array($Z_PLUS, $Y_MINUS, $X_PLUS),
    array($Z_PLUS, $X_PLUS, $Y_PLUS),
    array($Z_MINUS, $Y_MINUS, $X_MINUS),
    array($Z_MINUS, $X_PLUS, $Y_MINUS),
    array($Z_MINUS, $Y_PLUS, $X_PLUS),
    array($Z_MINUS, $X_MINUS, $Y_PLUS),
);

// A single point in the 3D space
class Point3D {
    public $x;
    public $y;
    public $z;

    public function __construct($x, $y, $z) {
        $this->x = $x;
        $this->y = $y;
        $this->z = $z;
        // Also keep the string representation (for toString) and the array representation (for orient)
        $this->as_string = "$x,$y,$z";
        $this->as_array = array($x, $y, $z);
    }

    // Orient this point relative to the given orientation (an entry in $orientations) and return the new oriented point
    public function orient($o) {
        $ox = $o[0];
        $oy = $o[1];
        $oz = $o[2];
        return new Point3D($this->as_array[$ox->axis] * $ox->sign,
                           $this->as_array[$oy->axis] * $oy->sign,
                           $this->as_array[$oz->axis] * $oz->sign);
    }

    // Return a new point that is offset relative to this point
    public function offset($o) {
        return new Point3D($this->x + $o->x, $this->y + $o->y, $this->z + $o->z);
    }

    // Return the distance between this point and the given point
    // The distance isn't a point technically, but we can simplify things a bit.
    public function distance($o) {
        return new Point3D($this->x - $o->x, $this->y - $o->y, $this->z - $o->z);
    }

    // Return the string representation of this point. Need for printing, but also for using the point
    // as a key in an associative array.
    public function __toString() {
        return $this->as_string;
    }
}

// A single scanner
class Scanner {
    private $all_beacons;               // all beacons in all possible orientations
    public $beacons;                    // current beacons (corresponding to the current orientation)
    private $orientation;               // the current orientation (an index in $orientations)
    public $id;                         // the ID of the scanner, as read from the puzzle input
    public $located;                    // true if the absolute location of this scanner is known, false otherwise
    public $origin;                     // origin of this beacon (only known after the beacon was located)

    public function __construct() {
        $this->all_beacons = array();
        $this->orientation = 0;
        $this->located = false;
    }

    // Parse the definition of this scanner from the input array "l" starting at index "idx"
    // Return the index of the next scanner definition.
    public function parse($l, $idx) {
        $first = true;
        $beacons = array();
        while ($idx < count($l)) {
            $e = $l[$idx]; // current line
            if ($first) { // first time parsing: parse the ID
                $parts = explode(" ", $e);
                $this->id = $parts[2];
                $first = false;
            } else if (strlen($e) == 0) { // empty line, we're done parsing.
                $idx ++; // the next definition starts at the next line
                break;
            } else { // parse a beacon spec
                $parts = explode(",", $e);
                array_push($beacons, new Point3D((int)$parts[0], (int)$parts[1], (int)$parts[2]));
            }
            $idx ++;
        }
        // Done with the definition of this scanner, so compute all possible orientations now and store them in all_beacons
        global $orientations;
        foreach ($orientations as $o) {
            $crt = array();
            foreach ($beacons as $b) {
                array_push($crt, $b->orient($o));
            }
            array_push($this->all_beacons, $crt);
        }
        // Return the index of the next scanner definition in the input array
        return $idx;
    }

    // Set the current orientation
    public function set_orientation($o) {
        $this->orientation = $o;
        $this->beacons = $this->all_beacons[$o];
    }

    // Set the absolute location of this scanner
    public function set_location($x, $y, $z) {
        $this->origin = new Point3D($x, $y, $z);
        // Recompute the beacons according to the current orientation (which is also the final orientation)
        for ($i = 0; $i < count($this->beacons); $i ++) {
            $this->beacons[$i] = $this->origin->offset($this->beacons[$i]);
        }
        $this->located = true;
    }
}

// Find the common beacons between the given scanners. If an intersection for more than 12 points can be
// found, return the corresponding (dx, dy, dz) distance tuple, otherwise return False
function find_common($s1, $s2) {
    $pa1 = $s1->beacons; // list of beacons from first scanner
    // Try all orientations until we get enough common points (or we run out of orientations)
    global $orientations;
    for ($o = 0; $o < count($orientations); $o ++) {
        $s2->set_orientation($o);
        $pa2 = $s2->beacons; // list of beacons at current orientation
        # Compute all distances using an associative array
        $dist_map = array();
        foreach ($pa1 as $p1) {
            foreach ($pa2 as $p2) {
                $dist = $p1->distance($p2);
                $dist_key = (string)$dist;
                if (empty($dist_map[$dist_key])) {
                    $dist_map[$dist_key] = 1;
                } else {
                    $dist_map[$dist_key] ++;
                }
                if ($dist_map[$dist_key] == 12) { // found enough common beacons, return the "winning" distance
                    return $dist;
                }
            }
        }
    }
    return false;
}

// Read input file
$f = fopen('input.txt', 'r');
$input = explode("\n", fread($f, filesize('input.txt')));
fclose($f);

// Create all the scanners
$scanners = array();
$idx = 0;
while ($idx < count($input)) {
    $s = new Scanner();
    $idx = $s->parse($input, $idx);
    array_push($scanners, $s);
}
// Consider the first scanner to be located at absolute position (0, 0, 0)
$scanners[0]->set_orientation(0);
$scanners[0]->set_location(0, 0, 0);
echo "Scanner 0 fixed at position (0, 0, 0)\n";

// Keep on running until all the scanners are located
$num_f = 1; // first scanner is always located (see above)
while ($num_f < count($scanners)) {
    foreach ($scanners as $s1) {
        if (!$s1->located) { // first scanner must be located
            continue;
        }
        foreach ($scanners as $s2) {
            if ($s2->located || $s1->id == $s2->id) { // skip located scanners or same scanner
                continue;
            }
            // Find the common beacons
            $res = find_common($s1, $s2);
            if ($res != false) { // found 12 common points, which means that we located s2
                echo "Found scanner $s2->id at ($res->x, $res->y, $res->z)\n";
                $s2->set_location($res->x, $res->y, $res->z);
                $num_f ++;
            }
        }
    }
}

// Part 1: count the beacons using a coordinate map
$found = array();
foreach ($scanners as $s) {
    foreach ($s->beacons as $b) {
        $found[(string)$b] = true;
    }
}
$num_beacons = count($found);
echo "Part 1: $num_beacons\n";

// Part 2
$max_d = 0;
foreach($scanners as $s1) {
    $o1 = $s1->origin;
    foreach($scanners as $s2) {
        $o2 = $s2->origin;
        $d = abs($o1->x - $o2->x) + abs($o1->y - $o2->y) + abs($o1->z - $o2->z);
        if ($d > $max_d) {
            $max_d = $d;
        }
    }
}
echo "Part 2: $max_d\n";
?>