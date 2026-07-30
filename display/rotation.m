#import <ApplicationServices/ApplicationServices.h>
#import <Foundation/Foundation.h>

#include <dlfcn.h>
#include <stdbool.h>
#include <stdio.h>

#include "rotation.h"

@interface MPDisplay : NSObject
- (instancetype)initWithCGSDisplayID:(int)display_id;
- (BOOL)canChangeOrientation;
- (void)setOrientation:(int)degrees;
@end

static void write_error(char *error, size_t error_size, const char *message) {
  if (error != NULL && error_size > 0) {
    snprintf(error, error_size, "%s", message);
  }
}

bool set_display_orientation(CGDirectDisplayID display_id, int degrees,
                             char *error, size_t error_size) {
  @autoreleasepool {
    static const char *framework =
        "/System/Library/PrivateFrameworks/MonitorPanel.framework/"
        "MonitorPanel";
    static void *monitor_panel = NULL;

    if (monitor_panel == NULL) {
      monitor_panel = dlopen(framework, RTLD_LAZY | RTLD_LOCAL);
    }
    if (monitor_panel == NULL) {
      write_error(error, error_size, dlerror());
      return false;
    }

    Class display_class = NSClassFromString(@"MPDisplay");
    if (display_class == Nil) {
      write_error(error, error_size,
                  "MonitorPanel does not provide the MPDisplay class");
      return false;
    }

    MPDisplay *display =
        [(MPDisplay *)[display_class alloc] initWithCGSDisplayID:(int)display_id];
    if (display == nil) {
      write_error(error, error_size,
                  "MonitorPanel could not open the requested display");
      return false;
    }

    if ([display respondsToSelector:@selector(canChangeOrientation)] &&
        ![display canChangeOrientation]) {
      [display release];
      write_error(error, error_size,
                  "macOS reports that this display cannot be rotated");
      return false;
    }

    [display setOrientation:degrees];
    [display release];

    // MonitorPanel applies this asynchronously. CoreGraphics can retain the
    // pre-change topology in this process, so polling CGDisplayRotation here
    // produces false timeouts after enabling or disabling a display.
    return true;
  }
}
