#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <stdlib.h>

__attribute__((constructor))
void checkLibraryFolderAccess() {
    // Get the path to the Library folder for the current app's sandbox
    NSString *libraryPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) firstObject];
    
    // Use NSFileManager to check if the folder is accessible
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDirectory;
    
    // Check if the Library folder exists and is a directory
    if (![fileManager fileExistsAtPath:libraryPath isDirectory:&isDirectory] || !isDirectory) {
        // If Library folder is not accessible, terminate the app
        exit(0); // Terminate the app
    }
}
