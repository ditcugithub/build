#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <IOKit/IOKitLib.h>

// Helper function to get the HWID (Hardware ID)
NSString *getHWID() {
    io_registry_entry_t ioRegistryRoot = IORegistryEntryFromPath(kIOMasterPortDefault, "IOService:/");
    CFStringRef uuidCf = IORegistryEntryCreateCFProperty(ioRegistryRoot, CFSTR(kIOPlatformUUIDKey), kCFAllocatorDefault, 0);
    IOObjectRelease(ioRegistryRoot);
    return (__bridge_transfer NSString *)uuidCf;
}

// Dylib implementation
@interface KeyValidator : NSObject
- (void)startValidation;
@end

@implementation KeyValidator {
    NSWindow *inputWindow;
    NSTextField *keyField;
    NSTextField *countdownLabel;
    NSButton *submitButton;
    NSInteger countdown;
    NSTimer *countdownTimer;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        countdown = 90; // Countdown starts at 90 seconds
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
    inputWindow = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 400, 200)
                                              styleMask:(NSWindowStyleMaskTitled | NSWindowStyleMaskClosable)
                                                backing:NSBackingStoreBuffered
                                                  defer:NO];
    [inputWindow setTitle:@"Enter Key"];
    [inputWindow center];

    keyField = [[NSTextField alloc] initWithFrame:NSMakeRect(20, 120, 360, 30)];
    [keyField setPlaceholderString:@"Enter your key here"];
    [[inputWindow contentView] addSubview:keyField];

    countdownLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(20, 70, 360, 30)];
    [countdownLabel setEditable:NO];
    [countdownLabel setBordered:NO];
    [countdownLabel setBackgroundColor:[NSColor clearColor]];
    [countdownLabel setFont:[NSFont systemFontOfSize:14]];
    [countdownLabel setStringValue:[NSString stringWithFormat:@"Time remaining: %ld seconds", (long)countdown]];
    [[inputWindow contentView] addSubview:countdownLabel];

    submitButton = [[NSButton alloc] initWithFrame:NSMakeRect(150, 20, 100, 30)];
    [submitButton setTitle:@"Submit"];
    [submitButton setTarget:self];
    [submitButton setAction:@selector(submitKey)];
    [[inputWindow contentView] addSubview:submitButton];

    [inputWindow makeKeyAndOrderFront:nil];
    [NSApp run];
    
    countdownTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                      target:self
                                                    selector:@selector(updateCountdown)
                                                    userInfo:nil
                                                     repeats:YES];
}

- (void)submitKey {
    NSString *key = [keyField stringValue];
    if (key.length == 0) {
        return;
    }
    [self validateKey:key];
}

- (void)validateKey:(NSString *)key {
    NSString *hwid = getHWID();
    NSString *urlString = [NSString stringWithFormat:@"https://chillysilly.frfrnocap.men/key_checker.php?key=%@&hwid=%@", key, hwid];
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
                [inputWindow close];
                [countdownTimer invalidate];
                countdownTimer = nil;
                [NSApp stop:nil];
            });
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [keyField setStringValue:@""];
                [keyField setPlaceholderString:@"Invalid key. Try again."];
            });
        }
    }];
    [task resume];
}

- (void)updateCountdown {
    countdown--;
    [countdownLabel setStringValue:[NSString stringWithFormat:@"Time remaining: %ld seconds", (long)countdown]];

    if (countdown <= 0) {
        [countdownTimer invalidate];
        countdownTimer = nil;
        [NSApp terminate:nil];
    }
}
@end

__attribute__((constructor))
static void initialize() {
    KeyValidator *validator = [[KeyValidator alloc] init];
    [validator startValidation];
}
