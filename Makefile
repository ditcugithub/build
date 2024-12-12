# Compiler and flags
CC = clang
CFLAGS = -fPIC -Wall -I/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk/usr/include
LDFLAGS = -shared -undefined dynamic_lookup -lobjc

# Source and output
SRC = inject.c
OBJ = $(SRC:.c=.o)
OUTPUT = libinject.dylib

# Build rule
all: $(OUTPUT)

$(OUTPUT): $(OBJ)
	$(CC) $(OBJ) -o $(OUTPUT) $(LDFLAGS)

# Compile the .c file to an object file
%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

# Clean build files
clean:
	rm -f $(OBJ) $(OUTPUT)
