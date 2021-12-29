# Overview

Solution to https://adventofcode.com/2021/day/19 in [PHP](https://www.php.net/) (using the command line).

To build and run:

- `sudo apt install php-cli`
- `php solution.php`

`php` version: `PHP 7.4.3 (cli) (built: Nov 25 2021 23:16:22) ( NTS )`.

# Algorithm

The algorithm is probably not optimal, since it computes distances between all possible becaons in all possible orientations of scanners until it finds a distance that repeats 12 times. First scanner (0) is considered to be located at absolute position (0, 0, 0), all the other scanners are relative to it. Once a scanner is located, its position/orientation doesn't change anymore. I might revisit the algorithm in the future, but for now it is good enough.
