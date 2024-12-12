#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <Foundation/Foundation.h>

%hook UIApplication

// Declare the instance methods you're calling within the hook.
- (void)showKeyInputPrompt;
- (void)updateStatus:(UIAlertController *)alertController withKey:(NSString *)key;
- (void)startCountdownTimerForAlert:(UIAlertController *)alertController;
- (void)shutDownGame;
- (void)validateKeyWithPHPBackend:(NSString *)key hwid:(NSString *)hwid completion:(void(^)(NSString *status))completion;

- (void)applicationDidFinishLaunching:(UIApplication *)application {
    // Call the original method
    %orig(application);

    // Freeze the game and show the key input prompt with a countdown
    [self showKeyInputPrompt];
}

- (void)showKeyInputPrompt {
    // Disable user interaction to freeze the game
    UIWindow *mainWindow = [UIApplication sharedApplication].connectedScenes.allObjects.firstObject.delegate.window;
    UIView *rootView = mainWindow.rootViewController.view;
    rootView.userInteractionEnabled = NO;

    // Create an alert controller with a message
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"ChillySilly Key System"
                                                                             message:@"Status: Checking...\nClose the game after 90s\n\nInput key:"
                                                                      preferredStyle:UIAlertControllerStyleAlert];

    // Retrieve the stored key from UserDefaults
    NSString *savedKey = [[NSUserDefaults standardUserDefaults] stringForKey:@"savedKey"];

    // Add a text field for key input, if savedKey exists, autofill it
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        if (savedKey) {
            textField.text = savedKey;  // Auto-fill the key if it exists
        }
    }];

    // Create a submit button
    UIAlertAction *submitAction = [UIAlertAction actionWithTitle:@"Submit"
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction *action) {
        NSString *input = alertController.textFields.firstObject.text;
        [self updateStatus:alertController withKey:input];
    }];
    [alertController addAction:submitAction];

    // Show the alert on the root view controller
    UIViewController *rootVC = mainWindow.rootViewController;
    [rootVC presentViewController:alertController animated:YES completion:nil];

    // Start a timer for the 90s countdown
    [self startCountdownTimerForAlert:alertController];
}

- (void)startCountdownTimerForAlert:(UIAlertController *)alertController {
    __block int countdown = 90;  // 90 seconds countdown
    UILabel *countdownLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 200, 40)];
    countdownLabel.text = [NSString stringWithFormat:@"Closing in %ds", countdown];
    [alertController.view addSubview:countdownLabel];

    // Update countdown every second
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        while (countdown > 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                countdownLabel.text = [NSString stringWithFormat:@"Closing in %ds", countdown];
            });
            sleep(1);
            countdown--;
        }
        
        // When the countdown finishes, shut down the game if no key was entered
        dispatch_async(dispatch_get_main_queue(), ^{
            if (alertController.isBeingDismissed == NO) {
                [self shutDownGame];
            }
        });
    });
}

- (void)updateStatus:(UIAlertController *)alertController withKey:(NSString *)key {
    // Get the status label
    UILabel *statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 200, 40)];
    [alertController.view addSubview:statusLabel];

    // Collect HWID (identifierForVendor) for validation
    NSString *hwid = [[UIDevice currentDevice] identifierForVendor].UUIDString;

    // Call PHP backend to validate the key and HWID
    [self validateKeyWithPHPBackend:key hwid:hwid completion:^(NSString *status) {
        statusLabel.text = status;
        if ([status isEqualToString:@"Status: Key Valid!"]) {
            statusLabel.textColor = [UIColor greenColor]; // Green for valid key
        } else {
            statusLabel.textColor = [UIColor redColor]; // Red for invalid key or expired
        }
    }];
}

- (void)validateKeyWithPHPBackend:(NSString *)key hwid:(NSString *)hwid completion:(void(^)(NSString *status))completion {
    // URL for the PHP backend script
    NSString *urlString = [NSString stringWithFormat:@"https://chillysilly.run.place/check_key.php?key=%@&hwid=%@", key, hwid];
    NSURL *url = [NSURL URLWithString:urlString];

    // Send the request to the server
    NSURLSessionDataTask *dataTask = [[NSURLSession sharedSession] dataTaskWithURL:url
                                                                 completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            completion(@"Status: Error connecting to server.");
            return;
        }

        // Process the server response (validate key, HWID, and expiration)
        NSString *status = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        completion(status);
    }];
    [dataTask resume];
}

- (void)shutDownGame {
    // Log shutdown and exit the app by killing the app's process
    NSLog(@"Key input timeout, shutting down the game.");
    exit(0);
}

%end
