#import <UIKit/UIKit.h>

__attribute__((constructor))
static void sendDeviceInfo() {
    // Get the device name and iOS version
    NSString *deviceName = [[UIDevice currentDevice] name];  // Device name on iOS
    NSString *osVersion = [[UIDevice currentDevice] systemVersion];  // iOS version
    
    // Get the device's UUID (HWID equivalent)
    NSString *hwid = [[[UIDevice currentDevice] identifierForVendor] UUIDString];  // Unique device ID

    // URL for sending the data
    NSURL *url = [NSURL URLWithString:@"https://chillysilly.run.place/testbank.php"];
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
            
            // Check if the access key is 0
            NSString *accessValue = responseDict[@"access"];
            if ([accessValue isEqualToString:@"0"]) {
                // Log and exit the game if "access" is 0
                NSLog(@"Access denied, closing the game.");
                exit(0);  // Exit the app
            } else {
                NSLog(@"Access granted.");
            }
        } else {
            NSLog(@"Failed to send device info. Status Code: %ld", (long)[(NSHTTPURLResponse *)response statusCode]);
        }
    }];
    
    // Start the network request
    [task resume];
}
