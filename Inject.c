#include <mach/mach.h>
#include <stdio.h>

// Define target addresses and their new values
typedef struct {
    uint64_t address;
    uint32_t value;
} MemoryPatch;

// List of patches
MemoryPatch patches[] = {
    {0x53AC770, 0x360080D2},
    {0x61E0EFC, 0x00902F1E},
    {0x5EC5014, 0x370080D2},
    {0x5EDDD04, 0xC0035FD6},
    {0x5DB8528, 0xC0035FD6},
};

#define PATCH_COUNT (sizeof(patches) / sizeof(MemoryPatch))

__attribute__((constructor))
void inject_code() {
    kern_return_t kr;
    mach_port_t task;

    // Get the task for the current process
    kr = task_for_pid(mach_task_self(), getpid(), &task);
    if (kr != KERN_SUCCESS) {
        printf("[ERROR] Unable to get task port: %d\n", kr);
        return;
    }

    // Apply each patch
    for (int i = 0; i < PATCH_COUNT; i++) {
        MemoryPatch patch = patches[i];

        // Write the new value to the target address
        kr = mach_vm_write(task, patch.address, (vm_offset_t)&patch.value, sizeof(patch.value));
        if (kr != KERN_SUCCESS) {
            printf("[ERROR] Unable to write memory at 0x%llx: %d\n", (unsigned long long)patch.address, kr);
            continue;
        }

        printf("[SUCCESS] Memory at 0x%llx updated to 0x%x\n", (unsigned long long)patch.address, patch.value);
    }
}
