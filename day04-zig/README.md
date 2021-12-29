# Overview

Solution to https://adventofcode.com/2021/day/4 in [zig](https://ziglang.org/) (version 0.8.1).

There are different ways to install zig, I used [brew](https://brew.sh) because it's easy and I was using brew anyway:

- Install `brew` (see https://brew.sh for installation instructions).
- `brew install zig`
- `zig run solution.zig`

# Notes

I was quite anxious to give `zig` a try, since I've been reading many positive things about it lately. Many people are calling it "the next (and better) C". But first impressions are hard to get right sometimes, and while my first impressions were mostly positive, they were still mixed. However, I am very new to Zig, so take the next paragraphs with lots of grains of salt.

The good:

- "error union" types that combine an actual value with an error condition in a single type. In order to get the value from this type, you have to test it explicitly (`try result`). Similar idea to Rust's `enum Result`.
- Optionals (`?i32`). Similar idea to Rust's `enum Option`.
- Good (and interesting) support for compile time constructs.
- The async suport. I **LOVE** the fact that there are no "function colors" in Zig. I read a number of arguments in favor of function colors in Rust, but I couldn't buy into any of them. Zig's way of doing async is much better IMO.
- Not depending on libc is a huge advantage for small targets (like MCUs) and I expect that it has major implications for the async functionality.
- You have to explicitly pass an allocator to functions that need to allocate memory. Besides making it very clear which functions need to allocate memory, this has the advantage that you can easily provide different allocators for different purposes.
- Large and helpful community (I askeged a question on `zig-help` (Discord) on a Saturday afternoon and got a response back almost instantly).

The bad:

- Still quite verbose (one of the main complaints against Go). For example, there's no numeric for. While I understand the concept of "for is only for iterating over collections", it gets tedious and annoying to write `while` loops instead of `for` loops every time.
- Documentation is far from complete. Be prepared to take a look at the source code and/or join Discord or a similar service to get help with the language.
- The error messages aren't too helpful sometimes. It took me a while to figure out why Zig was complaining that I was trying to assign to a constant inside of a function embedded in a struct (there was no word about this in the documentation).
- Syntax feels weird at times, especially when defining more complex types. A `typedef`-like feature would be really helpful.
- No preprocessor. For all the shortcomings of the C preprocessor, I'd rather have it than live without it. Some other modern languages have some form of macros (which are generally much better than C macros), but Zig doesn't have that either.
- The standard library is still quite small and incomplete (but still good for a pre-1.0.0 release).

All in all, a very interesting language. I intend to keep a close eye on in in the future.
