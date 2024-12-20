#include <stdio.h>
#include <objc/runtime.h>
#include <objc/message.h>
#include <string.h>

// Define the fake response (your JSON data)
const char *fakeResponse = "{\"device_name\":\"iPhone\",\"software_version\":\"16.6.1\",\"ip_address\":\"171.242.185.166\",\"gps_location\":\"14.378906,108.970430\",\"remaining_hours\":6969,\"expire_full_date\":\"Sunday, 22/12/3000 00:31:00\",\"debname\":\"Mrken001\",\"debcontact\":\"https://cylight.click/create-package.php\",\"status\":\"success\",\"messenger\":\"Bypass EZ!!!!!\",\"key\":\"A0V-C2GM4W15IHR0UNOZ\",\"amount\":\"A0V-C2GM4W15IHR0UNOZ Hạn sử dụng đến: Dùng tới chết luôn:)\",\"udid\":\"c3bf1801fb354d42be16d1abb5c932f7\",\"device_model\":\"iPhone11,2 - iPhone XS\",\"os_version\":\"16.6.1\",\"login_text\":\"Login\",\"contact_text\":\"Liên Hệ\"}";

// Hook method to intercept requests
void hookNSURLSessionSendRequest() {
    // Get the original method (NSURLSession's dataTaskWithRequest)
    Method originalMethod = class_getInstanceMethod(objc_getClass("NSURLSession"), @selector(dataTaskWithRequest:completionHandler:));

    // Define the custom method to intercept the request
    void (*originalImp)(id, SEL, NSURLRequest *, void (^)(NSData *, NSURLResponse *, NSError *)) = (void (*)(id, SEL, NSURLRequest *, void (^)(NSData *, NSURLResponse *, NSError *)))method_getImplementation(originalMethod);

    // Custom implementation that fakes the response
    void customImp(id self, SEL _cmd, NSURLRequest *request, void (^completionHandler)(NSData *, NSURLResponse *, NSError *)) {
        // Check if the URL matches the target URL (you can refine this check further)
        if ([request.URL.absoluteString containsString:@"https://cylight.click/checklogin.php"]) {
            // Return the fake response immediately
            NSData *fakeResponseData = [NSData dataWithBytes:fakeResponse length:strlen(fakeResponse)];

            // Call the completion handler with the fake response
            completionHandler(fakeResponseData, nil, nil);
            return;
        }

        // If not the target URL, call the original method
        originalImp(self, _cmd, request, completionHandler);
    }

    // Swizzle the method to use our custom implementation
    method_setImplementation(originalMethod, (IMP)customImp);
}

// This will be executed when the dylib is injected into the process
__attribute__((constructor)) void inject() {
    hookNSURLSessionSendRequest();
}
