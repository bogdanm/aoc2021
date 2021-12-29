# Overview

Solution to https://adventofcode.com/2021/day/14 in [F#](https://fsharp.org/).

To build and run:

- Install `F#` by follwing the instructions at https://fsharp.org/use/linux/.
- `dotnet fsi solution.fsx`

`dotnet` framework version: `6.0.100`

# Algorithm

Since the sequence of elements grows exponentially, the naive approach of generating a new sequence at each step works only for very few steps (for example the first part of the puzzle). However, it turns out that we just need to count the element pairs in the sequence, not the actual sequence, which leads to a much better algorithm:

- Keep a counter for each element pair at the current step (initialized using the first line of the input).
- At each step, iterate through all avaiable pairs (count > 0), generate new pairs using the mutation rules and make the count for the mutated pair 0 (since mutation destroys the pair).
- In parallel, keep a count of the actual elements in a separate array (initialized using the first line of the input) and update it as needed when generating new pairs.

To simplify things a bit, the pairs are transformed to numbers (using their ASCII values) and kept in integer arrays instead of hash maps. The same thing happens with element counts.

# Notes

I am going to guess that a "true" functional programmer will cringe in despair when looking at my code. So, to all those programmers, a sincere "I'm sorry!" :) Unfortunately my experience with functional languages is extremely limited, but I'd like to change that in the future.
