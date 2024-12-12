#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <Foundation/Foundation.h>

@interface UIApplication (ChillySillyKeySystem)

- (void)showKeyInputPrompt;
- (void)updateStatus:(UIAlertController *)alertController withKey:(NSString *)key;
- (void)startCountdownTimerForAlert:(UIAlertController *)alertController;
- (void)shutDownGame;
- (void)validateKeyWithPHPBackend:(NSString *)key hwid:(NSString *)hwid completion:(void(^)(NSString *status))completion;

@end

%hook UIApplication

// Hooking the applicationDidFinishLaunching method
- (void)applicationDidFinishLaunching:(UIApplication *)application {
    %orig(application);

    // Call custom methods here
    [self showKeyInputPrompt];
}

// Custom method to show key input prompt
- (void)showKeyInputPrompt {
    // Disable user interaction to freeze the game
    UIWindow *mainWindow = [UIApplication sharedApplication].connectedScenes.allObjects.firstObject.delegate.window;
    UIViewController *rootVC = mainWindow.rootViewController;
    rootVC.view.userInteractionEnabled = NO;

    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"ChillySilly Key System"
                                                                             message:@"Status: Checking...\nClose the game after 90s\n\nInput key:"
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    
    NSString *savedKey = [[NSUserDefaults standardUserDefaults] stringForKey:@"savedKey"];

    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        if (savedKey) {
            textField.text = savedKey;
        }
    }];
    
    UIAlertAction *submitAction = [UIAlertAction actionWithTitle:@"Submit"
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction *action) {
        NSString *input = alertController.textFields.firstObject.text;
        [self updateStatus:alertController withKey:input];
    }];
    [alertController addAction:submitAction];

    [rootVC presentViewController:alertController animated:YES completion:nil];
    [self startCountdownTimerForAlert:alertController];
}

// Custom method to update status
- (void)updateStatus:(UIAlertController *)alertController withKey:(NSString *)key {
    UILabel *statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 200, 40)];
    statusLabel.textAlignment = NSTextAlignmentCenter;
    statusLabel.center = CGPointMake(alertController.view.bounds.size.width / 2, alertController.view.bounds.size.height - 120);
    [alertController.view addSubview:statusLabel];
    
    NSString *hwid = [[UIDevice currentDevice] identifierForVendor].UUIDString;
    [self validateKeyWithPHPBackend:key hwid:hwid completion:^(NSString *status) {
        // Ensure UI updates happen on the main thread
        dispatch_async(dispatch_get_main_queue(), ^{
            statusLabel.text = status;
            if ([status isEqualToString:@"Status: Key Valid!"]) {
                statusLabel.textColor = [UIColor greenColor];
            } else {
                statusLabel.textColor = [UIColor redColor];
            }
        });
    }];
}

// Custom method to start countdown timer
- (void)startCountdownTimerForAlert:(UIAlertController *)alertController {
    __block int countdown = 90;
    
    UILabel *countdownLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 200, 40)];
    countdownLabel.text = [NSString stringWithFormat:@"Closing in %ds", countdown];
    countdownLabel.textAlignment = NSTextAlignmentCenter;
    countdownLabel.center = CGPointMake(alertController.view.bounds.size.width / 2, alertController.view.bounds.size.height - 60);
    [alertController.view addSubview:countdownLabel];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        while (countdown > 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                countdownLabel.text = [NSString stringWithFormat:@"Closing in %ds", countdown];
            });
            sleep(1);
            countdown--;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (alertController.isBeingDismissed == NO) {
                [self shutDownGame];
            }
        });
    });
}

// Custom method to shut down the game
- (void)shutDownGame {
    // Calling exit(0) to shut down the game
    exit(0);
}

// Custom method to validate key via PHP backend
- (void)validateKeyWithPHPBackend:(NSString *)key hwid:(NSString *)hwid completion:(void(^)(NSString *status))completion {
    NSString *urlString = [NSString stringWithFormat:@"https://chillysilly.run.place/check_key.php?key=%@&hwid=%@", key, hwid];
    NSURL *url = [NSURL URLWithString:urlString];
    
    NSURLSessionDataTask *dataTask = [[NSURLSession sharedSession] dataTaskWithURL:url
                                                                 completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            completion(@"Status: Error connecting to server.");
            return;
        }
        
        NSString *status = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        completion(status);
    }];
    [dataTask resume];
}

%end
