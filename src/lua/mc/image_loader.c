#define STB_IMAGE_IMPLEMENTATION
#include "stb_image.h"

#define STB_IMAGE_WRITE_IMPLEMENTATION
#include "stb_image_write.h"

#include <stdlib.h>

unsigned char* mc_load_image(const char* filename, int* width, int* height, int* channels, int desired_channels) {
    return stbi_load(filename, width, height, channels, desired_channels);
}

void mc_free_image(unsigned char* pixels) {
    stbi_image_free(pixels);
}
