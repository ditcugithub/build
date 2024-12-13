#import <Foundation/Foundation.h>

// Helper function to extract the numeric part of the file name
static NSNumber *extractNumberFromFileName(NSString *fileName, NSString *prefix, NSString *suffix) {
    NSString *trimmedFileName = [fileName stringByReplacingOccurrencesOfString:prefix withString:@""];
    trimmedFileName = [trimmedFileName stringByReplacingOccurrencesOfString:suffix withString:@""];
    return @([trimmedFileName longLongValue]);  // Convert to a number
}

__attribute__((constructor))
static void processFilesInDocuments() {
    // Get the path to the Documents directory
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    
    // Define the file patterns for processing
    NSArray<NSString *> *filePrefixes = @[@"item_data_", @"season_data_", @"statistic_id_"];
    NSString *fileSuffix = @".data";

    // Iterate over each file prefix to process files
    for (NSString *prefix in filePrefixes) {
        // Get all files in the Documents directory
        NSArray<NSString *> *allFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentsDirectory error:nil];
        
        // Filter files matching the current prefix and suffix
        NSPredicate *fileFilter = [NSPredicate predicateWithFormat:@"SELF BEGINSWITH %@ AND SELF ENDSWITH %@", prefix, fileSuffix];
        NSArray<NSString *> *filteredFiles = [allFiles filteredArrayUsingPredicate:fileFilter];
        
        // Skip processing if there are fewer than two files
        if (filteredFiles.count < 2) continue;

        // Map file names to their numeric values
        NSMutableDictionary<NSNumber *, NSString *> *fileMap = [NSMutableDictionary dictionary];
        for (NSString *fileName in filteredFiles) {
            NSNumber *number = extractNumberFromFileName(fileName, prefix, fileSuffix);
            
            // Skip files with the number 5253258
            if ([number isEqualToNumber:@5253258]) {
                NSLog(@"Ignoring file with number 5253258: %@", fileName);
                continue;
            }
            
            fileMap[number] = fileName;
        }

        // Sort the numbers
        NSArray<NSNumber *> *sortedNumbers = [[fileMap allKeys] sortedArrayUsingSelector:@selector(compare:)];

        // If there are still fewer than two valid files, skip further processing
        if (sortedNumbers.count < 2) continue;

        // Identify files to delete and rename
        NSNumber *smallerNumber = sortedNumbers[0];
        NSNumber *largerNumber = sortedNumbers[1];
        NSString *fileToDelete = fileMap[largerNumber];
        NSString *fileToRename = fileMap[smallerNumber];

        // Delete the file with the larger number
        NSString *deletePath = [documentsDirectory stringByAppendingPathComponent:fileToDelete];
        NSError *deleteError = nil;
        if ([[NSFileManager defaultManager] removeItemAtPath:deletePath error:&deleteError]) {
            NSLog(@"Deleted file: %@", fileToDelete);
        } else {
            NSLog(@"Failed to delete file: %@, error: %@", fileToDelete, deleteError.localizedDescription);
        }

        // Rename the file with the smaller number to use the larger number
        NSString *renamePath = [documentsDirectory stringByAppendingPathComponent:fileToRename];
        NSString *newFileName = [NSString stringWithFormat:@"%@%@%@", prefix, largerNumber, fileSuffix];
        NSString *newFilePath = [documentsDirectory stringByAppendingPathComponent:newFileName];
        NSError *renameError = nil;
        if ([[NSFileManager defaultManager] moveItemAtPath:renamePath toPath:newFilePath error:&renameError]) {
            NSLog(@"Renamed file: %@ -> %@", fileToRename, newFileName);
        } else {
            NSLog(@"Failed to rename file: %@, error: %@", fileToRename, renameError.localizedDescription);
        }
    }
}
