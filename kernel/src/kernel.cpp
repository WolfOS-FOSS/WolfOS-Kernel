#include "kernel.h"
#include <string.h>

// Global Kernel State
static kernel_t kernel;

// Initialize Memory Manager
void init_memory() {
    memset(kernel.mem_manager.page_usage, 0, sizeof(kernel.mem_manager.page_usage));
}

// Allocate a Page
void* alloc_page() {
    for (int i = 0; i < MAX_PAGES; i++) {
        if (!kernel.mem_manager.page_usage[i]) {
            kernel.mem_manager.page_usage[i] = true;
            return static_cast<void*>(&kernel.mem_manager.memory[i * PAGE_SIZE]);
        }
    }
    return nullptr;  // Out of memory
}

// Free a Page
void free_page(void* page) {
    uintptr_t addr = reinterpret_cast<uintptr_t>(page);
    size_t index = (addr - reinterpret_cast<uintptr_t>(kernel.mem_manager.memory)) / PAGE_SIZE;
    if (index < MAX_PAGES) {
        kernel.mem_manager.page_usage[index] = false;
    }
}

// Initialize Process Manager
void init_process_manager() {
    kernel.process_count = 0;
    memset(kernel.processes, 0, sizeof(kernel.processes));
}

// Create a Process
int create_process(const char* name, int pid) {
    if (kernel.process_count >= MAX_PROCESSES) {
        return -1;  // Process table full
    }
    process_t* proc = &kernel.processes[kernel.process_count++];
    proc->pid = pid;
    strncpy(proc->name, name, sizeof(proc->name) - 1);
    proc->active = true;
    return pid;
}

// Schedule Processes
void schedule() {
    for (int i = 0; i < kernel.process_count; i++) {
        if (kernel.processes[i].active) {
            // Placeholder for actual scheduling logic
        }
    }
}

// Initialize File System
void init_file_system() {
    memset(kernel.files, 0, sizeof(kernel.files));
}

// Create a File
int create_file(const char* name, size_t size) {
    for (int i = 0; i < MAX_FILES; i++) {
        if (!kernel.files[i].in_use) {
            kernel.files[i].id = i;
            strncpy(kernel.files[i].name, name, sizeof(kernel.files[i].name) - 1);
            kernel.files[i].size = size;
            kernel.files[i].in_use = true;
            return i;
        }
    }
    return -1;  // No space for new files
}

// Initialize Network
void init_network() {
    // Stub: Initialize networking components (e.g., TCP/IP stack)
}

// Kernel Entry Point
void kernel_main() {
    init_memory();
    init_process_manager();
    init_file_system();
    init_network();

    create_process("init", 1);
    int file_id = create_file("log.txt", 1024);
    if (file_id >= 0) {
        // File created successfully
    }

    uint8_t* page = static_cast<uint8_t*>(alloc_page());
    if (page != nullptr) {
        // Successfully allocated a page
        free_page(page);
    }

    while (true) {
        schedule();
    }
}
