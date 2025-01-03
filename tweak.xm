#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <IOKit/IOKitLib.h>

// Helper function to get the HWID (Hardware ID)
NSString *getHWID() {
    io_registry_entry_t ioRegistryRoot = IORegistryEntryFromPath(kIOMasterPortDefault, "IOService:/");
    CFStringRef uuidCf = IORegistryEntryCreateCFProperty(ioRegistryRoot, CFSTR(kIOPlatformUUIDKey), kCFAllocatorDefault, 0);
    IOObjectRelease(ioRegistryRoot);
    return (__bridge_transfer NSString *)uuidCf;
}

// Main class for key validation
@interface KeyValidator : NSObject
- (void)startValidation;
@end

@implementation KeyValidator {
    UIWindow *keyWindow;
    UIView *keyInputView;
    UITextField *keyField;
    UILabel *countdownLabel;
    UIButton *submitButton;
    NSInteger countdown;
    NSTimer *countdownTimer;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        countdown = 90; // Set the countdown timer to 90 seconds
    }
    return self;
}

- (void)startValidation {
    NSString *savedKey = [[NSUserDefaults standardUserDefaults] stringForKey:@"savedKey"];
    if (savedKey) {
        [self validateKey:savedKey];
    } else {
        [self showKeyInputDialog];
    }
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

    // Create the countdown label
    countdownLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 100, keyInputView.frame.size.width - 40, 30)];
    countdownLabel.text = [NSString stringWithFormat:@"Time remaining: %ld seconds", (long)countdown];
    countdownLabel.textAlignment = NSTextAlignmentCenter;
    countdownLabel.font = [UIFont systemFontOfSize:14];
    [keyInputView addSubview:countdownLabel];

    // Create the submit button
    submitButton = [UIButton buttonWithType:UIButtonTypeSystem];
    submitButton.frame = CGRectMake((keyInputView.frame.size.width - 100) / 2, 140, 100, 40);
    [submitButton setTitle:@"Submit" forState:UIControlStateNormal];
    [submitButton addTarget:self action:@selector(submitKey) forControlEvents:UIControlEventTouchUpInside];
    [keyInputView addSubview:submitButton];

    [keyWindow addSubview:keyInputView];
    [keyWindow makeKeyAndVisible];

    // Start the countdown timer
    countdownTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                      target:self
                                                    selector:@selector(updateCountdown)
                                                    userInfo:nil
                                                     repeats:YES];
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
    NSString *urlString = [NSString stringWithFormat:@"https://chillysilly.frfrnocap.men/check_key.php?key=%@&hwid=%@", key, hwid];
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
                [countdownTimer invalidate];
                countdownTimer = nil;
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

- (void)updateCountdown {
    countdown--;
    countdownLabel.text = [NSString stringWithFormat:@"Time remaining: %ld seconds", (long)countdown];

    if (countdown <= 0) {
        [countdownTimer invalidate];
        countdownTimer = nil;
        exit(0); // Close the app after the timer runs out
    }
}
@end

__attribute__((constructor))
static void initialize() {
    KeyValidator *validator = [[KeyValidator alloc] init];
    [validator startValidation];
}
