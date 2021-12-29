# Overview

Solution to https://adventofcode.com/2021/day/15 in C++.

To build and run:

- `sudo apt install build-essential` if they're not already installed.
- `g++ -std=c++11 -o solution solution.cpp && ./solution`.

# Algorithm

The input data is transformed into a graph (implemented by the `Graph` class) and [Dijkstra's algorithm](https://en.wikipedia.org/wiki/Dijkstra's_algorithm) is used to find the path of minimal cost from the start node to the end node. It turned out that a "naive" Dijkstra implementation (which runs in `O(N²)`) was too slow to resolve the second part of the puzzle, so I swithed to a better implementation that uses a priority queue and runs in `O(NlogN)`. This is an excellent demonstration of how the implementation of an algorithm can dramatically influence its behavior.

