#import <Foundation/Foundation.h>
#import <sys/sysctl.h>
#import <UIKit/UIKit.h>

// Function to get the device name (model)
NSString* getDeviceName() {
    size_t size;
    sysctlbyname("hw.model", NULL, &size, NULL, 0);
    
    // Allocate memory for the device name and cast malloc result to char *
    char *deviceName = (char *)malloc(size);
    sysctlbyname("hw.model", deviceName, &size, NULL, 0);
    
    // Convert the C string to an NSString and free the allocated memory
    NSString *deviceString = [NSString stringWithCString:deviceName encoding:NSUTF8StringEncoding];
    free(deviceName);
    
    return deviceString;
}

// Function to get iOS version
NSString* getIOSVersion() {
    return [[UIDevice currentDevice] systemVersion];
}

// Function to communicate with the PHP server (using NSURLSession)
void sendDeviceInfoToServer(NSString *deviceName, NSString *iosVersion) {
    NSURL *url = [NSURL URLWithString:@"https://chillysilly.run.place/check_key.php"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    
    // Set up the POST data
    NSDictionary *bodyData = @{
        @"device_name": deviceName,
        @"ios_version": iosVersion
    };
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:bodyData options:0 error:nil];
    [request setHTTPBody:jsonData];
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request
                                               completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            NSLog(@"Error sending data: %@", error);
            return;
        }
        
        // Handle server response (Assume JSON response with "access" field)
        NSDictionary *jsonResponse = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        NSInteger access = [jsonResponse[@"access"] integerValue];
        
        if (access == 0) {
            // Close the game if access is 0
            exit(0);
        } else {
            // Allow the game to continue
            NSLog(@"Game continues");
        }
    }];
    
    [dataTask resume];
}

// Main function to check device and communicate with the server
void checkAndSendDeviceInfo() {
    NSString *deviceName = getDeviceName();
    NSString *iosVersion = getIOSVersion();
    
    sendDeviceInfoToServer(deviceName, iosVersion);
}

int main() {
    checkAndSendDeviceInfo();
    return 0;
}
