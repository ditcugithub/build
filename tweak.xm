#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface Tweak : NSObject
+ (void)handlePan:(UIPanGestureRecognizer *)gesture;
+ (void)handlePinch:(UIPinchGestureRecognizer *)gesture;
+ (void)startTimedEvents;
+ (void)uploadButtonPressed:(UIButton *)button;
+ (void)loadButtonPressed:(UIButton *)button;
+ (void)deleteButtonPressed:(UIButton *)button;
+ (void)startStopButtonPressed:(UIButton *)button;
+ (void)stopPlayback;
+ (void)simulateKeypress:(NSString *)key;
@end

@implementation Tweak

static BOOL isPlaying = NO;
static NSTimer *timer = nil;
static NSArray *songNotesArray = nil;
static NSInteger currentIndex = 0;
static NSString *sheetDirectory;
static NSMutableDictionary<NSString *, UIView *> *keyViews;
static NSString *mainFile;
static AVSpeechSynthesizer *synthesizer;
static double startTime;
static NSMutableArray *keyPressTimers;

__attribute__((constructor))
static void initialize() {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    sheetDirectory = [paths.firstObject stringByAppendingPathComponent:@"sheet"];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:sheetDirectory isDirectory:NULL]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:sheetDirectory withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    keyViews = [NSMutableDictionary dictionary];
    synthesizer = [[AVSpeechSynthesizer alloc] init];
    keyPressTimers = [NSMutableArray array];

    dispatch_async(dispatch_get_main_queue(), ^{
        for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
            if ([scene isKindOfClass:[UIWindowScene class]]) {
                UIWindowScene *windowScene = (UIWindowScene *)scene;
                NSArray<UIWindow *> *windows = windowScene.windows;
                if (windows.count > 0) {
                    UIWindow *window = windows[0];
                    for (int i = 0; i <= 14; i++) {
                        UILabel *keyLabel = [[UILabel alloc] initWithFrame:CGRectMake(50 + (i * 40), 300, 35, 50)];
                        keyLabel.text = [NSString stringWithFormat:@"Key%d", i];
                        keyLabel.accessibilityLabel = keyLabel.text;
                        keyLabel.textAlignment = NSTextAlignmentCenter;
                        keyLabel.backgroundColor = [UIColor lightGrayColor];
                        keyLabel.layer.cornerRadius = 10;
                        keyLabel.layer.masksToBounds = YES;
                        keyLabel.font = [UIFont systemFontOfSize:10];
                        keyLabel.userInteractionEnabled = YES;
                        UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:[Tweak class] action:@selector(handlePan:)];
                        [keyLabel addGestureRecognizer:panGesture];
                        [window addSubview:keyLabel];
                        keyViews[[NSString stringWithFormat:@"Key%d", i]] = keyLabel;
                    }

                    UIButton *uploadButton = [UIButton buttonWithType:UIButtonTypeSystem];
                    uploadButton.frame = CGRectMake(20, 100, 80, 50);
                    [uploadButton setTitle:@"Upload" forState:UIControlStateNormal];
                    [uploadButton addTarget:[Tweak class] action:@selector(uploadButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
                    [window addSubview:uploadButton];

                    UIButton *loadButton = [UIButton buttonWithType:UIButtonTypeSystem];
                    loadButton.frame = CGRectMake(120, 100, 80, 50);
                    [loadButton setTitle:@"Load" forState:UIControlStateNormal];
                    [loadButton addTarget:[Tweak class] action:@selector(loadButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
                    [window addSubview:loadButton];

                    UIButton *deleteButton = [UIButton buttonWithType:UIButtonTypeSystem];
                    deleteButton.frame = CGRectMake(220, 100, 80, 50);
                    [deleteButton setTitle:@"Delete" forState:UIControlStateNormal];
                    [deleteButton addTarget:[Tweak class] action:@selector(deleteButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
                    [window addSubview:deleteButton];

                    UIButton *startButton = [UIButton buttonWithType:UIButtonTypeSystem];
                    startButton.frame = CGRectMake(320, 100, 80, 50);
                    [startButton setTitle:@"Start" forState:UIControlStateNormal];
                    [startButton addTarget:[Tweak class] action:@selector(startStopButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
                    [window addSubview:startButton];
                }
                break;
            }
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
            UIAlertController *fileNameAlert = [UIAlertController alertControllerWithTitle:@"File Name"
                                                                                  message:@"Enter the name for the downloaded file:"
                                                                           preferredStyle:UIAlertControllerStyleAlert];
            [fileNameAlert addTextFieldWithConfigurationHandler:nil];

            UIAlertAction *downloadAction = [UIAlertAction actionWithTitle:@"Download" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                NSString *fileName = fileNameAlert.textFields[0].text;
                if (fileName.length > 0) {
                    NSURLSession *session = [NSURLSession sharedSession];
                    [[session dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                        if (data) {
                            NSString *filePath = [sheetDirectory stringByAppendingPathComponent:fileName];
                            [data writeToFile:filePath atomically:YES];
                            NSLog(@"File downloaded and saved to: %@", filePath);
                        } else {
                            NSLog(@"Failed to download file: %@", error.localizedDescription);
                        }
                    }] resume];
                } else {
                    NSLog(@"Invalid file name");
                }
            }];
            
            [fileNameAlert addAction:downloadAction];
            [fileNameAlert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
            
            for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
                if ([scene isKindOfClass:[UIWindowScene class]]) {
                    UIWindowScene *windowScene = (UIWindowScene *)scene;
                    UIWindow *window = windowScene.windows.firstObject;
                    UIViewController *rootViewController = window.rootViewController;
                    if (rootViewController) {
                        [rootViewController presentViewController:fileNameAlert animated:YES completion:nil];
                    }
                    break;
                }
            }
            
        } else {
            NSLog(@"Invalid URL");
        }
    }];
    
    [alert addAction:submitAction];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if ([scene isKindOfClass:[UIWindowScene class]]) {
            UIWindowScene *windowScene = (UIWindowScene *)scene;
            UIWindow *window = windowScene.windows.firstObject;
            UIViewController *rootViewController = window.rootViewController;
            if (rootViewController) {
                [rootViewController presentViewController:alert animated:YES completion:nil];
            }
            break;
        }
    }
}

+ (void)loadButtonPressed:(UIButton *)button {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *files = [fileManager contentsOfDirectoryAtPath:sheetDirectory error:nil];

    if (files.count > 0) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Load File"
                                                                       message:@"Select a file to set as main:"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        for (NSString *file in files) {
            UIAlertAction *fileAction = [UIAlertAction actionWithTitle:file style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                mainFile = file;
                NSLog(@"Main file set to: %@", mainFile);
            }];
            [alert addAction:fileAction];
        }
        [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
        
        for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
            if ([scene isKindOfClass:[UIWindowScene class]]) {
                UIWindowScene *windowScene = (UIWindowScene *)scene;
                UIWindow *window = windowScene.windows.firstObject;
                UIViewController *rootViewController = window.rootViewController;
                if (rootViewController) {
                    [rootViewController presentViewController:alert animated:YES completion:nil];
                }
                break;
            }
        }
    } else {
        NSLog(@"No files found in the sheet directory.");
    }
}

+ (void)deleteButtonPressed:(UIButton *)button {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *files = [fileManager contentsOfDirectoryAtPath:sheetDirectory error:nil];

    if (files.count > 0) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Delete File"
                                                                       message:@"Select a file to delete:"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        for (NSString *file in files) {
            UIAlertAction *fileAction = [UIAlertAction actionWithTitle:file style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
                NSString *filePath = [sheetDirectory stringByAppendingPathComponent:file];
                NSError *error = nil;
                if ([fileManager removeItemAtPath:filePath error:&error]) {
                    NSLog(@"File deleted: %@", file);
                } else {
                    NSLog(@"Failed to delete file: %@", error.localizedDescription);
                }
            }];
            [alert addAction:fileAction];
        }
        [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
        
        for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
            if ([scene isKindOfClass:[UIWindowScene class]]) {
                UIWindowScene *windowScene = (UIWindowScene *)scene;
                UIWindow *window = windowScene.windows.firstObject;
                UIViewController *rootViewController = window.rootViewController;
                if (rootViewController) {
                    [rootViewController presentViewController:alert animated:YES completion:nil];
                }
                break;
            }
        }
    } else {
        NSLog(@"No files found in the sheet directory.");
    }
}

+ (void)startStopButtonPressed:(UIButton *)button {
    if (isPlaying) {
        [self stopPlayback];
    } else {
        [self startTimedEvents];
    }
}

+ (void)stopPlayback {
    [timer invalidate];
    timer = nil;
    isPlaying = NO;
    currentIndex = 0;
    songNotesArray = nil;
    NSLog(@"Playback stopped");
    [synthesizer stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
    for (NSTimer *t in keyPressTimers) {
        [t invalidate];
    }
    [keyPressTimers removeAllObjects];
    
    // Optionally, unhighlight all keys after stopping playback
    for (UIView *keyView in keyViews.allValues) {
        [self unhighlightKey:keyView];
    }
}

+ (void)simulateKeypress:(NSString *)key {
    UIView *keyView = keyViews[key];
    [self highlightKey:keyView];
    [self unhighlightKey:keyView];
}

+ (void)highlightKey:(UIView *)keyView {
    keyView.backgroundColor = [UIColor yellowColor];
}

+ (void)unhighlightKey:(UIView *)keyView {
    keyView.backgroundColor = [UIColor lightGrayColor];
}

+ (void)startTimedEvents {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *filePath = [sheetDirectory stringByAppendingPathComponent:mainFile];
    
    if (![fileManager fileExistsAtPath:filePath]) {
        NSLog(@"No file found");
        return;
    }
    
    NSError *error;
    NSData *data = [NSData dataWithContentsOfFile:filePath options:0 error:&error];
    
    if (error) {
        NSLog(@"Error reading file: %@", error.localizedDescription);
        return;
    }
    
    NSError *jsonError;
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
    if (jsonError) {
        NSLog(@"JSON parsing error: %@", jsonError.localizedDescription);
        return;
    }
    
    songNotesArray = jsonDict[@"songNotes"];
    if (!songNotesArray) {
        NSLog(@"Error: 'songNotes' array not found in JSON.");
        return;
    }

    // Sort the song notes by time
    songNotesArray = [songNotesArray sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        NSNumber *time1 = obj1[@"time"];
        NSNumber *time2 = obj2[@"time"];
        return [time1 compare:time2];
    }];
    
    [self processTimedEvents];
}

+ (void)processTimedEvents {
    startTime = CACurrentMediaTime();
    
    for (NSDictionary *note in songNotesArray) {
        double time = [note[@"time"] doubleValue];
        NSString *key = note[@"key"];
        
        // Delay the key press based on the time value
        double delayTime = time - startTime;
        if (delayTime > 0) {
            [NSTimer scheduledTimerWithTimeInterval:delayTime target:self selector:@selector(simulateKeypress:) userInfo:key repeats:NO];
        }
    }
}

+ (void)handlePan:(UIPanGestureRecognizer *)gesture {
    // Handle pan gesture for key movement if needed
}

+ (void)handlePinch:(UIPinchGestureRecognizer *)gesture {
    // Handle pinch gesture for resizing if needed
}

@end
