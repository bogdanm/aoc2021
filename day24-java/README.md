# Overview

Solution to https://adventofcode.com/2021/day/24 in [Java](https://www.oracle.com/java/).

To build and run:

- `sudo apt install openjdk-11-jre-headless` (newer versions should work too).
- `java Solution.java`.

`java` version:

```
openjdk 11.0.13 2021-10-19
OpenJDK Runtime Environment (build 11.0.13+8-Ubuntu-0ubuntu1.20.04)
OpenJDK 64-Bit Server VM (build 11.0.13+8-Ubuntu-0ubuntu1.20.04, mixed mode, sharing)
```

# Algorithm

Since the ALU works on 14 digit numbers, checking all of them would take way too much time, so another approach is needed (I kinda expected this by now). My algorithm (which is probably more complex than it needs to be) evaluates all the operations in the ALU, with one exception: an `EQL` instruction is not actually evalauted, but instead the evaluator branches in two different paths: one in which the expression is considerd to be true (1) and another one in which the expression is considered to be false (0). The result of this are 2 ** 14 evaluated expressions, each with its own set of branching conditions (in this context "evaluated" means "keep the symbols that are not known when evaluating an expression", which I suppose is a very basic form of symbolic algebra). Each of those evaluated expressions, together with their conditions, look like this:

```
[12!=d0]
[((d0 + 6) % 26) + 11!=d1]
[((((d0 + 6) * 26) + (d1 + 12)) % 26) + 10!=d2]
[((((((d0 + 6) * 26) + (d1 + 12)) * 26) + (d2 + 5)) % 26) + 10==d3]
[((((((d0 + 6) * 26) + (d1 + 12)) * 26) + (d2 + 5)) % 26) - 16==d4]
[(((((((d0 + 6) * 26) + (d1 + 12)) * 26) + (d2 + 5)) / 26) % 26) + 14!=d5]
[(((((((((d0 + 6) * 26) + (d1 + 12)) * 26) + (d2 + 5)) / 26) * 26) + d5) % 26) + 12==d6]
[(((((((((d0 + 6) * 26) + (d1 + 12)) * 26) + (d2 + 5)) / 26) * 26) + d5) % 26) - 4!=d7]
[((((((((((((d0 + 6) * 26) + (d1 + 12)) * 26) + (d2 + 5)) / 26) * 26) + d5) / 26) * 26) + (d7 + 12)) % 26) + 15!=d8]
[((((((((((((((d0 + 6) * 26) + (d1 + 12)) * 26) + (d2 + 5)) / 26) * 26) + d5) / 26) * 26) + (d7 + 12)) * 26) + (d8 + 14)) % 26) - 7==d9]
[(((((((((((((((d0 + 6) * 26) + (d1 + 12)) * 26) + (d2 + 5)) / 26) * 26) + d5) / 26) * 26) + (d7 + 12)) * 26) + (d8 + 14)) / 26) % 26) - 8==d10]
[((((((((((((((((d0 + 6) * 26) + (d1 + 12)) * 26) + (d2 + 5)) / 26) * 26) + d5) / 26) * 26) + (d7 + 12)) * 26) + (d8 + 14)) / 26) / 26) % 26) - 4!=d11]
[(((((((((((((((((((d0 + 6) * 26) + (d1 + 12)) * 26) + (d2 + 5)) / 26) * 26) + d5) / 26) * 26) + (d7 + 12)) * 26) + (d8 + 14)) / 26) / 26) / 26) * 26) + (d11 + 11)) % 26) - 15!=d12]
[((((((((((((((((((((((d0 + 6) * 26) + (d1 + 12)) * 26) + (d2 + 5)) / 26) * 26) + d5) / 26) * 26) + (d7 + 12)) * 26) + (d8 + 14)) / 26) / 26) / 26) * 26) + (d11 + 11)) / 26) * 26) + (d12 + 9)) % 26) - 8==d13]
  (((((((((((((((((((((d0 + 6) * 26) + (d1 + 12)) * 26) + (d2 + 5)) / 26) * 26) + d5) / 26) * 26) + (d7 + 12)) * 26) + (d8 + 14)) / 26) / 26) / 26) * 26) + (d11 + 11)) / 26) * 26) + (d12 + 9)) / 26
```

The first lines are the conditions, the last line (indented) is the value of `z` after running the program when the conditions are met (`d<x>` is the `x`-th digit in the input number (0 based)). All the conditions need to be satisfied in order for us to be able to compute `z` using the formula for its last expression.

Then the algorithm filters the above list as follows:

- All the expressions that have at least one condition that is always false (such as `d0==-8`) are eliminated.
- All the expressions that can't be 0 are eliminated. Since the value of `z` depends only on input digits and their minimum and maximum values are known (1 and 9 respectively), the algorithm computes the minimum and maximum value of `z` by traversing its expression tree and updating the minimum/maximum according to the operation type (add/mul/div/mod). If 0 is not in this `[min_value, max_value]` interval, the expression is eliminated.
- Finally, all the conditions that are always true (such as `12!=d0` above) are eliminated from the list of conditions to simplify processing.

After running all the filters above, I was left with a single expression that has only `expr == digit_val` conditions (which I suspect is a necessary condition to resolve this puzzle):

```
[((((((((d0 + 6) * 26) + (d1 + 12)) * 26) + (d2 + 5)) * 26) + (d3 + 10)) % 26) - 16==d4]
[(((((((((((((d0 + 6) * 26) + (d1 + 12)) * 26) + (d2 + 5)) * 26) + (d3 + 10)) / 26) * 26) + d5) * 26) + (d6 + 4)) % 26) - 4==d7]
[((((((((((((((((d0 + 6) * 26) + (d1 + 12)) * 26) + (d2 + 5)) * 26) + (d3 + 10)) / 26) * 26) + d5) * 26) + (d6 + 4)) / 26) * 26) + (d8 + 14)) % 26) - 7==d9]
[(((((((((((((((((d0 + 6) * 26) + (d1 + 12)) * 26) + (d2 + 5)) * 26) + (d3 + 10)) / 26) * 26) + d5) * 26) + (d6 + 4)) / 26) * 26) + (d8 + 14)) / 26) % 26) - 8==d10]
[((((((((((((((((((d0 + 6) * 26) + (d1 + 12)) * 26) + (d2 + 5)) * 26) + (d3 + 10)) / 26) * 26) + d5) * 26) + (d6 + 4)) / 26) * 26) + (d8 + 14)) / 26) / 26) % 26) - 4==d11]
[(((((((((((((((((((d0 + 6) * 26) + (d1 + 12)) * 26) + (d2 + 5)) * 26) + (d3 + 10)) / 26) * 26) + d5) * 26) + (d6 + 4)) / 26) * 26) + (d8 + 14)) / 26) / 26) / 26) % 26) - 15==d12]
[((((((((((((((((((((d0 + 6) * 26) + (d1 + 12)) * 26) + (d2 + 5)) * 26) + (d3 + 10)) / 26) * 26) + d5) * 26) + (d6 + 4)) / 26) * 26) + (d8 + 14)) / 26) / 26) / 26) / 26) % 26) - 8==d13]
  (((((((((((((((((((d0 + 6) * 26) + (d1 + 12)) * 26) + (d2 + 5)) * 26) + (d3 + 10)) / 26) * 26) + d5) * 26) + (d6 + 4)) / 26) * 26) + (d8 + 14)) / 26) / 26) / 26) / 26) / 26
```

The value of the expression turns out to be 0 for any combination of input digits (which is determined by computing the expression's minimum and maximum values as explained above), but we still need to satisfy all the conditions. However, if we look at the conditions and the expression, we can see that they depend only on 7 digits: `d0, d1, d2, d3, d5, d6, d8` (the implementation does this automatically of course). This means that we need to generate only the possible values for these digits and compute the remaining digits from the conditions. We have thus reduced our solution space from a 14 digit number to a 7 digit number (1 111 111 to 9 999 999), which is something that we can actually run. Generating all the allowed 7 digit numbers and computing the others (eliminating the invalid digits in the process) gives the minimum and maximum values of the numbers accepted by the ALU algorithm.

# Notes

Writing code in Java was (once again) not a pleasant experience. Very important language, huge number of libraries, used in a lot of places, but IMO it looks and feels like an outdated language in 2021. The verbosity alone is driving me insane. I haven't used it in a while and now it's clear that I won't be using it again unless I have to.
