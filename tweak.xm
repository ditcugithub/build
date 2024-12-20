#import <Foundation/Foundation.h>  // Ensure Foundation is imported for NSURLRequest and other types

#include <objc/runtime.h>
#include <objc/message.h>
#include <string.h>

// Define the fake response (your new JSON data)
const char *fakeResponse = "{\"device_name\":\"iPhone\",\"software_version\":\"16.6.1\",\"ip_address\":\"171.242.185.166\",\"gps_location\":\"14.378906,108.970430\",\"remaining_hours\":1000,\"expire_full_date\":\"Hai Dep Trai\",\"debname\":\"Mrken001\",\"debcontact\":\"https://cylight.click/create-package.php\",\"status\":\"success\",\"messenger\":\"EZ Bypass Key Server!.\",\"key\":\"A0V-C2GM4W15IHR0UNOZ\",\"amount\":\"A0V-C2GM4W15IHR0UNOZ Hạn sử dụng đến: Hai Dep Trai\",\"udid\":\"c3bf1801fb354d42be16d1abb5c932f7\",\"device_model\":\"iPhone11,2 - iPhone XS\",\"os_version\":\"16.6.1\",\"login_text\":\"Login\",\"contact_text\":\"Liên Hệ\"}";

// Declare the custom implementation function
void customImp(id self, SEL _cmd, NSURLRequest *request, void (^completionHandler)(NSData *, NSURLResponse *, NSError *)) {
    // Check if the URL matches the target URL pattern (checklogin?data=...)
    if ([request.URL.absoluteString containsString:@"checklogin?data="]) {
        // Return the fake response immediately
        NSData *fakeResponseData = [NSData dataWithBytes:fakeResponse length:strlen(fakeResponse)];

        // Call the completion handler with the fake response
        completionHandler(fakeResponseData, nil, nil);
        return;
    }

    // If not the target URL, call the original method (this will be set dynamically in hookNSURLSessionSendRequest)
    void (*originalImp)(id, SEL, NSURLRequest *, void (^)(NSData *, NSURLResponse *, NSError *));
    originalImp = (void (*)(id, SEL, NSURLRequest *, void (^)(NSData *, NSURLResponse *, NSError *)))objc_getAssociatedObject(self, "originalImp");
    originalImp(self, _cmd, request, completionHandler);
}

// Hook method to intercept requests
void hookNSURLSessionSendRequest() {
    // Get the original method (NSURLSession's dataTaskWithRequest)
    Method originalMethod = class_getInstanceMethod(objc_getClass("NSURLSession"), @selector(dataTaskWithRequest:completionHandler:));

    // Save the original implementation for later use
    void (*originalImp)(id, SEL, NSURLRequest *, void (^)(NSData *, NSURLResponse *, NSError *));
    originalImp = (void (*)(id, SEL, NSURLRequest *, void (^)(NSData *, NSURLResponse *, NSError *)))method_getImplementation(originalMethod);

    // Associate the original implementation with the class so it can be used in customImp
    objc_setAssociatedObject(objc_getClass("NSURLSession"), "originalImp", originalImp, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    // Swizzle the method to use our custom implementation
    method_setImplementation(originalMethod, (IMP)customImp);
}

// This will be executed when the dylib is injected into the process
__attribute__((constructor)) void inject() {
    hookNSURLSessionSendRequest();
}
