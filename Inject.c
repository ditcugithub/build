#include <mach/mach.h>
#include <mach/mach_vm.h>  // Required for mach_vm_write
#include <unistd.h>        // Required for getpid
#include <mach-o/dyld.h>   // Required for ASLR bypass
#include <stdio.h>
#include <dlfcn.h>

// Define target addresses and their new values
typedef struct {
    uint64_t address;
    uint32_t value;
} MemoryPatch;

// List of patches (hardcoded base addresses)
MemoryPatch patches[] = {
    {0x61E0EFC, 0x00902F1E},
    {0x5EC5014, 0x370080D2},
    {0x5EDDD04, 0xC0035FD6},
    {0x5DB8528, 0xC0035FD6},
    {0x53AC770, 0x360080D2},  // Added new patch
};

#define PATCH_COUNT (sizeof(patches) / sizeof(MemoryPatch))

// Helper function to resolve ASLR-based addresses
uint64_t resolve_address(uint64_t base_address) {
    const struct mach_header* header = _dyld_get_image_header(0);
    uint64_t slide = _dyld_get_image_vmaddr_slide(0);
    return base_address + slide;
}

// Function to temporarily change memory permissions
void change_permissions(mach_port_t task, uint64_t address, size_t size) {
    kern_return_t kr = mach_vm_protect(task, address, size, 0, VM_PROT_READ | VM_PROT_WRITE | VM_PROT_COPY);
    if (kr != KERN_SUCCESS) {
        printf("[ERROR] Unable to change memory protections: %d\n", kr);
    }
}

// Bypass anti-debugging
void bypass_anti_debugging() {
    void* handle = dlopen("/usr/lib/system/libsystem_kernel.dylib", RTLD_NOW);
    if (handle) {
        typedef int (*ptrace_t)(int request, pid_t pid, caddr_t addr, int data);
        ptrace_t ptrace = (ptrace_t)dlsym(handle, "ptrace");
        if (ptrace) {
            ptrace(31, 0, 0, 0);  // PTRACE_DENY_ATTACH
        }
        dlclose(handle);
    }
}

// Constructor function to execute on injection
__attribute__((constructor))
void inject_code() {
    kern_return_t kr;
    mach_port_t task;

    printf("[INFO] Starting injection...\n");

    // Bypass anti-debugging
    bypass_anti_debugging();

    // Get the task for the current process
    kr = task_for_pid(mach_task_self(), getpid(), &task);
    if (kr != KERN_SUCCESS) {
        printf("[ERROR] Unable to get task port: %d\n", kr);
        return;
    }

    // Apply each patch
    for (int i = 0; i < PATCH_COUNT; i++) {
        MemoryPatch patch = patches[i];
        uint64_t resolved_address = resolve_address(patch.address);  // Resolve ASLR

        // Temporarily change memory permissions
        change_permissions(task, resolved_address, sizeof(patch.value));

        // Write the new value to the target address
        kr = mach_vm_write(task, resolved_address, (vm_offset_t)&patch.value, sizeof(patch.value));
        if (kr != KERN_SUCCESS) {
            printf("[ERROR] Unable to write memory at 0x%llx: %d\n", (unsigned long long)resolved_address, kr);
            continue;
        }

        printf("[SUCCESS] Memory at 0x%llx updated to 0x%x\n", (unsigned long long)resolved_address, patch.value);
    }

    printf("[INFO] Injection completed.\n");
}
