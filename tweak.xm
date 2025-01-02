#include <objc/runtime.h>
#import <UIKit/UIKit.h>

@interface Tweak : NSObject
+ (void)handlePan:(UIPanGestureRecognizer *)gesture;
+ (void)handlePinch:(UIPinchGestureRecognizer *)gesture;
@end

@implementation Tweak

__attribute__((constructor))
static void initialize() {
    dispatch_async(dispatch_get_main_queue(), ^{
        // Create a view to hold the numbers
        UIWindow *window = nil;
        for (UIWindow *win in [UIApplication sharedApplication].windows) {
            if (win.isKeyWindow) {
                window = win;
                break;
            }
        }
        
        // Create a label for each number (1 to 15)
        for (int i = 1; i <= 15; i++) {
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(50 * (i % 5), 50 * (i / 5), 30, 30)];
            label.text = [NSString stringWithFormat:@"%d", i];
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

@end
