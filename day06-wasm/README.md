# Overview

Solution to https://adventofcode.com/2021/day/6 in [WebAssembly][https://webassembly.org/]. The solution is coded using WebAssembly instructions ([wat](https://www.webassemblyman.com/wat_webassembly_text_format.html)).

- Install [wabt](https://github.com/WebAssembly/wabt). I used the CMake-based method (remember to `sudo make install` after the build to install the tools system-wide).
- `wat2wasm solution.wat -o solution.wasm`.
- Create an webserver on the solution's directory (apparently needed in some distros). The simplest way if you have Python installed (and who doesn't) is to run `python3 -m http.server` (you are using Python 3 at this point, right?).
- Open a browser to `http://localhost:8000`, enter the puzzle input (hardcoded to my own input by default) and then click `Solve`. Tested with Microsoft Edge. Chrome and Firefox should work equally well, unsure about Safari.

The actual implementation is in `solution.wat` (function `$solve`), see below for details.

The solution was initially prototyped in [WebAssembly studio](https://webassembly.studio/), which is an excellent tool for playing with WebAssembly.

# Algorithm

Since it's quite hard to "decode" the WebAssembly implementation, this is how the algorithm works:

- It keeps a counter of 9 values (currently f64 because of some hard to overcome WASM limitations (at least when writing WebAssembly by hand), but `i64` would be a better representation).
- Each position of the counter represent the total number of fish timers for that particular position. For example, if there are 3 fish with timer 2, `cnt[2] == 3`.
- All counters start at 0 and are updated according to the input data. For example, if there are 5 values of 1 in the input, `cnt[1] == 5`.
- At each step (corresponding to one day):
  * The current value of the 0 counter (`cnt[0]`) is saved to a temporary variable `temp`.
  * The counters are shifted to the left one position (which is the same as decrementing the non-0 timers for all fish).
  * The values of sixes (`cnt[6]`) is incremented by `temp`  because a zero counter becomes a six counter.
  * The values of eights (`cnt[8]`) is set to `temp`. This represents the number of new fish generated that day.

Although it might not be obvious at first (even if the puzzle text makes an explicit reference to this), the number of fish grows exponentially. This can be clearly seen in the values of the solution.

# Notes

I find WebAssembly to be a format with great potential, even if it is quite simple at the moment (or maybe precisely because it is quite simple). Coding WASM by hand (like in this solution) is a very bad idea for everything but the most trivial algorithms, but fortunately there are a lot of languages that compile to WASM, and their number is increasing. I recommend Kevin Hoffman's book "Programming WebAssembly with Rust" for people interested in WebAssembly (and Rust).