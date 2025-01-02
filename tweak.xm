#include <objc/runtime.h>
#import <UIKit/UIKit.h>

@interface Tweak : NSObject
+ (void)handlePan:(UIPanGestureRecognizer *)gesture;
+ (void)handlePinch:(UIPinchGestureRecognizer *)gesture;
+ (void)createNumberLabelsAndButtons;
+ (void)uploadFileFromURL:(NSString *)urlString;
+ (void)startTimedEvents:(NSArray *)songNotes;
+ (void)showMessage:(NSString *)message;
@end

@implementation Tweak

static NSMutableArray *labels;
static NSMutableArray *buttons;

__attribute__((constructor))
static void initialize() {
    labels = [NSMutableArray array];
    buttons = [NSMutableArray array];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        // Create number labels and upload buttons on the screen
        [Tweak createNumberLabelsAndButtons];
    });
}

+ (void)createNumberLabelsAndButtons {
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    if (!window) return;
    
    int numRows = 3;
    int numColumns = 5;
    CGFloat labelWidth = 50;
    CGFloat labelHeight = 50;
    CGFloat buttonWidth = 70;
    CGFloat buttonHeight = 50;
    
    CGFloat screenWidth = window.bounds.size.width;
    CGFloat screenHeight = window.bounds.size.height;
    
    CGFloat totalWidth = labelWidth * numColumns + 10 * (numColumns - 1);
    CGFloat totalHeight = labelHeight * numRows + 10 * (numRows - 1);
    
    CGFloat startX = (screenWidth - totalWidth) / 2;
    CGFloat startY = (screenHeight - totalHeight) / 2;
    
    // Create a label and button for each key (Key0 to Key14)
    for (int i = 0; i < 15; i++) {
        int row = i / numColumns;
        int col = i % numColumns;
        
        // Create number label
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(startX + (labelWidth + 10) * col, startY + (labelHeight + 10) * row, labelWidth, labelHeight)];
        label.text = [NSString stringWithFormat:@"Key%d", i]; // Key0 to Key14
        label.font = [UIFont systemFontOfSize:14];
        label.textAlignment = NSTextAlignmentCenter;
        label.textColor = [UIColor blackColor];
        label.backgroundColor = [UIColor lightGrayColor];
        label.layer.cornerRadius = 15;
        label.layer.masksToBounds = YES;
        
        // Add the label to the window
        [window addSubview:label];
        
        // Enable user interaction
        label.userInteractionEnabled = YES;
        
        // Add pan and pinch gestures to move and resize the labels
        UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:[Tweak class] action:@selector(handlePan:)];
        [label addGestureRecognizer:panGesture];
        
        UIPinchGestureRecognizer *pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:[Tweak class] action:@selector(handlePinch:)];
        [label addGestureRecognizer:pinchGesture];
        
        // Add the label to the list of labels
        [labels addObject:label];
        
        // Create an upload button next to the label
        UIButton *uploadButton = [[UIButton alloc] initWithFrame:CGRectMake(startX + (labelWidth + 10) * col - buttonWidth - 5, startY + (labelHeight + 10) * row, buttonWidth, buttonHeight)];
        [uploadButton setTitle:@"Upload" forState:UIControlStateNormal];
        [uploadButton setBackgroundColor:[UIColor blueColor]];
        uploadButton.layer.cornerRadius = 15;
        uploadButton.layer.masksToBounds = YES;
        [uploadButton addTarget:[Tweak class] action:@selector(uploadFileFromURL:) forControlEvents:UIControlEventTouchUpInside];
        
        // Add the upload button to the window
        [window addSubview:uploadButton];
        
        // Enable user interaction for the button
        uploadButton.userInteractionEnabled = YES;
        
        // Add pan gesture for the upload button
        UIPanGestureRecognizer *buttonPanGesture = [[UIPanGestureRecognizer alloc] initWithTarget:[Tweak class] action:@selector(handlePan:)];
        [uploadButton addGestureRecognizer:buttonPanGesture];
        
        // Add the button to the list of buttons
        [buttons addObject:uploadButton];
    }
}

+ (void)uploadFileFromURL:(NSString *)urlString {
    // Create a UIAlertController to input URL
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Enter URL" message:@"Paste the URL to download the sheet file" preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"https://example.com/sheet.txt";
    }];
    
    UIAlertAction *uploadAction = [UIAlertAction actionWithTitle:@"Download and Upload" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        // Get the URL entered by the user
        NSString *urlString = alert.textFields.firstObject.text;
        if (urlString.length > 0) {
            [Tweak downloadFileFromURL:urlString];
        } else {
            [Tweak showMessage:@"URL is empty!"];
        }
    }];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    
    [alert addAction:uploadAction];
    [alert addAction:cancelAction];
    
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    [window.rootViewController presentViewController:alert animated:YES completion:nil];
}

+ (void)downloadFileFromURL:(NSString *)urlString {
    NSURL *url = [NSURL URLWithString:urlString];
    if (!url) {
        [Tweak showMessage:@"Invalid URL!"];
        return;
    }
    
    // Start downloading the file from the provided URL
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *downloadTask = [session dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            [Tweak showMessage:@"Failed to download file."];
            return;
        }
        
        if (data) {
            NSError *jsonError;
            NSArray *jsonArray = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
            if (jsonError) {
                [Tweak showMessage:@"Failed to parse JSON."];
                return;
            }
            
            [Tweak validateUploadedFile:jsonArray];
        }
    }];
    
    [downloadTask resume];
}

+ (void)validateUploadedFile:(NSArray *)fileData {
    // Validate the file structure and format
    if (![fileData isKindOfClass:[NSArray class]]) {
        [Tweak showMessage:@"File format is incorrect!"];
        return;
    }
    
    // Check if each element in the array contains necessary keys
    for (NSDictionary *item in fileData) {
        if (![item isKindOfClass:[NSDictionary class]] || !item[@"name"] || !item[@"bpm"] || !item[@"songNotes"]) {
            [Tweak showMessage:@"File format is incorrect!"];
            return;
        }
    }
    
    // If everything is fine
    [Tweak showMessage:@"File format is correct!"];
}

+ (void)showMessage:(NSString *)message {
    // Show a message to the user
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Upload Status" message:message preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
    [alert addAction:okAction];
    
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    [window.rootViewController presentViewController:alert animated:YES completion:nil];
}

+ (void)handlePan:(UIPanGestureRecognizer *)gesture {
    UIView *view = gesture.view;
    CGPoint translation = [gesture translationInView:view.superview];
    
    // Move the view (label or button) as the user drags it
    view.center = CGPointMake(view.center.x + translation.x, view.center.y + translation.y);
    [gesture setTranslation:CGPointZero inView:view.superview];
}

+ (void)handlePinch:(UIPinchGestureRecognizer *)gesture {
    UIView *view = gesture.view;
    
    // Adjust the view's transform to scale it
    CGAffineTransform currentTransform = view.transform;
    CGAffineTransform newTransform = CGAffineTransformScale(currentTransform, gesture.scale, gesture.scale);
    view.transform = newTransform;
    
    // Reset the scale for the next pinch event
    gesture.scale = 1.0;
}

@end
