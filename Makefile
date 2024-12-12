ARCHS = arm64 # Specify all supported architectures
TARGET = iphone:latest  # Set target device version
# THEOS_DEVICE_IP = 192.168.1.10  # Optional, for remote building to a device
LIBRARY_NAME = ChillySillyKeySystem  # The name of your dylib

# Frameworks you want to link
LIBRARY_FRAMEWORKS = UIKit Foundation

# Include the common.mk file from Theos
include $(THEOS)/makefiles/common.mk

# Specify the source files
# $(LIBRARY_NAME)_FILES = tweak.xm  # Your source file (change to the correct name if needed)
ChillySillyKeySystem_FILES = tweak.xm
# Specify the compiler flags
$(LIBRARY_NAME)_CFLAGS = -fobjc-arc  # Enable ARC (Automatic Reference Counting)

# Include the final rule to build the dylib
include $(THEOS)/makefiles/library.mk
