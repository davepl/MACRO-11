#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/time.h>

#define DEFAULT_LIMIT 1000L
#define BITSPERBYTE 8

#define GET_BIT(array, n) ((array[(n) / BITSPERBYTE] >> ((n) % BITSPERBYTE)) & 1)
#define SET_BIT(array, n) (array[(n) / BITSPERBYTE] |= (1 << ((n) % BITSPERBYTE)))

void print_help(progname)
char *progname;
{
    printf("Usage: %s [-l limit] [-h|-?]\n", progname);
    printf("Options:\n");
    printf("  -l limit  Specify the upper limit for prime calculation (default: 1000)\n");
    printf("  -h, -?    Print this help message and exit\n");
}

int main(argc, argv)
int argc;
char *argv[];
{
    long limit;
    int opt;
    long i, j;
    size_t size;
    long count;
    char *sieve;
    struct timeval start_time, end_time;
    double elapsed_time;

    limit = DEFAULT_LIMIT;

    printf("Sieve of Eratosthenes by Davepl 2024 for the PDP-11 running 211BSD\n");
    printf("------------------------------------------------------------------\n");
    
    /* Parse command-line arguments */
    while ((opt = getopt(argc, argv, "l:h?")) != -1) {
        switch (opt) {
            case 'l':
                limit = atol(optarg);
                break;
            case 'h':
            case '?':
                print_help(argv[0]);
                return 0;
            default:
                print_help(argv[0]);
                return 1;
        }
    }

    size = (limit / 2) / BITSPERBYTE + 1;
    count = 1;  /* 2 is a prime number */
    sieve = (char *) calloc(size, 1);

    printf("Solving primes up to %ld\n", limit);

    if (sieve == NULL) {
        printf("Memory allocation failed\n");
        return 1;
    }

    gettimeofday(&start_time, NULL);

    for (i = 3; i * i <= limit; i += 2)
        if (!GET_BIT(sieve, i / 2))
            for (j = i * i; j <= limit; j += 2 * i)
                SET_BIT(sieve, j / 2);

    for (i = 3; i <= limit; i += 2)
        if (!GET_BIT(sieve, i / 2))
            count++;

    gettimeofday(&end_time, NULL);

    elapsed_time = (end_time.tv_sec - start_time.tv_sec) + (end_time.tv_usec - start_time.tv_usec) / 1000000.0;

    printf("Number of primes found: %ld\n", count);
    printf("Time taken: %.2f seconds\n", elapsed_time);
    free(sieve);

    return 0;
}