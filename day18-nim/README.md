# Overview

Solution to https://adventofcode.com/2021/day/18 in [nim](https://nim-lang.org).

- Install `nim` (see https://nim-lang.org/install_unix.html, I used the `choosenim` method).
- `nim c -r solution.nim`

`nim` version: `Nim Compiler Version 1.6.0 [Linux: amd64]`

# Algorithm

The pairs (called "numbers" in the puzzle) are kept as binary trees. The implementation consists mostly of fairly common traversal operations on binary trees. However, the code also keeps a list of the leaves in the binary tree (the actual numbers) to make it easier to find the next/previous number for an "explode" operation, and a suitable number for a "split" operation. This list of leaves is also updated when the tree is changed due to an "explode" or a "split", since it has to be kept "in sync" with the tree at all times.

# Notes

I gave `nim` a try out of curiosity mostly, but I ended up enjoying it more than I thought I would. It feels simple and intuitive, like Python, but of course it is a very different language. It has a number of interesting features, my favorite one is the very powerful macro support. There are however a number of things that I don't get about the language:

- Up until today, I thought that programming languages are either case sensitive or case insensitive. However:

```
Note however that Nim is both case- and underscore-insensitive meaning that helloWorld and hello_world would be the same name. The exception to this is the first character, which is case-sensitive.
```

Are there good reasons for a programming language to be mostly case-insensitive, but not completely? And why would underscores be ignored? This rule feels like it's adding a WTF factor that nobody actually needed.

- Procedures can return a result, but there's also an implicit `result` variable in the procedure (automatically defined by the language) and you can return a value from a procedure using either `return val` or `result = val`. I don't understand this decision, seems like an unneeded complication (Pascal influence maybe?). More than that, it can lead to weird behaviors:

```
The result variable is already implicitly declared at the start of the function, so declaring it again with 'var result', for example, would shadow it with a normal variable of the same name.
```

There are advantages to the default `result` variable, for example the fact that it is automatically initialized to the "0 value" of the return type, but this still feels unneeded.

- Some functions in the standard library have more than just a signature, they also hardcode implicit parameter names. Take for example the function `allIt` from `sequtils`:

```
template allIt(s, pred: untyped): bool
Iterates through a container and checks if every item fulfills the predicate.

The predicate needs to be an expression using the it variable for testing, like: allIt("abba", it == 'a').

Example:

let numbers = @[1, 4, 5, 8, 9, 7, 4]
assert numbers.allIt(it < 10) == true
assert numbers.allIt(it < 9) == false
```

So you don't have to know just that `allIt` takes a container and a predicate function, but also that the predicate function has an argument that is always called `it`. Why do that, especially when you have a nice shorthand for functions? The above examples could have been written like this:

```
import sugar

let numbers = @[1, 4, 5, 8, 9, 7, 4]
assert all(numbers, (x) => x < 10) == true
assert all(numbers, (x) => x < 9) == false
```

Do the extra chars needed to write the version above really justify the addition of a function that uses "magic" argument names?

With all these negatives in mind, I still like `nim`. It's breaking my personal version of "the principle of least astonishment" here and there, but overall I enjoy writing `nim` code. I will probably use it again in the future.
