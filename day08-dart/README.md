# Overview

Solution to https://adventofcode.com/2021/day/8 in [dart](https://dart.dev/).

To build and run:

- Follow the instructions at https://dart.dev/get-dart to install `dart` (I used the `apt-get` method for Debian).
- `dart run solution.dart`

`dart` version: `Dart SDK version: 2.14.4 (stable) (Unknown timestamp) on "linux_x64"`.

# Algorithm

The algorithm for solving the puzzle is described in `solution.dart`. Interestingly, it turns out that some of the input data is redundant, since all you need to find the solution are digits 0, 1, 4, 6, 7 and 9 (which might not even be the minimum set of digits needed for the solution, it's just something that I found while playing with the input data).
