#ifndef KERNEL_H
#define KERNEL_H

#include <stddef.h>
#include <stdint.h>
#include <stdbool.h>

#define MAX_PROCESSES 16
#define MAX_PAGES 256
#define PAGE_SIZE 4096
#define MAX_FILES 16

// Memory Management
typedef struct {
    bool page_usage[MAX_PAGES];
    uint8_t memory[MAX_PAGES * PAGE_SIZE];
} memory_manager_t;

// Process Management
typedef struct {
    int pid;
    char name[32];
    bool active;
} process_t;

// File System
typedef struct {
    int id;
    char name[64];
    size_t size;
    bool in_use;
} file_t;

// Kernel Structures
typedef struct {
    memory_manager_t mem_manager;
    process_t processes[MAX_PROCESSES];
    file_t files[MAX_FILES];
    int process_count;
} kernel_t;

// Kernel Functions
void init_memory();
void init_process_manager();
void init_file_system();
void init_network();
void schedule();
void* alloc_page();
void free_page(void* page);
int create_file(const char* name, size_t size);
int create_process(const char* name, int pid);
void kernel_main();

#endif
