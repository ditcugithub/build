#import <UIKit/UIKit.h>

@interface Tweak : NSObject
+ (void)handlePan:(UIPanGestureRecognizer *)gesture;
+ (void)handlePinch:(UIPinchGestureRecognizer *)gesture;
+ (void)startTimedEvents:(NSArray *)songNotes;
+ (void)uploadButtonPressed:(UIButton *)button;
+ (void)loadButtonPressed:(UIButton *)button;
+ (void)startStopButtonPressed:(UIButton *)button;
@end

@implementation Tweak

static BOOL isPlaying = NO;  // Track whether events are playing
static NSTimer *timer = nil;  // Timer for event playback
static NSArray *songNotesArray = nil;  // Store the song notes for playback
static NSInteger currentIndex = 0;  // Index to track the current event
static NSString *sheetDirectory; // Directory for storing the files
static NSMutableDictionary<NSString *, UIView *> *keyViews; // Dictionary to track key views

__attribute__((constructor))
static void initialize() {
    // Create "sheet" directory in the application's documents directory
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    sheetDirectory = [paths.firstObject stringByAppendingPathComponent:@"sheet"];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:sheetDirectory]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:sheetDirectory withIntermediateDirectories:YES attributes:nil error:nil];
    }

    // Initialize key views
    keyViews = [NSMutableDictionary dictionary];

    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *window = nil;

        // Use UIWindowScene for iOS 15 and later
        if (@available(iOS 15.0, *)) {
            UIWindowScene *windowScene = nil;
            for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
                if ([scene isKindOfClass:[UIWindowScene class]]) {
                    windowScene = (UIWindowScene *)scene;
                    break;
                }
            }

            if (windowScene) {
                window = windowScene.keyWindow;  // Access the key window in the scene
            }
        } else {
            // Fallback for older iOS versions
            window = UIApplication.sharedApplication.delegate.window; // Use delegate's window for backward compatibility
        }

        if (window) {
            // Create keys on the screen and add to the keyViews dictionary
            for (int i = 0; i <= 14; i++) {
                UILabel *keyLabel = [[UILabel alloc] initWithFrame:CGRectMake(50 + (i * 40), 300, 35, 50)];
                keyLabel.text = [NSString stringWithFormat:@"Key%d", i];
                keyLabel.textAlignment = NSTextAlignmentCenter;
                keyLabel.backgroundColor = [UIColor lightGrayColor];
                keyLabel.layer.cornerRadius = 10;
                keyLabel.layer.masksToBounds = YES;
                keyLabel.userInteractionEnabled = YES;

                // Add pan gesture to move the key
                UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:[Tweak class] action:@selector(handlePan:)];
                [keyLabel addGestureRecognizer:panGesture];

                [window addSubview:keyLabel];
                keyViews[[NSString stringWithFormat:@"Key%d", i]] = keyLabel; // Store the label in the dictionary
            }

            // Upload Button
            UIButton *uploadButton = [UIButton buttonWithType:UIButtonTypeSystem];
            uploadButton.frame = CGRectMake(20, 100, 80, 50);
            [uploadButton setTitle:@"Upload" forState:UIControlStateNormal];
            [uploadButton addTarget:[Tweak class] action:@selector(uploadButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
            uploadButton.userInteractionEnabled = YES;
            UIPanGestureRecognizer *uploadPanGesture = [[UIPanGestureRecognizer alloc] initWithTarget:[Tweak class] action:@selector(handlePan:)];
            [uploadButton addGestureRecognizer:uploadPanGesture];
            [window addSubview:uploadButton];

            // Load Button
            UIButton *loadButton = [UIButton buttonWithType:UIButtonTypeSystem];
            loadButton.frame = CGRectMake(120, 100, 80, 50);
            [loadButton setTitle:@"Load" forState:UIControlStateNormal];
            [loadButton addTarget:[Tweak class] action:@selector(loadButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
            loadButton.userInteractionEnabled = YES;
            UIPanGestureRecognizer *loadPanGesture = [[UIPanGestureRecognizer alloc] initWithTarget:[Tweak class] action:@selector(handlePan:)];
            [loadButton addGestureRecognizer:loadPanGesture];
            [window addSubview:loadButton];

            // Start Button
            UIButton *startButton = [UIButton buttonWithType:UIButtonTypeSystem];
            startButton.frame = CGRectMake(220, 100, 80, 50);
            [startButton setTitle:@"Start" forState:UIControlStateNormal];
            [startButton addTarget:[Tweak class] action:@selector(startStopButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
            startButton.userInteractionEnabled = YES;
            UIPanGestureRecognizer *startPanGesture = [[UIPanGestureRecognizer alloc] initWithTarget:[Tweak class] action:@selector(handlePan:)];
            [startButton addGestureRecognizer:startPanGesture];
            [window addSubview:startButton];
        }
    });
}

+ (void)uploadButtonPressed:(UIButton *)button {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Upload"
                                                                   message:@"Enter the download link:"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addTextFieldWithConfigurationHandler:nil];
    
    UIAlertAction *submitAction = [UIAlertAction actionWithTitle:@"Submit" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSString *urlString = alert.textFields[0].text;
        NSURL *url = [NSURL URLWithString:urlString];
        
        if (url) {
            NSURLSession *session = [NSURLSession sharedSession];
            [[session dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                if (data) {
                    // Save the file to the "sheet" directory
                    NSString *filePath = [sheetDirectory stringByAppendingPathComponent:@"song.txt"];
                    [data writeToFile:filePath atomically:YES];

                    NSLog(@"File downloaded and saved to: %@", filePath);
                } else {
                    NSLog(@"Failed to download file: %@", error.localizedDescription);
                }
            }] resume];
        } else {
            NSLog(@"Invalid URL");
        }
    }];
    
    [alert addAction:submitAction];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    
    // Present the alert
    UIWindow *window = nil;
    if (@available(iOS 15.0, *)) {
        for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
            if ([scene isKindOfClass:[UIWindowScene class]]) {
                window = ((UIWindowScene *)scene).keyWindow; // Get the key window from the window scene
                break;
            }
        }
    } else {
        window = UIApplication.sharedApplication.delegate.window; // Use delegate's window for older iOS versions
    }
    [window.rootViewController presentViewController:alert animated:YES completion:nil];
}

+ (void)loadButtonPressed:(UIButton *)button {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *files = [fileManager contentsOfDirectoryAtPath:sheetDirectory error:nil];

    if (files.count > 0) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Load File"
                                                                       message:@"Select a file to load:"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        for (NSString *file in files) {
            UIAlertAction *fileAction = [UIAlertAction actionWithTitle:file style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [self loadFile:file];
            }];
            [alert addAction:fileAction];
        }
        [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
        
        // Present the alert
        UIWindow *window = nil;
        if (@available(iOS 15.0, *)) {
            for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
                if ([scene isKindOfClass:[UIWindowScene class]]) {
                    window = ((UIWindowScene *)scene).keyWindow; // Get the key window from the window scene
                    break;
                }
            }
        } else {
            window = UIApplication.sharedApplication.delegate.window; // Use delegate's window for older iOS versions
        }
        [window.rootViewController presentViewController:alert animated:YES completion:nil];
    } else {
        NSLog(@"No files found in the sheet directory.");
    }
}

+ (void)loadFile:(NSString *)fileName {
    NSString *filePath = [sheetDirectory stringByAppendingPathComponent:fileName];
    
    NSError *error = nil;
    NSData *data = [NSData dataWithContentsOfFile:filePath options:0 error:&error];
    
    if (error) {
        NSLog(@"Error reading file: %@", error.localizedDescription);
        return;
    }
    
    NSError *jsonError = nil;
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
    
    if (jsonError) {
        NSLog(@"JSON parsing error: %@", jsonError.localizedDescription);
        return;
    }
    
    NSArray *songNotes = jsonDict[@"songNotes"];
    [self startTimedEvents:songNotes];
}

+ (void)startTimedEvents:(NSArray *)songNotes {
    songNotesArray = songNotes;
    currentIndex = 0; // Reset index for new song notes
    isPlaying = YES; // Start playing

    timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:[Tweak class] selector:@selector(playEvents) userInfo:nil repeats:YES];
}

+ (void)playEvents {
    if (currentIndex < songNotesArray.count) {
        NSDictionary *note = songNotesArray[currentIndex];
        NSNumber *time = note[@"time"];
        NSString *key = note[@"key"];
        
        // Check if it's time to simulate the click
        if (CACurrentMediaTime() * 1000 >= time.doubleValue) {
            [self simulateClickForKey:key];
            currentIndex++;
        }
    } else {
        [timer invalidate];
        timer = nil;
        isPlaying = NO;
        NSLog(@"Playback finished");
    }
}

+ (void)simulateClickForKey:(NSString *)key {
    UIView *keyView = keyViews[key];
    if (keyView) {
        CGPoint keyPosition = [keyView center]; // Get the current center position of the key

        // Simulating the click at the key's position
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"Simulating click at: %@", NSStringFromCGPoint(keyPosition));
            // Here you would implement the logic to simulate a tap at keyPosition
            // For actual touch simulation, consider using a custom approach or third-party libraries.
        });
    } else {
        NSLog(@"No view found for key: %@", key);
    }
}

+ (void)handlePan:(UIPanGestureRecognizer *)gesture {
    UIView *movableView = gesture.view;
    CGPoint translation = [gesture translationInView:movableView.superview];

    // Update the position of the key or button
    movableView.center = CGPointMake(movableView.center.x + translation.x, movableView.center.y + translation.y);
    [gesture setTranslation:CGPointZero inView:movableView.superview];
}

+ (void)handlePinch:(UIPinchGestureRecognizer *)gesture {
    // This method can be implemented if you want pinch-to-zoom functionality
    // Currently, it is empty as no functionality was specified
}

+ (void)startStopButtonPressed:(UIButton *)button {
    // Implement start/stop logic to toggle playback
    if (isPlaying) {
        [timer invalidate];
        timer = nil;
        isPlaying = NO;
        [button setTitle:@"Start" forState:UIControlStateNormal];
    } else {
        isPlaying = YES;
        [button setTitle:@"Stop" forState:UIControlStateNormal];
        [self startTimedEvents:songNotesArray]; // Restart the playback with the existing song notes
    }
}

@end
