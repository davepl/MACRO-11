/* Github Primes Project (c) Plummer's Software, Inc. 2018-2024

   This is a simple sieve that compiles and runs under 211BSD using the default
   cc compiler. It is a simple sieve that counts the number of primes up to
   the limit.

   It uses one bit per even numnber.

*/
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define LIMIT 500000L
#define BITSPERBYTE 8

#define GET_BIT(array, n) ((array[(n) / BITSPERBYTE] >> ((n) % BITSPERBYTE)) & 1)
#define SET_BIT(array, n) (array[(n) / BITSPERBYTE] |= (1 << ((n) % BITSPERBYTE)))

int main() 
{
    long i, j;
    size_t size = (LIMIT / 2) / BITSPERBYTE + 1;
    long count = 1;
    char * sieve = (char *) calloc(size, 1);

    printf("Solving primes up to %ld\n", LIMIT);

    if (sieve == NULL) {
        printf("Memory allocation failed\n");
        return 1;
    }
   
    for (i = 3; i * i <= LIMIT; i += 2) 
        if (!GET_BIT(sieve, i / 2)) 
            for (j = i * i; j <= LIMIT; j += 2 * i) 
                SET_BIT(sieve, j / 2);
    
    for (i = 3; i <= LIMIT; i += 2) 
        if (!GET_BIT(sieve, i / 2)) 
            count++;

    printf("Number of primes found: %ld\n", count);
    free(sieve);

    return 0;
}


