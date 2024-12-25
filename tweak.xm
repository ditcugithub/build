#include <objc/runtime.h>
#include <objc/message.h>
#import <UIKit/UIKit.h>

void (*original_showMenu)(id, SEL); // Function pointer for the original method

void custom_showMenu(id self, SEL _cmd) {
    // Prevent the menu from showing
    NSLog(@"Menu show blocked!");
    return;
}

__attribute__((constructor))
static void initialize() {
    Class menuClass = objc_getClass("UIMenuController"); // Replace with the relevant class for your target
    SEL selector = @selector(setMenuVisible:animated:);  // Replace with the target method's selector
    Method originalMethod = class_getInstanceMethod(menuClass, selector);

    if (originalMethod) {
        original_showMenu = (void (*)(id, SEL))method_getImplementation(originalMethod); // Cast properly
        method_setImplementation(originalMethod, (IMP)custom_showMenu);
    } else {
        NSLog(@"Failed to find method to hook.");
    }
}
