ARCHS = arm64  # Target architecture (for iPhone)
TARGET = iphone:latest  # Target iOS version (adjust as needed)

# Define the name of the library
LIBRARY_NAME = ChillySillyKeySystem

# Frameworks to link (UIKit, Foundation are common for iOS apps)
LIBRARY_FRAMEWORKS = UIKit Foundation

# Specify paths for libcurl (make sure these paths are correct for your system)
CURL_INCLUDE = /usr/include/curl  # Location of curl headers
CURL_LIB = /usr/lib  # Location of curl libraries

# Add libcurl to the LDFLAGS and CFLAGS to ensure it's linked correctly
LDFLAGS += -L$(CURL_LIB)  # Link the curl library
CFLAGS += -I$(CURL_INCLUDE)  # Include curl headers

# Specify the source files for your dylib
ChillySillyKeySystem_FILES = tweak.xm  # Replace with the actual name of your source file

# Include the common.mk from Theos, which includes the basic build environment
include $(THEOS)/makefiles/common.mk

# Include the final rule for building the dylib
include $(THEOS)/makefiles/library.mk
