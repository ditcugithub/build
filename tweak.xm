#include <UIKit/UIKit.h>
#include <Foundation/Foundation.h>
#include <objc/runtime.h>
#include <objc/message.h>
#include <IOKit/IOKitLib.h>
#include <sys/sysctl.h>
#include <stdlib.h>
#include <unistd.h>

@interface KeyInputViewController : UIViewController
@property (nonatomic, strong) UITextField *keyTextField;
@property (nonatomic, strong) UIButton *submitButton;
@property (nonatomic, strong) UIButton *menuButton;
@property (nonatomic, strong) UILabel *countdownLabel;
@property (nonatomic, assign) NSInteger countdown;
@end

@implementation KeyInputViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    // Key input field
    self.keyTextField = [[UITextField alloc] initWithFrame:CGRectMake(50, 100, 300, 40)];
    self.keyTextField.placeholder = @"Enter key";
    self.keyTextField.borderStyle = UITextBorderStyleRoundedRect;
    [self.view addSubview:self.keyTextField];
    
    // Submit button
    self.submitButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.submitButton.frame = CGRectMake(50, 150, 300, 40);
    [self.submitButton setTitle:@"Submit" forState:UIControlStateNormal];
    [self.submitButton addTarget:self action:@selector(submitKey) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.submitButton];
    
    // Countdown Label
    self.countdownLabel = [[UILabel alloc] initWithFrame:CGRectMake(50, 200, 300, 40)];
    self.countdownLabel.text = @"Time remaining: 90s";
    self.countdownLabel.textColor = [UIColor redColor];
    [self.view addSubview:self.countdownLabel];
    
    // Countdown Timer
    self.countdown = 90;
    [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(updateCountdown) userInfo:nil repeats:YES];
    
    // Menu Button (Hidden initially)
    self.menuButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.menuButton.frame = CGRectMake(50, 300, 100, 40);
    [self.menuButton setTitle:@"Menu" forState:UIControlStateNormal];
    [self.menuButton addTarget:self action:@selector(showMenu) forControlEvents:UIControlEventTouchUpInside];
    self.menuButton.hidden = YES;
    [self.view addSubview:self.menuButton];
}

- (void)submitKey {
    NSString *key = self.keyTextField.text;
    NSString *hwid = [self getHwid];  // Get the HWID here
    
    NSString *urlString = [NSString stringWithFormat:@"https://chillysilly.frfrnocap.men/checkkey.php?key=%@&hwid=%@", key, hwid];
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    NSURLSessionDataTask *dataTask = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            NSLog(@"Error: %@", error);
            return;
        }
        
        NSDictionary *responseDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        if ([responseDict[@"status"] isEqualToString:@"success"]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                // Key is valid, close input and show menu
                self.keyTextField.hidden = YES;
                self.submitButton.hidden = YES;
                self.countdownLabel.hidden = YES;
                self.menuButton.hidden = NO;
            });
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                // Key is invalid, show alert
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Invalid Key" message:@"The key is invalid or already linked to another HWID." preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
                [self presentViewController:alert animated:YES completion:nil];
            });
        }
    }];
    [dataTask resume];
}

- (NSString *)getHwid {
    // Retrieve HWID from IORegistry (this is the device's UUID)
    io_registry_entry_t entry = IORegistryEntryFromPath(kIOMasterPortDefault, "IOService:/");
    CFStringRef uuid = IORegistryEntryCreateCFProperty(entry, CFSTR(kIOPlatformUUIDKey), kCFAllocatorDefault, 0);
    
    // Convert UUID to NSString
    NSString *hwid = (__bridge NSString *)uuid;
    
    return hwid ? hwid : @"unknown";
}

- (void)updateCountdown {
    self.countdown--;
    self.countdownLabel.text = [NSString stringWithFormat:@"Time remaining: %lds", (long)self.countdown];
    
    if (self.countdown <= 0) {
        // Timeout, close the app
        exit(0);
    }
}

- (void)showMenu {
    UIAlertController *menuAlert = [UIAlertController alertControllerWithTitle:@"Menu" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    [menuAlert addAction:[UIAlertAction actionWithTitle:@"Download" style:UIAlertActionStyleDefault handler:nil]];
    [menuAlert addAction:[UIAlertAction actionWithTitle:@"Upload" style:UIAlertActionStyleDefault handler:nil]];
    [menuAlert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    
    [self presentViewController:menuAlert animated:YES completion:nil];
}

@end

%ctor {
    Class keyInputVCClass = objc_allocateClassPair([UIViewController class], "KeyInputViewController", 0);
    class_addMethod(keyInputVCClass, @selector(viewDidLoad), (IMP)keyInputViewController_viewDidLoad, "v@:");
    objc_registerClassPair(keyInputVCClass);

    id keyInputVC = [[keyInputVCClass alloc] init];
    UIApplication *app = [UIApplication sharedApplication];
    if (@available(iOS 15.0, *)) {
        UIWindowScene *windowScene = (UIWindowScene *)app.connectedScenes.allObjects.firstObject;
        UIWindow *window = windowScene.windows.firstObject;
        [window setRootViewController:keyInputVC];
    } else {
        UIWindow *window = app.keyWindow;
        [window setRootViewController:keyInputVC];
    }
}
