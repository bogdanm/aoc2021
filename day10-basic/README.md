# Overview

Solution to https://adventofcode.com/2021/day/10 in [FreeBASIC](https://freebasic.net/), AKA "the language of maximum nostalgia".

To build and run:

- Follow the instructions at https://www.freebasic.net/wiki/CompilerInstalling to install `FreeBASIC`.
- `fbc solution.bas && ./solution`

`FreeBASIC` version: `Version 1.08.1 (2021-07-05), built for linux-x86_64 (64bit)`

# Algorithm

The algorithm is very simple and uses a stack of chars (implemented using an array). For each char in a single line of input:

- Every start char (`[({>`) is added to the stack.
- When an end char (`])}<`) is found:
    * If its corresponding start char is at the top of the stack, it is popped.
    * Othewise this is an invalid entry and its score is returned.

If the stack is not empty after all the chars in the line are processed, this is an incomplete entry and it is "completed" by popping the chars that are still in the stack (not actually completed though, only the completion score is computed).

# Notes

`BASIC` is the first programming language that I ever learned and used (on an 8 bit Romanian clone of the Sinclair ZX Spectrum). Because of this, I'll always have a soft spot for this language, even though it is completely outdated by today's standards (which is true even for the more modern implementations like `FreeBASIC`). And yes, I am aware of [Dijkstra's quote](https://www.goodreads.com/quotes/79997-it-is-practically-impossible-to-teach-good-programming-to-students). I just happen to disagree with it, even when placed [in the proper context](https://programmingisterrible.com/post/40132515169/dijkstra-basic).
