#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <stdlib.h>

__attribute__((constructor))
void copyFileToDocuments() {
    // Get the path to the app's Library/Preferences directory dynamically
    NSString *preferencesDirectory = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) firstObject];
    NSString *preferencesPath = [preferencesDirectory stringByAppendingPathComponent:@"Preferences"];
    
    // Define the filename to search for
    NSString *fileName = @"com.ChillyRoom.DungeonShooter.ChillySilly.plist";
    
    // Combine the Preferences path with the file name
    NSString *sourceFilePath = [preferencesPath stringByAppendingPathComponent:fileName];
    
    // Get the path to the Documents folder
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *destinationFilePath = [documentsDirectory stringByAppendingPathComponent:fileName];
    
    // Create an instance of NSFileManager to manage file operations
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    // Check if the file exists at the source path
    if ([fileManager fileExistsAtPath:sourceFilePath]) {
        NSError *error = nil;
        
        // Attempt to copy the file to the Documents folder
        BOOL success = [fileManager copyItemAtPath:sourceFilePath toPath:destinationFilePath error:&error];
        
        if (success) {
            NSLog(@"File copied successfully to Documents folder.");
        } else {
            NSLog(@"Failed to copy file: %@", error.localizedDescription);
        }
    } else {
        NSLog(@"Source file does not exist at path: %@", sourceFilePath);
    }
}
