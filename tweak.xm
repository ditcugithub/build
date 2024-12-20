#import <Foundation/Foundation.h>
#include <objc/runtime.h>
#include <objc/message.h>
#include <string.h>

// Define the fake response (your custom JSON data)
const char *fakeResponse = "{\"device_name\":\"iPhone\",\"software_version\":\"16.6.1\",\"ip_address\":\"171.242.185.166\",\"gps_location\":\"14.378906,108.970430\",\"remaining_hours\":1000,\"expire_full_date\":\"Hai Dep Trai\",\"debname\":\"Mrken001\",\"debcontact\":\"https://cylight.click/create-package.php\",\"status\":\"success\",\"messenger\":\"EZ Bypass Key Server!.\",\"key\":\"A0V-C2GM4W15IHR0UNOZ\",\"amount\":\"A0V-C2GM4W15IHR0UNOZ Hạn sử dụng đến: Hai Dep Trai\",\"udid\":\"c3bf1801fb354d42be16d1abb5c932f7\",\"device_model\":\"iPhone11,2 - iPhone XS\",\"os_version\":\"16.6.1\",\"login_text\":\"Login\",\"contact_text\":\"Liên Hệ\"}";

// Declare the custom implementation function
void customImp(id self, SEL _cmd, NSURLRequest *request, void (^completionHandler)(NSData *, NSURLResponse *, NSError *)) {
    // Check if the URL matches the target condition
    if ([request.URL.absoluteString containsString:@"checklogin?data="]) {
        NSLog(@"Intercepted request: %@", request.URL.absoluteString);

        // Return a fake response
        NSData *fakeResponseData = [NSData dataWithBytes:fakeResponse length:strlen(fakeResponse)];
        completionHandler(fakeResponseData, nil, nil); // Call the completion handler with the fake response
        return;
    }

    // Call the original implementation for all other requests
    NSValue *originalImpValue = objc_getAssociatedObject(objc_getClass("NSURLSession"), "originalImp");
    void (*originalImp)(id, SEL, NSURLRequest *, void (^)(NSData *, NSURLResponse *, NSError *)) =
        (void (*)(id, SEL, NSURLRequest *, void (^)(NSData *, NSURLResponse *, NSError *)))[originalImpValue pointerValue];

    originalImp(self, _cmd, request, completionHandler); // Forward to original implementation
}

// Hook method to dynamically intercept requests
void hookNSURLSessionSendRequest() {
    Class NSURLSessionClass = objc_getClass("NSURLSession");

    // Get the original method (dataTaskWithRequest:completionHandler:)
    Method originalMethod = class_getInstanceMethod(NSURLSessionClass, @selector(dataTaskWithRequest:completionHandler:));

    // Save the original method's implementation
    void (*originalImp)(id, SEL, NSURLRequest *, void (^)(NSData *, NSURLResponse *, NSError *));
    originalImp = (void (*)(id, SEL, NSURLRequest *, void (^)(NSData *, NSURLResponse *, NSError *)))method_getImplementation(originalMethod);

    // Save it for later use
    NSValue *originalImpValue = [NSValue valueWithPointer:(void *)originalImp];
    objc_setAssociatedObject(NSURLSessionClass, "originalImp", originalImpValue, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    // Replace the method implementation with our custom implementation
    method_setImplementation(originalMethod, (IMP)customImp);
}

// Entry point: Activate the hook when the library is loaded
__attribute__((constructor)) void inject() {
    NSLog(@"Injecting custom NSURLSession hook...");
    hookNSURLSessionSendRequest();
}
