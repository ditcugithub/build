#include <objc/runtime.h>
#include <objc/message.h>
#import <UIKit/UIKit.h>

void (*original_showMenu)(id, SEL);

void custom_showMenu(id self, SEL _cmd) {
    // Prevent the menu from showing
    NSLog(@"Menu show blocked!");
    return;
}

__attribute__((constructor))
static void initialize() {
    Class menuClass = objc_getClass("NSMenu");
    SEL selector = @selector(popUpMenuPositioningItem:atLocation:inView:);
    Method originalMethod = class_getInstanceMethod(menuClass, selector);
    original_showMenu = (void *)method_getImplementation(originalMethod);
    method_setImplementation(originalMethod, (IMP)custom_showMenu);
}
