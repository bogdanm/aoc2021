#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <stdbool.h>
#include <assert.h>
#include <string.h>

// ********************************************************************************************************************
// Local fuctions and data

// Length of the decode string
#define DECODE_STR_LEN                  512
// Conversion from char to light/dark pixel
#define CHR2PIXEL(c)                    ((c) == '#' ? 1 : 0)
// Convert an (y, x) coordinate to an array index
#define CRD2IDX(y, x)                   ((y) * cols + (x))

// Decoding algorithm
static uint8_t algorithm[DECODE_STR_LEN];
// Current image size
static int lines = -1, cols = -1;
// Current image data
static uint8_t *img_data;
// Current step
static uint8_t step = 1;

// Read input from the given file
static void read_input(const char *fname) {
    char crt_line[DECODE_STR_LEN + 2]; // +1 \n +1 \0
    unsigned line_no = 1;
    unsigned img_idx = 0;

    FILE *fp = fopen(fname, "rt");
    while (true) {
        // Read next line and exit on EOF
        if (fgets(crt_line, sizeof(crt_line), fp) == NULL) {
            break;
        }
        // Remove endline char if found
        size_t l = strlen(crt_line);
        if ((crt_line[l - 1] == '\n') || (crt_line[l - 1] == '\r')) {
            crt_line[l - 1] = '\0';
        }
        // Interpret the data
        if (line_no == 1) { // this is the algorithm
            assert(strlen(crt_line) == DECODE_STR_LEN);
            for (unsigned i = 0; i < DECODE_STR_LEN; i ++) {
                algorithm[i] = CHR2PIXEL(crt_line[i]);
            }
        } else if (line_no == 2) { // empty line
            assert(strlen(crt_line) == 0);
        } else { // image data
            if (lines < 0) { // first time reading image data
                // The puzzle doesn't specify that the image is a square, but that seems to be the case, so simplify the
                // implementation a bit and assume that the number of lines and columns is equal (which means that we know
                // how much memory we need to allocate for the image now).
                lines = cols = strlen(crt_line);
                img_data = (uint8_t*)malloc(lines * cols);
            }
            for (unsigned i = 0; i < strlen(crt_line); i ++) {
                img_data[img_idx ++] = CHR2PIXEL(crt_line[i]);
            }
        }
        line_no ++;
    }
    fclose(fp);
}

// Get the default pixel color (the pixels outside the known image) at the current step
static uint8_t get_default_color(void) {
    if (algorithm[0] == 0) { // always 0
        return 0;
    } else {
        if (algorithm[DECODE_STR_LEN - 1] == 1) { // 0 at step 1, 1 after
            return step == 1 ? 0 : 1;
        } else { // alternating
            return step % 2 == 1 ? 0 : 1;
        }
    }
}

// Return the pixel at the given coordinates, keeping in mind that it might be outside of the current image
static uint8_t get_at(int y, int x) {
    if (y >= 0 && y < lines && x >= 0 && x < cols) { // known pixel, return it
        return img_data[CRD2IDX(y, x)];
    } else {
        return get_default_color(); // return the default color at the current step
    }
}

// Return the computed index in the algorithm array for the given pixel
static size_t get_algorithm_idx(int y, int x) {
    size_t res = 0;

    // Look at all the neighbors left to right and top to bottom
    for (int y_off = -1; y_off <= 1; y_off ++) {
        for (int x_off = -1; x_off <= 1; x_off ++) {
            res = res * 2 + get_at(y + y_off, x + x_off); // build index one bit at a time
        }
    }
    return res;
}

// Perform a single decode step
static void decode_once() {
    // Compute the new image size and allocate the new image data
    int new_lines = lines + 2;
    int new_cols = cols + 2;
    uint8_t *new_image = (uint8_t*)malloc(new_lines * new_cols);
    unsigned img_idx = 0;

    // Iterate one pixel outside the previous image in each direction and save the decoded image in new_image
    for (int y = -1; y <= lines; y ++) {
        for (int x = -1; x <= cols; x ++) {
            new_image[img_idx ++] = algorithm[get_algorithm_idx(y, x)];
        }
    }
    // Update image data
    free(img_data);
    img_data = new_image;
    cols = new_cols;
    lines = new_lines;
    // And increment the step number
    step ++;
}

// Count the number of ones in the image (which in this case means the sum of the elements in img_data)
static unsigned count_ones() {
    unsigned res = 0;

    for (unsigned i = 0; i < lines * cols; i ++) {
        res += img_data[i];
    }
    return res;
}

// ********************************************************************************************************************
// Publinc interface

int main() {
    read_input("input.txt");

    // Part 1: run decode twice
    decode_once();
    decode_once();
    printf("Part 1: %u\n", count_ones());
    // Part 2: run decode 48 more times (to get to 50)
    for (int i = 0; i < 48; i ++) {
        decode_once();
    }
    printf("Part 2: %u\n", count_ones());
}
