#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

// Utility function to get HWID
NSString *getHWID() {
    return [[[UIDevice currentDevice] identifierForVendor] UUIDString];
}

// KeyValidator Class
@interface KeyValidator : NSObject
- (void)startValidation;
- (void)showMenu;
@end

@implementation KeyValidator {
    UIWindow *keyWindow;
    UIView *keyInputView;
    UITextField *keyField;
    UIButton *menuButton;
    NSInteger countdown;
    NSTimer *countdownTimer;
    UIView *menuView;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        countdown = 90; // Set the countdown timer to 90 seconds
    }
    return self;
}

- (void)startValidation {
    // Ensure all UI operations are performed on the main thread
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *savedKey = [[NSUserDefaults standardUserDefaults] stringForKey:@"savedKey"];
        if (savedKey) {
            [self validateKey:savedKey];
        } else {
            [self showKeyInputDialog];
        }
    });
}

- (void)showKeyInputDialog {
    // Create a new UIWindow
    keyWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    keyWindow.backgroundColor = [UIColor colorWithWhite:0 alpha:0.7];
    keyWindow.windowLevel = UIWindowLevelAlert + 1;

    // Create the main view for the key input dialog
    keyInputView = [[UIView alloc] initWithFrame:CGRectMake(50, 200, keyWindow.frame.size.width - 100, 200)];
    keyInputView.backgroundColor = [UIColor whiteColor];
    keyInputView.layer.cornerRadius = 10;

    // Create the key input field
    keyField = [[UITextField alloc] initWithFrame:CGRectMake(20, 50, keyInputView.frame.size.width - 40, 40)];
    keyField.placeholder = @"Enter your key";
    keyField.borderStyle = UITextBorderStyleRoundedRect;
    keyField.textAlignment = NSTextAlignmentCenter;
    [keyInputView addSubview:keyField];

    // Create the submit button
    UIButton *submitButton = [UIButton buttonWithType:UIButtonTypeSystem];
    submitButton.frame = CGRectMake((keyInputView.frame.size.width - 100) / 2, 120, 100, 40);
    [submitButton setTitle:@"Submit" forState:UIControlStateNormal];
    [submitButton addTarget:self action:@selector(submitKey) forControlEvents:UIControlEventTouchUpInside];
    [keyInputView addSubview:submitButton];

    [keyWindow addSubview:keyInputView];
    [keyWindow makeKeyAndVisible];
}

- (void)submitKey {
    NSString *key = keyField.text;
    if (key.length == 0) {
        return;
    }
    [self validateKey:key];
}

- (void)validateKey:(NSString *)key {
    NSString *hwid = getHWID();
    NSString *urlString = [NSString stringWithFormat:@"https://chillysilly.frfrnocap.men/checkkey.php?key=%@&hwid=%@", key, hwid];
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            NSLog(@"Validation Error: %@", error.localizedDescription);
            return;
        }

        NSDictionary *result = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        NSString *status = result[@"status"];
        if ([status isEqualToString:@"success"]) {
            [[NSUserDefaults standardUserDefaults] setObject:key forKey:@"savedKey"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            dispatch_async(dispatch_get_main_queue(), ^{
                [keyWindow resignKeyWindow];
                keyWindow = nil;
                [self showMenu];
            });
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                keyField.text = @"";
                keyField.placeholder = @"Invalid key. Try again.";
            });
        }
    }];
    [task resume];
}

- (void)showMenu {
    // Create a movable button
    menuButton = [UIButton buttonWithType:UIButtonTypeSystem];
    menuButton.frame = CGRectMake(50, 150, 100, 40);
    [menuButton setTitle:@"Menu" forState:UIControlStateNormal];
    [menuButton addTarget:self action:@selector(toggleMenu) forControlEvents:UIControlEventTouchUpInside];

    // Add the button to the keyWindow
    [keyWindow addSubview:menuButton];
}

- (void)toggleMenu {
    // Create a menu view
    if (menuView == nil) {
        menuView = [[UIView alloc] initWithFrame:CGRectMake(50, 200, 200, 150)];
        menuView.backgroundColor = [UIColor whiteColor];
        menuView.layer.cornerRadius = 10;
        menuView.layer.shadowOpacity = 0.3;
        menuView.layer.shadowOffset = CGSizeMake(2, 2);

        // Create buttons for "Download", "Upload", "Cancel"
        UIButton *downloadButton = [UIButton buttonWithType:UIButtonTypeSystem];
        downloadButton.frame = CGRectMake(20, 20, 160, 40);
        [downloadButton setTitle:@"Download" forState:UIControlStateNormal];
        [downloadButton addTarget:self action:@selector(downloadAction) forControlEvents:UIControlEventTouchUpInside];
        [menuView addSubview:downloadButton];

        UIButton *uploadButton = [UIButton buttonWithType:UIButtonTypeSystem];
        uploadButton.frame = CGRectMake(20, 70, 160, 40);
        [uploadButton setTitle:@"Upload" forState:UIControlStateNormal];
        [uploadButton addTarget:self action:@selector(uploadAction) forControlEvents:UIControlEventTouchUpInside];
        [menuView addSubview:uploadButton];

        UIButton *cancelButton = [UIButton buttonWithType:UIButtonTypeSystem];
        cancelButton.frame = CGRectMake(20, 120, 160, 40);
        [cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
        [cancelButton addTarget:self action:@selector(cancelAction) forControlEvents:UIControlEventTouchUpInside];
        [menuView addSubview:cancelButton];

        [keyWindow addSubview:menuView];
    } else {
        menuView.hidden = !menuView.hidden;
    }
}

- (void)downloadAction {
    NSLog(@"Download button pressed");
    // Add download action logic here
}

- (void)uploadAction {
    NSLog(@"Upload button pressed");
    // Add upload action logic here
}

- (void)cancelAction {
    NSLog(@"Cancel button pressed");
    // Add cancel action logic here
}
@end

__attribute__((constructor))
static void initialize() {
    KeyValidator *validator = [[KeyValidator alloc] init];
    [validator startValidation];
}
