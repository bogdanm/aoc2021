# Overview

Solution to https://adventofcode.com/2021/day/23 in [Python](https://www.python.org/).

To build and run:

- `sudo apt install python3` if not already installed (which is quite unlikely).
- `python(3) solution.py`

`python(3)` version: `3.8.10`

# Algorithm

I spent WAY too much time on this puzzle, trying to find various branch-and-bound type solutions with all kinds of weird heuristics, because I forgot one simple principle: don't try to optimize too soon. Turns out that a simple implementation that keeps the puzzle state in a priority queue based on costs and considers the solution with the least cost at each step works quite well. Further optimizations are definitely possible, but I'll skip them for now.

# Notes

Python is one of my favorite programming languages, mainly due to its simplicity and its huge ecosystem (I can't remember the last time when I needed a Python library for some task and I was unable to find one). It's almost always my language of choice whenever I need to write a simple tool, a quick-and-dirty prototype or something, or to solve an AoC puzzle. For a lot of the puzzles from this year's AoC I wrote a quick Python implementation, then figured out the final language that I was going to use based on that implementation. Definitely a very good language to have in your toolbox.