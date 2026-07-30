#include "brightness.h"

#include <dlfcn.h>
#include <math.h>
#include <stdbool.h>

typedef int (*GetBrightnessFn)(CGDirectDisplayID display_id, float *value);
typedef int (*SetBrightnessFn)(CGDirectDisplayID display_id, float value);

typedef struct {
  GetBrightnessFn get;
  SetBrightnessFn set;
} BrightnessAPI;

static const BrightnessAPI *brightness_api(void) {
  static const char *framework =
      "/System/Library/PrivateFrameworks/DisplayServices.framework/"
      "DisplayServices";
  static BrightnessAPI api = {0};
  static bool loaded = false;

  if (!loaded) {
    loaded = true;
    void *handle = dlopen(framework, RTLD_LAZY | RTLD_LOCAL);
    if (handle != NULL) {
      api.get = (GetBrightnessFn)dlsym(handle, "DisplayServicesGetBrightness");
      api.set = (SetBrightnessFn)dlsym(handle, "DisplayServicesSetBrightness");
    }
  }

  return &api;
}

static bool valid_brightness(float value) {
  return isfinite(value) && value >= 0.0F && value <= 1.0F;
}

bool brightness_get(CGDirectDisplayID display_id, float *value) {
  const BrightnessAPI *api = brightness_api();
  return value != NULL && api->get != NULL &&
         api->get(display_id, value) == 0 && valid_brightness(*value);
}

bool brightness_set(CGDirectDisplayID display_id, float value) {
  const BrightnessAPI *api = brightness_api();
  return valid_brightness(value) && api->set != NULL &&
         api->set(display_id, value) == 0;
}
