#include <stdio.h>

extern void myPrintfWrap(const char* format, ...);

int main() {
    myPrintfWrap("%d %s %x %d %%%b%c meow meow %o\n", -1, "love", 3802, 100, 31, 33, 72);
    
    myPrintfWrap("Hello world\n");
    myPrintfWrap("%d\n", 42);
    myPrintfWrap("%d\n", -1);
    myPrintfWrap("%s\n", "test");
    myPrintfWrap("%c\n", 'A');
    myPrintfWrap("%%\n");

    return 0;
}