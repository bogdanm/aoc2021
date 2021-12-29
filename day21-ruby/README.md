# Overview

Solution to https://adventofcode.com/2021/day/21 in [Ruby](https://www.ruby-lang.org/).

To build and run:

- `sudo apt install ruby` (if not already installed).
- `ruby solution.rb`

# Algorithm

The first part is trivial.

The second part was a real head scratcher. Initially I didn't even understand the description correctly, I misunderstood how the game evolves in the newly created states. After searching for a few hints and finding quite a few references to memoization, I started to get an idea about what needs to be done: generate all possible solutions for all game states (positions, scores, turn, dice roll) until all the winning paths are discovered. This is the job of `solve2` that starts from the initial state (player positions/scores) and then generates recursively all the other states from this initial state, after each position/score update, for each dice roll. This might look as infinite recursion at first, but it is not, because the state space as defined above (positions/scores/turn/dice roll) is finite (which is also why memoization works so well). The function returns after all possible win counts were computed.

Also, there are probably better ways to memoize functions in Ruby, but my manual quick-and-dirty implementation that uses strings as keys works quite well.
