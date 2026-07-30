#ifndef DISPLAY_BRIGHTNESS_H
#define DISPLAY_BRIGHTNESS_H

#include <ApplicationServices/ApplicationServices.h>
#include <stdbool.h>

bool brightness_get(CGDirectDisplayID display_id, float *value);
bool brightness_set(CGDirectDisplayID display_id, float value);

#endif
