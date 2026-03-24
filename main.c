#include <stdio.h>

extern void myPrintfWrap(const char* format, ...);

int main() {
    myPrintfWrap("%d %s %x %d%%%b%c meow meow %o\n", -1, "love", 3802, 100, 31, 33, 72);
    // myPrintfWrap("");
    return 0;
}