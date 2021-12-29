# Overview

Solution to https://adventofcode.com/2021/day/20 in C.

To build and run:

- `sudo apt install build-essential` (if not already installed).
- `gcc -o solution solution.c && ./solution`

# Algorithm

At each decoding step, the algorithm considers the current image, plus one pixel outside of it in all directions (up/down/left/rigtht), since those are the pixels from the "infinite space" that could be changed because of the image (the other pixels don't interesect the image in the sense of the 3x3 neighboring pixels defined by the puzzle). The color of the pixels outside the image (the default color) can also vary:

- If entry 0 in the decoder is 0, the default color never changes, since the color of the default pixels will decode to the first entry in the decoder.
- If entry 0 in the decoder is 1, the default color changes from 0 to 1 after the first decoding step. Then:
  * If the last entry in the decoder is 1, the default color never changes again (since the default pixels will always decode to the last entry in the decoder).
  * If the last entry in the decoder is 0, the default color alternates from 0 to 1 in each step. In this case, the answer to "How many pixels are lit in the resulting image?" after each odd step is "infinity".

The output after each decoding step is a new image that is larger by 2 pixels in each dimension (width and height). This new image becomes the input of the decoder in the next step and the process continues.