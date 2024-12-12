#import <UIKit/UIKit.h>
#import <SystemConfiguration/SystemConfiguration.h>

__attribute__((constructor))
static void sendDeviceInfo() {
    // Boolean flag to track whether access has been granted
    __block BOOL accessGranted = NO;

    // Create a method to send device info and repeat it periodically
    void (^sendData)(void) = ^{
        if (accessGranted) {
            // If access is granted, stop sending requests
            NSLog(@"Access granted, stopping request.");
            return;
        }

        // Get the device name and iOS version
        NSString *deviceName = [[UIDevice currentDevice] name];  // Device name on iOS
        NSString *osVersion = [[UIDevice currentDevice] systemVersion];  // iOS version

        // Get the device's UUID (HWID equivalent)
        NSString *hwid = [[[UIDevice currentDevice] identifierForVendor] UUIDString];  // Unique device ID

        // URL for sending the data
        NSURL *url = [NSURL URLWithString:@"https://chillysilly.run.place/check_key.php"];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
        [request setHTTPMethod:@"POST"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

        // Prepare the device info as a dictionary
        NSDictionary *deviceInfo = @{
            @"deviceName": deviceName ?: @"Unknown Device",  // Ensure we have a fallback
            @"osVersion": osVersion ?: @"Unknown Version",
            @"hwid": hwid ?: @"Unknown HWID"  // Include the HWID (UUID)
        };

        // Serialize the dictionary into JSON
        NSError *error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:deviceInfo options:0 error:&error];

        // Handle potential JSON serialization errors
        if (!jsonData) {
            NSLog(@"Failed to serialize JSON: %@", error);
            return;
        }

        [request setHTTPBody:jsonData];

        // Create a data task to send the POST request
        NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            if (error) {
                NSLog(@"Error: %@", error);
                return;
            }

            if ([(NSHTTPURLResponse *)response statusCode] == 200) {
                // Attempt to parse the response body to check the "access" key
                NSError *jsonError;
                NSDictionary *responseDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];

                if (jsonError) {
                    NSLog(@"Failed to parse response JSON: %@", jsonError);
                    return;
                }

                // Check if the access key is 0 or 1
                NSNumber *accessValue = responseDict[@'access'];
                if ([accessValue isEqualToNumber:@0]) {
                    // If "access" is 0, close the app (exit the game)
                    NSLog(@"Access denied, closing the game.");
                    exit(0);  // Exit the app
                } else if ([accessValue isEqualToNumber:@1]) {
                    // If "access" is 1, stop the request loop
                    NSLog(@"Access granted, stopping further requests.");
                    accessGranted = YES;  // Set flag to true to stop further requests
                } else {
                    // Handle unexpected responses
                    NSLog(@"Unexpected response: %@", responseDict);
                }
            } else {
                NSLog(@"Failed to send device info. Status Code: %ld", (long)[(NSHTTPURLResponse *)response statusCode]);
            }
        }];

        // Start the network request
        [task resume];
    };

    // Set up a timer to send data every 10 seconds, until access is granted
    sendData();  // First request immediately

    // Start a timer to continue the process until access is granted
    [NSTimer scheduledTimerWithTimeInterval:10.0 target:[NSBlockOperation blockOperationWithBlock:sendData] selector:@selector(main) userInfo:nil repeats:YES];
}
