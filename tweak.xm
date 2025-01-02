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

        // Check if the app supports scenes (iOS 13.0+)
        if (@available(iOS 13.0, *)) {
            // Access the first connected window scene (ensures compatibility with multiple scenes)
            UIWindowScene *windowScene = [UIApplication.sharedApplication.connectedScenes allObjects].firstObject;
            window = windowScene.windows.firstObject;  // Access the first window in the scene
        } else {
            // Fallback for older iOS versions (pre-iOS 13.0)
            window = UIApplication.sharedApplication.keyWindow;  // Deprecated in iOS 13.0+, but still works in older versions
        }

        if (window) {
            // Calculate number of rows and columns (3 rows, 5 columns)
            int numRows = 3;
            int numColumns = 5;

            // Size of each label
            CGFloat labelWidth = 50;
            CGFloat labelHeight = 50;

            // Calculate the starting point to center the numbers
            CGFloat screenWidth = window.bounds.size.width;
            CGFloat screenHeight = window.bounds.size.height;

            CGFloat totalWidth = labelWidth * numColumns + 10 * (numColumns - 1); // space between labels
            CGFloat totalHeight = labelHeight * numRows + 10 * (numRows - 1); // space between labels

            CGFloat startX = (screenWidth - totalWidth) / 2;
            CGFloat startY = (screenHeight - totalHeight) / 2;

            // Create a label for each number (0 to 14)
            for (int i = 0; i < 15; i++) {
                int row = i / numColumns;
                int col = i % numColumns;

                // Position each label dynamically
                UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(startX + (labelWidth + 10) * col, startY + (labelHeight + 10) * row, labelWidth, labelHeight)];
                label.text = [NSString stringWithFormat:@"Key%d", i];  // Display Key0-Key14
                label.font = [UIFont systemFontOfSize:14];
                label.textAlignment = NSTextAlignmentCenter;
                label.textColor = [UIColor blackColor];
                label.backgroundColor = [UIColor lightGrayColor];
                label.layer.cornerRadius = 15;
                label.layer.masksToBounds = YES;

                // Add the label to the window
                [window addSubview:label];

                // Enable user interaction on the label
                label.userInteractionEnabled = YES;

                // Add a pan gesture recognizer to move the label
                UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:[Tweak class] action:@selector(handlePan:)];
                [label addGestureRecognizer:panGesture];

                // Add a pinch gesture recognizer to zoom the label
                UIPinchGestureRecognizer *pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:[Tweak class] action:@selector(handlePinch:)];
                [label addGestureRecognizer:pinchGesture];

                // Add the "Upload" button next to the number label
                UIButton *uploadButton = [UIButton buttonWithType:UIButtonTypeSystem];
                uploadButton.frame = CGRectMake(label.frame.origin.x - 60, label.frame.origin.y, 50, labelHeight);  // Positioned to the left of the number
                [uploadButton setTitle:@"Upload" forState:UIControlStateNormal];
                uploadButton.titleLabel.font = [UIFont systemFontOfSize:12];
                [uploadButton addTarget:[Tweak class] action:@selector(uploadButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
                [window addSubview:uploadButton];
            }

            // Add the "Start/Stop" button
            UIButton *startStopButton = [UIButton buttonWithType:UIButtonTypeSystem];
            startStopButton.frame = CGRectMake(screenWidth - 80, screenHeight / 2 - 25, 60, 50);  // Positioned on the right side
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

    // Move the label as the user drags it
    label.center = CGPointMake(label.center.x + translation.x, label.center.y + translation.y);
    [gesture setTranslation:CGPointZero inView:label.superview];
}

+ (void)handlePinch:(UIPinchGestureRecognizer *)gesture {
    UIView *label = gesture.view;

    // Adjust the label's transform to scale it
    CGAffineTransform currentTransform = label.transform;
    CGAffineTransform newTransform = CGAffineTransformScale(currentTransform, gesture.scale, gesture.scale);
    label.transform = newTransform;

    // Reset the scale for the next pinch event
    gesture.scale = 1.0;
}

// Implementing the missing startTimedEvents: method
+ (void)startTimedEvents:(NSArray *)songNotes {
    // Store the song notes for playback
    songNotesArray = songNotes;
}

// Action for Start/Stop button
+ (void)startStopButtonPressed:(UIButton *)button {
    if (isPlaying) {
        // Stop the playback and reset
        [timer invalidate];  // Stop the timer
        timer = nil;  // Reset the timer
        currentIndex = 0;  // Reset the current index to start from the beginning
        isPlaying = NO;
        [button setTitle:@"Start" forState:UIControlStateNormal];  // Change button text to "Start"
    } else {
        // Start playing the events from the beginning
        isPlaying = YES;
        [button setTitle:@"Stop" forState:UIControlStateNormal];  // Change button text to "Stop"

        // Start a timer to simulate playing the events based on time and key
        timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:[Tweak class] selector:@selector(playEvents) userInfo:nil repeats:YES];
    }
}

// Simulate playing the events based on the song notes
+ (void)playEvents {
    if (currentIndex < songNotesArray.count) {
        NSDictionary *note = songNotesArray[currentIndex];
        NSNumber *time = note[@"time"];
        NSString *key = note[@"key"];
        
        // Check if the time has passed, then simulate a key press (e.g., by triggering an action)
        if (CACurrentMediaTime() * 1000 >= time.doubleValue) {
            NSLog(@"At time: %@, key: %@", time, key);
            // Trigger key press event here, e.g., visually pressing a key or playing a sound
            
            currentIndex++;
        }
    } else {
        // If we reach the end of the song notes, stop the playback
        [timer invalidate];
        timer = nil;
        isPlaying = NO;
        UIButton *startStopButton = [UIApplication.sharedApplication.windows.firstObject viewWithTag:100];  // Retrieve the Start/Stop button
        [startStopButton setTitle:@"Start" forState:UIControlStateNormal];  // Change button text back to "Start"
    }
}

// Action for Upload button
+ (void)uploadButtonPressed:(UIButton *)button {
    NSLog(@"Upload button pressed for: %@", button.titleLabel.text);
    // Handle the upload action (e.g., prompt the user to upload a file)
}

@end
