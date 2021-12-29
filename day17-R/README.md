# Overview

Solution to https://adventofcode.com/2021/day/17 in [R](https://www.r-project.org/).

To build and run:

- `sudo apt install r-base`
- We need to install an additional package, so:
  * `sudo R`
  * `install.packages("stringr")`
  * `q()`
- `Rscript solution.r`

R version: `R scripting front-end version 4.0.4 (2021-02-15)`

# Algorithm

**NOTE**: the algorithm assumes that the starting point (0, 0) is always up and to the left of the trench, as is the case in the example and in my input.

## Part 1

After playing a bit with the rules for x/y movement, we can find the equation for the `y` position at any step `k` for an initial velocity `vy`:

```
y(k) = k * vy - (k * (k - 1)) / 2
```

If we plot the above equation in `R` for `vy >= 0`, we can see that `y` starts from 0, goes up to some maximum value, then decreases to 0 and below again. Our trench is in a negative range of `y`, so if we make `y(k) = 0` and solve for `k` we get the step at which `y` becomes 0 (`k0`):

```
k0 = 2 * vy + 1
```

We need to make sure that `y` doesn't go below `y_min` in the next step (`ko + 1`), which leads to the maximum value for `vy` that doesn't overshoot the trench towards bottom (where `y_min` is the minum `y` from the puzzle input):

```
vy_max = -(1 + y_min)
```

If we derive the equation of `y(k)` for `k` we find the inflection point at `ki = vy + 1/2`. Plotting the above equation in `R` shows that the graph is concave, which means that the inflection point represents a maximum of the function. So, by substituting `ki` in the equation for `y(k)`, we find the maximum value of `y` (the maximum height) for any `vy`:

```
ymax(vy) = (vy * vy) / 2 + vy / 2 + 1 / 8
```

The function above is convex (it grows with `vy`) and we already know the maximum value of `vy`, so the first part of the problem is just the result of `ymax(vy_max)` (rounded to an integer).

## Part 2

To solve part 2 we need to find the other limits for `vy` and `vx`, so far we know only `vy_max` from part 1.

Let's consider the equation for `y(k)` again, but this time when `vy < 0`. Plotting this function again shows that after the initial value of `0` for `k = 0` the function decreases below 0. We want it to not go below the bottom of the trench at the first step (`k = 1`), so we set `vy_min = y_min`.

It's time to look at `x`. Due to the drag, `x` doesn't change after a while, and either increases if its initial value is negative or decreases if its initial value is positive. The equation for `x` at any step `k` can thus be formulated as follows:

```
x(k) = t * v0 - (t * (t - 1)) / 2, where t = min(k, v0)
```

(the `min` above ensures that `x` becomes a constant after `abs(v0)` steps).

The maximum value for `vx` is easy: we need to be able to reach the trench in step 1, so `vx_min = x_max` (any other value overshoots the trench to the right in step 1 and thus in the other steps too, since `x_max` is positive, which means that `x` will increase).

To figure out the minimum value, we need to make sure that the maximum value of `x` (after it becomes a constant) is at least `x_min`, otherwise the left part of the trench will never be reached. The maximum value of `x` is `(vx * (vx + 1)) / 2` (the sum of the first `abs(vx)` natural numbers) and `vx` must be positive. If we make this maximum value equal to `x_min` and solve for `x` we get:

```
vx_min = ceil((sqrt(8 * x_min) - 1) / 2)
```

The rest is easy, we just iterate from min to max on both axes, check if we hit the trench and increment a counter if we do. The hit function starts with a step equal to `k0` from part 1 and stops as soon as either x or y overshoot the trench.

# Notes

Since this puzzle is mostly mathematical in nature, it seemed like a good opportunity to give `R` a try. I'm not at all versed in `R`, but the implementation was simple and thus easy to write (although probably not very `R`-ish in nature). The built-in graphing features were quite handy while checking the various equations for x and y movement.
