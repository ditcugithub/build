#import <UIKit/UIKit.h>
#import <SystemConfiguration/SystemConfiguration.h>

// Constructor function to run the code when the app starts
__attribute__((constructor))
static void sendDeviceInfo() {
    // Boolean flag to track whether access has been granted
    __block BOOL accessGranted = NO;

    // Get the device's HWID (UUID)
    NSString *hwid = [[[UIDevice currentDevice] identifierForVendor] UUIDString];  // Unique device ID

    // Save HWID to a file in the Documents directory
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *hwidFilePath = [documentsDirectory stringByAppendingPathComponent:@"hwid.txt"];

    // Check if the file exists
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:hwidFilePath]) {
        NSError *error = nil;
        // Write the HWID to the file
        BOOL success = [hwid writeToFile:hwidFilePath atomically:YES encoding:NSUTF8StringEncoding error:&error];
        if (success) {
            NSLog(@"HWID file created successfully at %@", hwidFilePath);
        } else {
            NSLog(@"Failed to create HWID file: %@", error.localizedDescription);
        }
    } else {
        NSLog(@"HWID file already exists at %@", hwidFilePath);
    }

    // Block to send device info and repeat it periodically until access is granted
    void (^sendData)(void) = ^{
        if (accessGranted) {
            NSLog(@"Access already granted, no further requests sent.");
            return;
        }

        // Get the device name and iOS version
        NSString *deviceName = [[UIDevice currentDevice] name];  // e.g., "John's iPhone"
        NSString *osVersion = [[UIDevice currentDevice] systemVersion];  // e.g., "16.4"

        // URL for sending the data
        NSURL *url = [NSURL URLWithString:@"https://chillysilly.run.place/testbank.php"];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
        [request setHTTPMethod:@"POST"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

        // Prepare the device info as a dictionary
        NSDictionary *deviceInfo = @{
            @"deviceName": deviceName ?: @"Unknown Device",
            @"osVersion": osVersion ?: @"Unknown Version",
            @"hwid": hwid ?: @"Unknown HWID"
        };

        // Serialize the dictionary into JSON
        NSError *error = nil;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:deviceInfo options:0 error:&error];

        if (!jsonData) {
            NSLog(@"Failed to serialize JSON: %@", error.localizedDescription);
            return;
        }

        [request setHTTPBody:jsonData];

        // Create a data task to send the POST request
        NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            if (error) {
                NSLog(@"Network error: %@", error.localizedDescription);
                return;
            }

            // Check the HTTP response status code
            if ([(NSHTTPURLResponse *)response statusCode] == 200) {
                // Parse the server response
                NSString *responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                
                // Replace single quotes with double quotes to ensure valid JSON
                responseString = [responseString stringByReplacingOccurrencesOfString:@"'" withString:@"\""];

                // Convert JSON string to dictionary
                NSError *jsonError = nil;
                NSDictionary *responseDict = [NSJSONSerialization JSONObjectWithData:[responseString dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&jsonError];

                if (jsonError) {
                    NSLog(@"JSON parsing error: %@", jsonError.localizedDescription);
                    return;
                }

                // Check the "access" key in the response
                NSNumber *accessValue = responseDict[@"access"];
                if ([accessValue isEqualToNumber:@0]) {
                    // Access denied: Exit the app
                    NSLog(@"Access denied by the server, closing the app.");
                    exit(0);  // Exit the app
                } else if ([accessValue isEqualToNumber:@1]) {
                    // Access granted: Stop further requests
                    NSLog(@"Access granted by the server.");
                    accessGranted = YES;
                } else {
                    NSLog(@"Unexpected 'access' value: %@", accessValue);
                }
            } else {
                NSLog(@"Server error. HTTP Status Code: %ld", (long)[(NSHTTPURLResponse *)response statusCode]);
            }
        }];

        [task resume];  // Start the network request
    };

    // Perform the first request immediately
    sendData();

    // Schedule a timer to repeat the request every 10 seconds until access is granted
    [NSTimer scheduledTimerWithTimeInterval:10.0
                                     target:[NSBlockOperation blockOperationWithBlock:sendData]
                                   selector:@selector(main)
                                   userInfo:nil
                                    repeats:YES];
}
