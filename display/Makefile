CC := /usr/bin/clang
CFLAGS := -O2 -std=c11 -Wall -Wextra -Wconversion -Werror
OBJCFLAGS := -O2 -Wall -Wextra -Wconversion -Werror -fno-objc-arc
FRAMEWORKS := -framework ApplicationServices -framework CoreFoundation -framework Foundation

.PHONY: all clean

all: display

display: display.o brightness.o rotation.o
	$(CC) $^ -o $@ $(FRAMEWORKS)

display.o: display.c brightness.h rotation.h
	$(CC) $(CFLAGS) -c $< -o $@

brightness.o: brightness.c brightness.h
	$(CC) $(CFLAGS) -c $< -o $@

rotation.o: rotation.m rotation.h
	$(CC) $(OBJCFLAGS) -c $< -o $@

clean:
	rm -f display display.o brightness.o rotation.o
