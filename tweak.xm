#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <dirent.h>
#include <unistd.h>
#include <limits.h>

// Define the ignored number
#define IGNORED_NUMBER 5253258

// Helper function to extract the numeric part from the filename
long extract_number(const char *filename, const char *prefix) {
    char *start = strstr(filename, prefix);
    if (!start) return -1;

    start += strlen(prefix);
    char *end = strchr(start, '_');
    if (!end) return -1;

    char number_str[13]; // 12 digits max + null terminator
    strncpy(number_str, start, end - start);
    number_str[end - start] = '\0';

    return atol(number_str);
}

// Function to process files for a specific prefix
void process_files(const char *directory, const char *prefix) {
    DIR *dir;
    struct dirent *entry;
    char file1[PATH_MAX] = {0}, file2[PATH_MAX] = {0};
    long num1 = -1, num2 = -1;

    // Open the directory
    dir = opendir(directory);
    if (!dir) {
        perror("opendir");
        return;
    }

    // Find two files that match the prefix
    while ((entry = readdir(dir)) != NULL) {
        if (strstr(entry->d_name, prefix) && strstr(entry->d_name, ".data")) {
            long num = extract_number(entry->d_name, prefix);
            if (num == IGNORED_NUMBER) continue; // Ignore the file with the specified number

            if (num1 == -1) {
                num1 = num;
                snprintf(file1, sizeof(file1), "%s/%s", directory, entry->d_name);
            } else {
                num2 = num;
                snprintf(file2, sizeof(file2), "%s/%s", directory, entry->d_name);
                break;
            }
        }
    }
    closedir(dir);

    // If two files were found, compare their numbers
    if (num1 != -1 && num2 != -1) {
        char larger_file[PATH_MAX], smaller_file[PATH_MAX];
        long larger_num, smaller_num;

        if (num1 > num2) {
            larger_num = num1;
            smaller_num = num2;
            strncpy(larger_file, file1, sizeof(larger_file) - 1);
            strncpy(smaller_file, file2, sizeof(larger_file) - 1);
        } else {
            larger_num = num2;
            smaller_num = num1;
            strncpy(larger_file, file2, sizeof(larger_file) - 1);
            strncpy(smaller_file, file1, sizeof(larger_file) - 1);
        }

        // Delete the larger file
        if (unlink(larger_file) == 0) {
            printf("Deleted file: %s\n", larger_file);

            // Rename the smaller file
            char new_name[PATH_MAX];
            snprintf(new_name, sizeof(new_name), "%s/%s%ld_.data", directory, prefix, larger_num);
            if (rename(smaller_file, new_name) == 0) {
                printf("Renamed file: %s -> %s\n", smaller_file, new_name);
            } else {
                perror("rename");
            }
        } else {
            perror("unlink");
        }
    }
}

int main() {
    // Path to the Documents folder
    const char *documents_path = getenv("HOME");
    if (!documents_path) {
        fprintf(stderr, "Unable to locate the HOME directory.\n");
        return 1;
    }

    char target_directory[PATH_MAX];
    snprintf(target_directory, sizeof(target_directory), "%s/Documents", documents_path);

    // Process each file category in the Documents folder
    process_files(target_directory, "item_data_");
    process_files(target_directory, "season_data_");
    process_files(target_directory, "statistic_id_");

    return 0;
}
