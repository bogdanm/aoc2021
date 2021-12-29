# Overview

Solution to https://adventofcode.com/2021/day/1 in x64 assembly using [NASM](https://www.nasm.org/).

To build and run:

- `sudo apt install nasm`
- `sudo apt install build-essential` (if you haven't already)
- `nasm -f elf64 -o solution.o solution.asm && ld -o solution solution.o  && ./solution`

To simplify things, the input is included directly in the source by using `%include` from `NASM`.

The algorithm is trivial and is partially explained in the comments inside `solution.asm`.