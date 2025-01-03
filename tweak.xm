#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface Tweak : NSObject
+ (void)handlePan:(UIPanGestureRecognizer *)gesture;
+ (void)handlePinch:(UIPinchGestureRecognizer *)gesture;
+ (void)startTimedEvents:(NSArray *)songNotes;
+ (void)uploadButtonPressed:(UIButton *)button;
+ (void)loadButtonPressed:(UIButton *)button;
+ (void)deleteButtonPressed:(UIButton *)button;
+ (void)startStopButtonPressed:(UIButton *)button;
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

__attribute__((constructor))
static void initialize() {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    sheetDirectory = [paths.firstObject stringByAppendingPathComponent:@"sheet"];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:sheetDirectory]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:sheetDirectory withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    keyViews = [NSMutableDictionary dictionary];
    synthesizer = [[AVSpeechSynthesizer alloc] init];

    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindowScene *scene = UIApplication.sharedApplication.connectedScenes.allObjects.firstObject;
        UIWindow *window = scene.delegate.window;

        if (window) {
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
            
            UIWindowScene *scene = UIApplication.sharedApplication.connectedScenes.allObjects.firstObject;
            UIWindow *window = scene.delegate.window;
            UIViewController *rootViewController = window.rootViewController;
            if (rootViewController) {
                [rootViewController presentViewController:fileNameAlert animated:YES completion:nil];
            }
            
        } else {
            NSLog(@"Invalid URL");
        }
    }];
    
    [alert addAction:submitAction];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    
    UIWindowScene *scene = UIApplication.sharedApplication.connectedScenes.allObjects.firstObject;
    UIWindow *window = scene.delegate.window;
    UIViewController *rootViewController = window.rootViewController;
    if (rootViewController) {
        [rootViewController presentViewController:alert animated:YES completion:nil];
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
        
        UIWindowScene *scene = UIApplication.sharedApplication.connectedScenes.allObjects.firstObject;
        UIWindow *window = scene.delegate.window;
        UIViewController *rootViewController = window.rootViewController;
        if (rootViewController) {
            [rootViewController presentViewController:alert animated:YES completion:nil];
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
        
        UIWindowScene *scene = UIApplication.sharedApplication.connectedScenes.allObjects.firstObject;
        UIWindow *window = scene.delegate.window;
        UIViewController *rootViewController = window.rootViewController;
        if (rootViewController) {
            [rootViewController presentViewController:alert animated:YES completion:nil];
        }
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
    currentIndex = 0;
    isPlaying = YES;
    
    timer = [NSTimer scheduledTimerWithTimeInterval:0.001
                                             target:[Tweak class]
                                           selector:@selector(playEvents)
                                           userInfo:nil
                                            repeats:YES];
}

+ (void)playEvents {
    if (currentIndex < songNotesArray.count && isPlaying) {
        NSDictionary *note = songNotesArray[currentIndex];
        NSNumber *time = note[@"time"];
        NSString *key = note[@"key"];

        if (CACurrentMediaTime() * 1000 >= time.doubleValue) {
            [self simulateClickForKey:key];
            currentIndex++;
            
            AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:key];
            [synthesizer speakUtterance:utterance];
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
    if (keyView && keyView.window) {
        [keyView accessibilityActivate];
    } else {
        NSLog(@"No view found for key: %@", key);
    }
}

+ (void)handlePan:(UIPanGestureRecognizer *)gesture {
    UIView *movableView = gesture.view;
    CGPoint translation = [gesture translationInView:movableView.superview];
    movableView.center = CGPointMake(movableView.center.x + translation.x, movableView.center.y + translation.y);
    [gesture setTranslation:CGPointZero inView:movableView.superview];
}

+ (void)handlePinch:(UIPinchGestureRecognizer *)gesture {
    // Implement pinch gesture handling here
}

+ (void)startStopButtonPressed:(UIButton *)button {
    if (isPlaying) {
        [timer invalidate];
        timer = nil;
        isPlaying = NO;
        [button setTitle:@"Start" forState:UIControlStateNormal];
        [synthesizer stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
    } else {
        if (mainFile) {
            [self loadFile:mainFile];
            [button setTitle:@"Stop" forState:UIControlStateNormal];
        } else {
            NSLog(@"Please load a main file first.");
        }
    }
}

@end
