#ifndef DISPLAY_ROTATION_H
#define DISPLAY_ROTATION_H

#include <ApplicationServices/ApplicationServices.h>
#include <stdbool.h>
#include <stddef.h>

bool set_display_orientation(CGDirectDisplayID display_id, int degrees,
                             char *error, size_t error_size);

#endif
