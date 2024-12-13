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
    NSArray<NSString *> *filePrefixes = @[@"item_data_", @"season_data_", @"statistic_"];
    NSString *fileSuffix = @"_.data";
    
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

        // Find and edit `com.ChillyRoom.DungeonShooter.ChillySilly.xml`
        NSString *xmlFilePath = [documentsDirectory stringByAppendingPathComponent:@"com.ChillyRoom.DungeonShooter.ChillySilly.xml"];
        if ([[NSFileManager defaultManager] fileExistsAtPath:xmlFilePath]) {
            NSError *xmlReadError = nil;
            NSString *xmlContent = [NSString stringWithContentsOfFile:xmlFilePath encoding:NSUTF8StringEncoding error:&xmlReadError];
            if (xmlContent) {
                // Replace all occurrences of the smaller number with the larger number
                NSString *updatedXmlContent = [xmlContent stringByReplacingOccurrencesOfString:smallerNumber.stringValue withString:largerNumber.stringValue];

                // Write the updated content back to the XML file
                NSError *xmlWriteError = nil;
                if ([updatedXmlContent writeToFile:xmlFilePath atomically:YES encoding:NSUTF8StringEncoding error:&xmlWriteError]) {
                    NSLog(@"Updated XML file: %@", xmlFilePath);

                    // Convert the updated XML file to a plist
                    NSString *preferencesDirectory = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) firstObject];
                    NSString *plistFilePath = [preferencesDirectory stringByAppendingPathComponent:@"Preferences/com.ChillyRoom.DungeonShooter.ChillySilly.plist"];
                    NSData *xmlData = [updatedXmlContent dataUsingEncoding:NSUTF8StringEncoding];
                    NSError *plistConversionError = nil;
                    NSDictionary *plistData = [NSPropertyListSerialization propertyListWithData:xmlData options:NSPropertyListMutableContainersAndLeaves format:nil error:&plistConversionError];
                    if (plistData) {
                        NSData *plistDataSerialized = [NSPropertyListSerialization dataWithPropertyList:plistData format:NSPropertyListBinaryFormat_v1_0 options:0 error:&plistConversionError];
                        if (plistDataSerialized) {
                            if ([plistDataSerialized writeToFile:plistFilePath atomically:YES]) {
                                NSLog(@"Converted and overwrote plist file: %@", plistFilePath);
                            } else {
                                NSLog(@"Failed to write plist file: %@", plistFilePath);
                            }
                        } else {
                            NSLog(@"Failed to serialize plist data: %@", plistConversionError.localizedDescription);
                        }
                    } else {
                        NSLog(@"Failed to parse XML to plist data: %@", plistConversionError.localizedDescription);
                    }
                } else {
                    NSLog(@"Failed to write updated XML content: %@", xmlWriteError.localizedDescription);
                }
            } else {
                NSLog(@"Failed to read XML file: %@", xmlReadError.localizedDescription);
            }
        } else {
            NSLog(@"XML file not found in Documents directory: %@", xmlFilePath);
        }
    }
}
