#import <UIKit/UIKit.h>

@interface Tweak : NSObject
+ (void)handlePan:(UIPanGestureRecognizer *)gesture;
+ (void)handlePinch:(UIPinchGestureRecognizer *)gesture;
+ (void)startTimedEvents:(NSArray *)songNotes;
+ (void)startStopButtonPressed:(UIButton *)button;
+ (void)uploadButtonPressed:(UIButton *)button;
@end

@implementation Tweak

static BOOL isPlaying = NO;  // Track whether events are playing
static NSTimer *timer = nil;  // Timer for event playback
static NSArray *songNotesArray = nil;  // Store the song notes for playback
static NSInteger currentIndex = 0;  // Index to track the current event

__attribute__((constructor))
static void initialize() {
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
                window = windowScene.windows.firstObject;  // Access the first window in the scene
            }
        } else {
            // Fallback for older iOS versions
            window = UIApplication.sharedApplication.delegate.window; // Use delegate's window for backward compatibility
        }

        if (window) {
            int numRows = 3;
            int numColumns = 5;
            CGFloat labelWidth = 50;
            CGFloat labelHeight = 50;
            CGFloat screenWidth = window.bounds.size.width;
            CGFloat screenHeight = window.bounds.size.height;

            CGFloat totalWidth = labelWidth * numColumns + 10 * (numColumns - 1);
            CGFloat totalHeight = labelHeight * numRows + 10 * (numRows - 1);
            CGFloat startX = (screenWidth - totalWidth) / 2;
            CGFloat startY = (screenHeight - totalHeight) / 2;

            for (int i = 0; i < 15; i++) {
                int row = i / numColumns;
                int col = i % numColumns;

                UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(startX + (labelWidth + 10) * col, startY + (labelHeight + 10) * row, labelWidth, labelHeight)];
                label.text = [NSString stringWithFormat:@"Key%d", i];
                label.font = [UIFont systemFontOfSize:14];
                label.textAlignment = NSTextAlignmentCenter;
                label.textColor = [UIColor blackColor];
                label.backgroundColor = [UIColor lightGrayColor];
                label.layer.cornerRadius = 15;
                label.layer.masksToBounds = YES;

                [window addSubview:label];
                label.userInteractionEnabled = YES;

                UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:[Tweak class] action:@selector(handlePan:)];
                [label addGestureRecognizer:panGesture];

                UIPinchGestureRecognizer *pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:[Tweak class] action:@selector(handlePinch:)];
                [label addGestureRecognizer:pinchGesture];

                UIButton *uploadButton = [UIButton buttonWithType:UIButtonTypeSystem];
                uploadButton.frame = CGRectMake(label.frame.origin.x - 60, label.frame.origin.y, 50, labelHeight);
                [uploadButton setTitle:@"Upload" forState:UIControlStateNormal];
                uploadButton.titleLabel.font = [UIFont systemFontOfSize:12];
                [uploadButton addTarget:[Tweak class] action:@selector(uploadButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
                [window addSubview:uploadButton];
            }

            UIButton *startStopButton = [UIButton buttonWithType:UIButtonTypeSystem];
            startStopButton.frame = CGRectMake(screenWidth - 80, screenHeight / 2 - 25, 60, 50);
            [startStopButton setTitle:@"Start" forState:UIControlStateNormal];
            startStopButton.titleLabel.font = [UIFont systemFontOfSize:14];
            [startStopButton addTarget:[Tweak class] action:@selector(startStopButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
            startStopButton.layer.cornerRadius = 25;
            startStopButton.layer.masksToBounds = YES;
            startStopButton.backgroundColor = [UIColor lightGrayColor];
            [window addSubview:startStopButton];
        }
    });
}

+ (void)handlePan:(UIPanGestureRecognizer *)gesture {
    UIView *label = gesture.view;
    CGPoint translation = [gesture translationInView:label.superview];

    label.center = CGPointMake(label.center.x + translation.x, label.center.y + translation.y);
    [gesture setTranslation:CGPointZero inView:label.superview];
}

+ (void)handlePinch:(UIPinchGestureRecognizer *)gesture {
    UIView *label = gesture.view;
    CGAffineTransform currentTransform = label.transform;
    CGAffineTransform newTransform = CGAffineTransformScale(currentTransform, gesture.scale, gesture.scale);
    label.transform = newTransform;
    gesture.scale = 1.0;
}

+ (void)startTimedEvents:(NSArray *)songNotes {
    songNotesArray = songNotes;
}

+ (void)startStopButtonPressed:(UIButton *)button {
    if (isPlaying) {
        [timer invalidate];
        timer = nil;
        currentIndex = 0;
        isPlaying = NO;
        [button setTitle:@"Start" forState:UIControlStateNormal];
    } else {
        isPlaying = YES;
        [button setTitle:@"Stop" forState:UIControlStateNormal];
        timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:[Tweak class] selector:@selector(playEvents) userInfo:nil repeats:YES];
    }
}

+ (void)playEvents {
    if (currentIndex < songNotesArray.count) {
        NSDictionary *note = songNotesArray[currentIndex];
        NSNumber *time = note[@"time"];
        NSString *key = note[@"key"];
        
        if (CACurrentMediaTime() * 1000 >= time.doubleValue) {
            NSLog(@"At time: %@, key: %@", time, key);
            currentIndex++;
        }
    } else {
        [timer invalidate];
        timer = nil;
        isPlaying = NO;
        
        UIWindow *window = nil;
        if (@available(iOS 15.0, *)) {
            UIWindowScene *windowScene = nil;
            for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
                if ([scene isKindOfClass:[UIWindowScene class]]) {
                    windowScene = (UIWindowScene *)scene;
                    break;
                }
            }
            if (windowScene) {
                window = windowScene.windows.firstObject;
            }
        } else {
            window = UIApplication.sharedApplication.delegate.window;
        }
        
        UIButton *startStopButton = nil;
        for (UIView *subview in window.subviews) {
            if ([subview isKindOfClass:[UIButton class]] && [((UIButton *)subview).currentTitle isEqualToString:@"Stop"]) {
                startStopButton = (UIButton *)subview;
                break;
            }
        }
        
        if (startStopButton) {
            [startStopButton setTitle:@"Start" forState:UIControlStateNormal];
        }
    }
}

+ (void)uploadButtonPressed:(UIButton *)button {
    NSLog(@"Upload button pressed for: %@", button.titleLabel.text);
}

@end
