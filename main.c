#include <stdio.h>
#include <limits.h>
#include <math.h>

extern void myPrintfWrap(const char* format, ...);

int main() {
    // goto start;
    // printf("%g\n\n", 3.0545e234);
    // myPrintfWrap("%f\n", 3.0545e234);
    myPrintfWrap("%f\n", 3.15);
    // myPrintfWrap("%f\n", 3.15e-1);

    // myPrintfWrap("%f\n", -INFINITY);
    myPrintfWrap("%f\n", 3.626);
    // myPrintfWrap("%f\n", NAN);
    
    // myPrintfWrap("Hello world\n");
    // myPrintfWrap("%d\n", 42);
    // myPrintfWrap("%d\n", -1);
    // myPrintfWrap("%s\n", "test");
    // myPrintfWrap("%c\n", 'A');
    // myPrintfWrap("%%\n");

    // myPrintfWrap("%d %s %x\n", 10, "hello", 255);
    // myPrintfWrap("%d%%%d\n", 50, 60);
    // myPrintfWrap("%s %c %d\n", "wow", 'Z', -123);

    // myPrintfWrap("%d\n", 123);
    // myPrintfWrap("%b\n", 5);
    // myPrintfWrap("%o\n", 15);
    // myPrintfWrap("%x\n", 255);
    // myPrintfWrap("%c\n", 65);
    // myPrintfWrap("%s\n", "hello");

    // myPrintfWrap("%d\n", 0);
    // myPrintfWrap("%d\n", INT_MAX);
    // myPrintfWrap("%d\n", INT_MIN);

    // myPrintfWrap("%x\n", 0);
    // myPrintfWrap("%o\n", 0);
    // myPrintfWrap("%b\n", 0);

    // myPrintfWrap("%d %d %d %d %d %d\n", 1, 2, 3, 4, 5, 6);
    
    // myPrintfWrap("%f %d%d%d%d%d \n", 145.2, 1, 2, 3, 4, 5);

    // myPrintfWrap("%%%%%%\n");      
    // myPrintfWrap("%d%d%d\n", 1,2,3);   
    // myPrintfWrap("%s%d%s\n", "a", 1, "b");

    // myPrintfWrap("%d %d %d\n", 1); 
    // myPrintfWrap("%d\n", 1, 2, 3);   

    // myPrintfWrap("");
    // myPrintfWrap("\n");

    return 0;
}