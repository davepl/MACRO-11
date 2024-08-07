#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#define BLOCK_SIZE 20000  /* Size of each block to allocate */

typedef struct MemoryBlock {
    char *data;
    struct MemoryBlock *next;
} MemoryBlock;

MemoryBlock *allocate_memory_blocks(total_size)
long total_size;
{
    long allocated_size = 0;
    MemoryBlock *head = NULL;
    MemoryBlock *current = NULL;

    while (allocated_size < total_size) {
        MemoryBlock *new_block = (MemoryBlock *)malloc(sizeof(MemoryBlock));
        if (new_block == NULL) {
            perror("malloc");
            exit(1);
        }
        printf("Allocated block at %p\n", new_block);
        new_block->data = (char *)malloc(BLOCK_SIZE);
        if (new_block->data == NULL) {
            perror("malloc");
            exit(1);
        }
        new_block->next = NULL;

        if (head == NULL) {
            head = new_block;
        } else {
            current->next = new_block;
        }
        current = new_block;

        allocated_size += BLOCK_SIZE;
    }
    return head;
}

void free_memory_blocks(head)
MemoryBlock *head;
{
    MemoryBlock *current = head;
    MemoryBlock *next;
    while (current != NULL) {
        next = current->next;
        free(current->data);
        free(current);
        current = next;
    }
}

int main()
{
    long total_size = 200000;  /* Example total size to allocate */
    MemoryBlock *memory_blocks = allocate_memory_blocks(total_size);
    /* Use the memory blocks... */
    /* Example: Fill each block with data */
    MemoryBlock *current = memory_blocks;
 
    while (current != NULL) {
        memset(current->data, 'A', BLOCK_SIZE);
        current = current->next;
    }

    /* Free the memory blocks when done */
    free_memory_blocks(memory_blocks);

    return 0;
}