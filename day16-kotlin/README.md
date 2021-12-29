# Overview

Solution to https://adventofcode.com/2021/day/16 in [Kotlin](https://kotlinlang.org/) (using the native toolchain).

To build and run:

- Follow the instructions at https://kotlinlang.org/docs/native-command-line-compiler.html to install Kotlin/Native and add it to your PATH.
- Go to `<install_dir>/bin` and run `./generate-platform -target linux_x64`. I couldn't find this documented anywhere, but this step is needed to generate the `platform.posix` package which is not installed by default (although all the information that I was able to find suggests that it should be installed by default). This was quite an annoying issue, since google didn't return any useful results. Basically I had to guess that somewhere there's a script for generating libraries and that I had to run it manually after untaring the release archive.
- `kotlinc-native solution.kt -o solution && ./solution.kexe`

Kotlin native version:

```
info: kotlinc-native 1.6.10 (JRE 11.0.13+8-Ubuntu-0ubuntu1.20.04)
Kotlin/Native: 1.6.10
```