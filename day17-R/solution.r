require(stringr)

# Read limits from input file
f <- file("input.txt", "rt")
l <- readLines(f)
# The two parts are separated by ", "
parts <- str_split(l, ", ")
# Split the x part once after ".." to get the maximum x
parts_x <- str_split(parts[[1]][[1]], "\\.\\.")
x_max <- as.numeric(parts_x[[1]][[2]])
parts_x <- str_split(parts_x[[1]][[1]], "=")
x_min <- as.numeric(parts_x[[1]][[2]])
# Repeat for y limits
parts_y <- str_split(parts[[1]][[2]], "\\.\\.")
y_max <- as.numeric(parts_y[[1]][[2]])
parts_y <- str_split(parts_y[[1]][[1]], "=")
y_min <- as.numeric(parts_y[[1]][[2]])

# Start interval for vx
vx_min <- ceiling((sqrt(8 * x_min) - 1) / 2)
# End interval for vx (conservative)
vx_max <- x_max
# Start interval for vy
vy_min <- y_min
# End interval for vy
vy_max <- -(1 + y_min)

# Return the y coordinate at step k given the initial velocity
y_at <- function(k, v0) {
    k * v0 - (k * (k - 1)) / 2
}

# Return the x coordinate at step k given the initial velocity
x_at <- function(k, v0) {
    t <- min(k, v0)
    t * v0 - (t * (t - 1)) / 2
}

# Check if the given initial velocities can hit the target
can_hit <- function(vx0, vy0) {
    # y test: compute k for which y == 0 the second time (2*vy0 + 1)
    # We only need to test from the next index
    k <- max(0, 2 * vy0 + 2)
    while (TRUE) {
        y <- y_at(k, vy0)
        if (y < y_min) { # we're outside the target and y goes down from here on, so we're done
            return (FALSE)
        } else if (y <= y_max) { # this is a hit on y, check x now
            x <- x_at(k, vx0)
            if (x > x_max) { # we're outside the target and x goes right or remaine the same, so we're done
                return (FALSE)
            } else if (x >= x_min) { # hit on x too!
                return (TRUE)
            }
        }
        k <- k + 1
    }
}

# Part 1: get maximum height for each possible y
# After a bit of math, it turns out that the maximum height for any vy is (vy ^ 2) / 2 + vy / 2 + 1 / 8
# Since the above expression increases with vy, it follows that the maximum height is obtained for vy_max
# (we keep only the integer part of that value since we're dealing with integer coordinates)
print(paste("Part 1:", floor((vy_max * vy_max) / 2 + vy_max / 2 + 1 / 8)))

# Part 2: generate all possible (x, y) pairs that can hit the target and count them
hits <- 0
for (vx in seq.int(vx_min, vx_max)) {
    for (vy in seq.int(vy_min, vy_max)) {
        if (can_hit(vx, vy)) {
            hits <- hits + 1
        }
    }
}
print(paste("Part 2:", hits))