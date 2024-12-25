#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

%hook ViewController
// Replace 'ViewController' with the class responsible for the popup

- (void)showPopup {
    // Prevent the popup from showing by overriding the method
    NSLog(@"Popup blocked!");
    return;
}
%end
