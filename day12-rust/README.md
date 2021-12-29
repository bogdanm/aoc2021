# Overview

Solution to https://adventofcode.com/2021/day/12 in [Rust](https://www.rust-lang.org/).

- Install `rust` using your preferred method, I used [rustup](https://rustup.rs/).
- Execute `cargo run` in this directory.

`rust` version: `rustc 1.57.0 (f1edd0429 2021-11-29)`.

# Algorithm

The input data is kept in a map in which the keys are node names and the values are lists of neighbors for each node (also represented as strings). The algorithm used for solving the puzzle is in the `solve` function (which is used for solving both parts). `solve` traverses each neighbor of a node recursively in order to find all the paths from the `start` node to the `end` node. It keeps the number of times that each node was found during traversal in the `path_cnt` map, which is updated accordingly at the beginning and at the end of `solve` (only ccounts for small caves are kept in `path_cnt`, since
it is always possible to traverse big caves). The difference between solving part 1 and part 2 is in the function that decides if a neighbor node can be
traversed or not (`pred`):

- For part 1, we can traverse only caves that are big or they were not traversed yet (`path_cnt[node] == 0`).
- For part 2, we can traverse all the caves in part 1, plus small caves that have a count of 1 in `path_cnt` if there isn't any other small cave with a count of 2 in `path_cnt`, keeping in mind that the `start` node can have a count of at most 1 (the `end` node is never added to `path_cnt` in this implementation).

# Notes

`rust` is an interesting language and its safety features are very important, especially in the world of systems programming. Also, I really like the fact that the compiler's error messages are probably the best error messages that you can get from any compiler. To me, however, it is still a difficult language to love, even though I've been looking at it for a while now. The ownership rules are sometimes hard to understand (for example in this implementation where I had to juggle between `&str` and `String` types) and the combination of traits and generics can lead to code that is very hard to read and understand (and thus maintain).

Also, I believe that Rust's `async` implementation is going in a wrong direction. Besides using "colors" for async functions, the required trait bounds can get really hairy, and there are other async-related issues in the language and its libraries. IMO other languages (like Zig) are doing a better job with asynchronous programming (obviously their implementations come with their own set of issues, but they still "feel" better to me). And this is a huge shame, because getting `async` wrong is a big problem for a systems programming language. I really hope things will get better in this area in the future.
