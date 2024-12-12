#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

void __attribute__((constructor)) closeAppOnLaunch(void) {
    // Wait for 5 seconds
    sleep(5);
    
    // Exit the application after waiting
    exit(0);
}
