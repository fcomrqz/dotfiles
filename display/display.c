#include <ApplicationServices/ApplicationServices.h>
#include <CoreFoundation/CoreFoundation.h>
#include <dlfcn.h>
#include <errno.h>
#include <fcntl.h>
#include <math.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>

#include "brightness.h"
#include "rotation.h"

#define ARRAY_COUNT(values) (sizeof(values) / sizeof((values)[0]))
#define MAX_DISPLAYS 32
#define NAME_SIZE 256
#define UUID_SIZE 64
#define ERROR_SIZE 256
#define BRIGHTNESS_STEP 0.0225F
#define SIDE_BRIGHTNESS_OFFSET 0.02625F

typedef CGError (*ConfigureDisplayEnabledFn)(CGDisplayConfigRef config,
                                             CGDirectDisplayID display,
                                             bool enabled);
typedef CFDictionaryRef (*DisplayCreateInfoDictionaryFn)(
    CGDirectDisplayID display);

typedef struct {
  const char *role;
  const char *uuid;
  int normal_orientation;
  int solo_orientation;
} KnownDisplay;

typedef struct {
  CGDirectDisplayID id;
  char name[NAME_SIZE];
  char uuid[UUID_SIZE];
  bool enabled;
  bool main;
  bool mirrored;
  int orientation;
} Display;

typedef struct {
  CGDirectDisplayID id;
  char uuid[UUID_SIZE];
  int orientation;
} SavedDisplay;

enum {
  MAIN_DISPLAY,
  LEFT_DISPLAY,
  FITNESS_DISPLAY,
};

static const KnownDisplay known_displays[] = {
    [MAIN_DISPLAY] = {
        .role = "main",
        .uuid = "1E1520FE-94BE-4EC7-BE8D-3F6DF7F99049",
        .normal_orientation = 90,
        .solo_orientation = 90,
    },
    [LEFT_DISPLAY] = {
        .role = "left",
        .uuid = "FC0249CC-8768-4F7E-9C15-CBCA19BCF41A",
        .normal_orientation = 90,
        .solo_orientation = 90,
    },
    [FITNESS_DISPLAY] = {
        .role = "fitness",
        .uuid = "57977437-1296-43A8-9836-89A69038CBBC",
        .normal_orientation = 270,
        .solo_orientation = 0,
    },
};

static void usage(FILE *stream, const char *program) {
  fprintf(stream,
          "usage:\n"
          "  %s list\n"
          "  %s main\n"
          "  %s fitness\n"
          "  %s reset\n"
          "  %s brightness [up|down|VALUE]\n"
          "  %s orientation TARGET DEGREES\n"
          "\n"
          "main     Enable only the main display at 90 degrees.\n"
          "fitness  Enable only the fitness display at 0 degrees.\n"
          "reset    Re-enable all three displays and restore orientation.\n"
          "\n"
          "TARGET is main, fitness, or a display UUID. DEGREES must be\n"
          "0, 90, 180, or 270. Brightness VALUE must be from 0 through 1.\n",
          program, program, program, program, program, program);
}

static void *load_symbol(const char *framework, const char *name) {
  void *symbol = dlsym(RTLD_DEFAULT, name);
  if (symbol != NULL) {
    return symbol;
  }

  void *handle = dlopen(framework, RTLD_LAZY | RTLD_LOCAL);
  return handle == NULL ? NULL : dlsym(handle, name);
}

static ConfigureDisplayEnabledFn configure_display_enabled(void) {
  static const char *frameworks[] = {
      "/System/Library/PrivateFrameworks/SkyLight.framework/SkyLight",
      "/System/Library/Frameworks/CoreGraphics.framework/CoreGraphics",
  };

  static ConfigureDisplayEnabledFn function = NULL;
  static bool loaded = false;
  if (!loaded) {
    loaded = true;
    for (size_t i = 0; i < ARRAY_COUNT(frameworks); i++) {
      void *symbol =
          load_symbol(frameworks[i], "CGSConfigureDisplayEnabled");
      if (symbol != NULL) {
        function = (ConfigureDisplayEnabledFn)symbol;
        break;
      }
    }
  }
  return function;
}

static DisplayCreateInfoDictionaryFn display_info_dictionary(void) {
  static const char *framework =
      "/System/Library/Frameworks/CoreDisplay.framework/CoreDisplay";
  static DisplayCreateInfoDictionaryFn function = NULL;
  static bool loaded = false;
  if (!loaded) {
    loaded = true;
    function = (DisplayCreateInfoDictionaryFn)load_symbol(
        framework, "CoreDisplay_DisplayCreateInfoDictionary");
  }
  return function;
}

static bool copy_cf_string(CFStringRef string, char *destination, size_t size) {
  return string != NULL && CFGetTypeID(string) == CFStringGetTypeID() &&
         CFStringGetCString(string, destination, (CFIndex)size,
                            kCFStringEncodingUTF8);
}

static bool copy_display_name_value(CFTypeRef value, char *destination,
                                    size_t size) {
  if (value == NULL) {
    return false;
  }
  if (CFGetTypeID(value) == CFStringGetTypeID()) {
    return copy_cf_string((CFStringRef)value, destination, size);
  }
  if (CFGetTypeID(value) != CFDictionaryGetTypeID()) {
    return false;
  }

  CFDictionaryRef names = (CFDictionaryRef)value;
  const CFStringRef preferred_keys[] = {CFSTR("en_US"), CFSTR("en")};
  for (size_t i = 0; i < ARRAY_COUNT(preferred_keys); i++) {
    CFTypeRef name = CFDictionaryGetValue(names, preferred_keys[i]);
    if (copy_cf_string((CFStringRef)name, destination, size)) {
      return true;
    }
  }

  CFIndex count = CFDictionaryGetCount(names);
  if (count <= 0) {
    return false;
  }

  const void **values = calloc((size_t)count, sizeof(*values));
  if (values == NULL) {
    return false;
  }

  CFDictionaryGetKeysAndValues(names, NULL, values);
  bool copied = false;
  for (CFIndex i = 0; i < count && !copied; i++) {
    copied = copy_cf_string((CFStringRef)values[i], destination, size);
  }
  free(values);
  return copied;
}

static void copy_display_name(DisplayCreateInfoDictionaryFn create_info,
                              CGDirectDisplayID id, char *destination,
                              size_t size) {
  destination[0] = '\0';
  if (create_info != NULL) {
    CFDictionaryRef info = create_info(id);
    if (info != NULL) {
      CFTypeRef value =
          CFDictionaryGetValue(info, CFSTR("DisplayProductName"));
      bool copied = copy_display_name_value(value, destination, size);
      CFRelease(info);
      if (copied) {
        return;
      }
    }
  }
  snprintf(destination, size, "Display %u", id);
}

static void copy_display_uuid(CGDirectDisplayID id, char *destination,
                              size_t size) {
  destination[0] = '\0';
  CFUUIDRef uuid = CGDisplayCreateUUIDFromDisplayID(id);
  if (uuid == NULL) {
    strlcpy(destination, "unavailable", size);
    return;
  }

  CFStringRef string = CFUUIDCreateString(kCFAllocatorDefault, uuid);
  if (!copy_cf_string(string, destination, size)) {
    strlcpy(destination, "unavailable", size);
  }
  if (string != NULL) {
    CFRelease(string);
  }
  CFRelease(uuid);
}

static int display_orientation(CGDirectDisplayID id) {
  int degrees = (int)lround(CGDisplayRotation(id));
  return ((degrees % 360) + 360) % 360;
}

static CGError load_displays(Display displays[], CGDisplayCount *count) {
  CGDirectDisplayID ids[MAX_DISPLAYS];
  CGDisplayCount found = 0;
  CGError error = CGGetOnlineDisplayList(MAX_DISPLAYS, ids, &found);
  if (error != kCGErrorSuccess) {
    return error;
  }

  DisplayCreateInfoDictionaryFn create_info = display_info_dictionary();
  for (CGDisplayCount i = 0; i < found; i++) {
    Display *display = &displays[i];
    display->id = ids[i];
    display->enabled =
        CGDisplayIsActive(ids[i]) || CGDisplayIsInMirrorSet(ids[i]);
    display->main = CGDisplayIsMain(ids[i]);
    display->mirrored = CGDisplayIsInMirrorSet(ids[i]);
    display->orientation = display_orientation(ids[i]);
    copy_display_name(create_info, ids[i], display->name, sizeof(display->name));
    copy_display_uuid(ids[i], display->uuid, sizeof(display->uuid));
  }

  *count = found;
  return kCGErrorSuccess;
}

static const Display *find_uuid(const Display displays[], CGDisplayCount count,
                                const char *uuid) {
  for (CGDisplayCount i = 0; i < count; i++) {
    if (strcasecmp(displays[i].uuid, uuid) == 0) {
      return &displays[i];
    }
  }
  return NULL;
}

static const Display *find_main(const Display displays[],
                                CGDisplayCount count) {
  for (CGDisplayCount i = 0; i < count; i++) {
    if (displays[i].main && displays[i].enabled) {
      return &displays[i];
    }
  }
  return NULL;
}

static CGDisplayCount enabled_display_count(const Display displays[],
                                            CGDisplayCount count) {
  CGDisplayCount enabled = 0;
  for (CGDisplayCount i = 0; i < count; i++) {
    if (displays[i].enabled) {
      enabled++;
    }
  }
  return enabled;
}

static bool full_setup_enabled(const Display displays[], CGDisplayCount count) {
  for (size_t i = 0; i < ARRAY_COUNT(known_displays); i++) {
    const Display *display =
        find_uuid(displays, count, known_displays[i].uuid);
    if (display == NULL || !display->enabled) {
      return false;
    }
  }
  return true;
}

static void print_displays(const Display displays[], CGDisplayCount count) {
  if (count == 0) {
    puts("No online displays found.");
    return;
  }

  for (CGDisplayCount i = 0; i < count; i++) {
    const Display *display = &displays[i];
    float value = 0.0F;
    bool has_brightness = brightness_get(display->id, &value);

    printf("%s\n"
           "  id: %u\n"
           "  uuid: %s\n"
           "  enabled: %s%s%s\n"
           "  orientation: %d°\n",
           display->name, display->id, display->uuid,
           display->enabled ? "yes" : "no", display->main ? ", main" : "",
           display->mirrored ? ", mirrored" : "", display->orientation);
    if (has_brightness) {
      printf("  brightness: %.4f\n", (double)value);
    } else {
      puts("  brightness: unavailable");
    }
  }
}

static float clamp_brightness(float value) {
  if (value < 0.0F) {
    return 0.0F;
  }
  if (value > 1.0F) {
    return 1.0F;
  }
  return value;
}

static int print_brightness(const Display displays[], CGDisplayCount count) {
  bool printed = false;
  bool failed = false;

  for (CGDisplayCount i = 0; i < count; i++) {
    if (!displays[i].enabled) {
      continue;
    }

    float value = 0.0F;
    if (!brightness_get(displays[i].id, &value)) {
      fprintf(stderr, "Could not read brightness for \"%s\" (%s).\n",
              displays[i].name, displays[i].uuid);
      failed = true;
      continue;
    }

    printf("%s%s: %.4f\n", displays[i].name,
           displays[i].main ? " (main)" : "", (double)value);
    printed = true;
  }

  if (!printed && !failed) {
    fputs("No enabled displays found.\n", stderr);
    failed = true;
  }
  return failed ? EXIT_FAILURE : EXIT_SUCCESS;
}

static int apply_brightness(const Display displays[], CGDisplayCount count,
                            float main_value) {
  const Display *main_display = find_main(displays, count);
  if (main_display == NULL) {
    fputs("Could not identify an enabled main display.\n", stderr);
    return EXIT_FAILURE;
  }

  float side_value = clamp_brightness(main_value - SIDE_BRIGHTNESS_OFFSET);
  bool changed = false;
  bool failed = false;

  for (CGDisplayCount i = 0; i < count; i++) {
    if (!displays[i].enabled) {
      continue;
    }

    float value =
        displays[i].id == main_display->id ? main_value : side_value;
    if (!brightness_set(displays[i].id, value)) {
      fprintf(stderr, "Could not set brightness for \"%s\" (%s).\n",
              displays[i].name, displays[i].uuid);
      failed = true;
    } else {
      changed = true;
    }
  }

  if (!changed) {
    return EXIT_FAILURE;
  }

  printf("Main display brightness: %.4f, side displays brightness: %.4f\n",
         (double)main_value, (double)side_value);
  return failed ? EXIT_FAILURE : EXIT_SUCCESS;
}

static bool parse_brightness(const char *text, float *value) {
  errno = 0;
  char *end = NULL;
  float parsed = strtof(text, &end);
  if (errno != 0 || end == text || *end != '\0' || !isfinite(parsed) ||
      parsed < 0.0F || parsed > 1.0F) {
    return false;
  }
  *value = parsed;
  return true;
}

static int brightness_command(const Display displays[], CGDisplayCount count,
                              int argc, char *argv[]) {
  if (argc == 2) {
    return print_brightness(displays, count);
  }
  if (argc != 3) {
    return -1;
  }

  float requested = 0.0F;
  bool adjusting =
      strcmp(argv[2], "up") == 0 || strcmp(argv[2], "down") == 0;
  if (adjusting) {
    const Display *main_display = find_main(displays, count);
    float current = 0.0F;
    if (main_display == NULL ||
        !brightness_get(main_display->id, &current)) {
      fputs("Could not read brightness from the enabled main display.\n",
            stderr);
      return EXIT_FAILURE;
    }

    float delta =
        strcmp(argv[2], "up") == 0 ? BRIGHTNESS_STEP : -BRIGHTNESS_STEP;
    requested = clamp_brightness(current + delta);
  } else if (!parse_brightness(argv[2], &requested)) {
    fprintf(stderr, "Brightness must be up, down, or a value from 0 through 1: "
                    "%s\n",
            argv[2]);
    return EXIT_FAILURE;
  }

  return apply_brightness(displays, count, requested);
}

static bool valid_orientation(int degrees) {
  return degrees == 0 || degrees == 90 || degrees == 180 || degrees == 270;
}

static bool parse_orientation(const char *text, int *degrees) {
  errno = 0;
  char *end = NULL;
  long parsed = strtol(text, &end, 10);
  if (errno != 0 || end == text || *end != '\0' ||
      (parsed != 0 && parsed != 90 && parsed != 180 && parsed != 270)) {
    return false;
  }
  *degrees = (int)parsed;
  return true;
}

static int rotate_display(const Display *display, int degrees, bool announce) {
  if (display->orientation == degrees) {
    if (announce) {
      printf("\"%s\" is already at %d°.\n", display->name, degrees);
    }
    return EXIT_SUCCESS;
  }

  char error[ERROR_SIZE] = {0};
  if (!set_display_orientation(display->id, degrees, error, sizeof(error))) {
    fprintf(stderr, "Could not rotate \"%s\" to %d°: %s\n", display->name,
            degrees, error[0] == '\0' ? "unknown error" : error);
    return EXIT_FAILURE;
  }

  if (announce) {
    printf("Rotated \"%s\" to %d°.\n", display->name, degrees);
  }
  return EXIT_SUCCESS;
}

static const Display *orientation_target(const Display displays[],
                                         CGDisplayCount count,
                                         const char *target) {
  if (strcmp(target, "main") == 0) {
    return find_uuid(displays, count, known_displays[MAIN_DISPLAY].uuid);
  }
  if (strcmp(target, "fitness") == 0) {
    return find_uuid(displays, count, known_displays[FITNESS_DISPLAY].uuid);
  }
  return find_uuid(displays, count, target);
}

static int orientation_command(const Display displays[], CGDisplayCount count,
                               const char *target, const char *value) {
  int degrees = 0;
  if (!parse_orientation(value, &degrees)) {
    fprintf(stderr, "Orientation must be 0, 90, 180, or 270: %s\n", value);
    return EXIT_FAILURE;
  }

  const Display *display = orientation_target(displays, count, target);
  if (display == NULL) {
    fprintf(stderr, "Enabled display not found: %s\n", target);
    return EXIT_FAILURE;
  }
  if (!display->enabled) {
    fprintf(stderr, "Display \"%s\" is disabled; run reset first.\n",
            display->name);
    return EXIT_FAILURE;
  }
  return rotate_display(display, degrees, true);
}

static void state_path(char *destination, size_t size) {
  snprintf(destination, size, "/tmp/display-%u.state", getuid());
}

static bool save_display_state(const Display displays[], CGDisplayCount count) {
  const Display *setup[ARRAY_COUNT(known_displays)];
  for (size_t i = 0; i < ARRAY_COUNT(known_displays); i++) {
    setup[i] = find_uuid(displays, count, known_displays[i].uuid);
    if (setup[i] == NULL || !setup[i]->enabled) {
      return false;
    }
  }

  char path[128];
  char temporary_path[160];
  state_path(path, sizeof(path));
  snprintf(temporary_path, sizeof(temporary_path), "%s.XXXXXX", path);

  int descriptor = mkstemp(temporary_path);
  if (descriptor == -1) {
    fprintf(stderr, "Could not create display state: %s\n", strerror(errno));
    return false;
  }
  if (fchmod(descriptor, 0600) == -1) {
    fprintf(stderr, "Could not protect display state: %s\n", strerror(errno));
    close(descriptor);
    unlink(temporary_path);
    return false;
  }

  FILE *file = fdopen(descriptor, "w");
  if (file == NULL) {
    fprintf(stderr, "Could not open display state: %s\n", strerror(errno));
    close(descriptor);
    unlink(temporary_path);
    return false;
  }

  bool saved = true;
  for (size_t i = 0; i < ARRAY_COUNT(setup); i++) {
    if (fprintf(file, "%u %s %d\n", setup[i]->id, setup[i]->uuid,
                setup[i]->orientation) < 0) {
      saved = false;
      break;
    }
  }
  if (fclose(file) == EOF) {
    saved = false;
  }
  if (!saved || rename(temporary_path, path) == -1) {
    fprintf(stderr, "Could not save display state: %s\n", strerror(errno));
    unlink(temporary_path);
    return false;
  }
  return true;
}

static size_t load_display_state(SavedDisplay displays[], size_t capacity) {
  char path[128];
  state_path(path, sizeof(path));
  FILE *file = fopen(path, "r");
  if (file == NULL) {
    return 0;
  }

  size_t count = 0;
  char line[192];
  while (count < capacity && fgets(line, sizeof(line), file) != NULL) {
    unsigned int id = 0;
    char uuid[UUID_SIZE];
    int orientation = 0;
    char trailing = '\0';
    if (sscanf(line, "%u %63s %d %c", &id, uuid, &orientation, &trailing) !=
            3 ||
        !valid_orientation(orientation)) {
      count = 0;
      break;
    }

    displays[count].id = (CGDirectDisplayID)id;
    strlcpy(displays[count].uuid, uuid, sizeof(displays[count].uuid));
    displays[count].orientation = orientation;
    count++;
  }

  fclose(file);
  return count;
}

static void clear_display_state(void) {
  char path[128];
  state_path(path, sizeof(path));
  unlink(path);
}

static CGDirectDisplayID display_id_from_uuid(const char *uuid_text) {
  CFStringRef string = CFStringCreateWithCString(
      kCFAllocatorDefault, uuid_text, kCFStringEncodingUTF8);
  if (string == NULL) {
    return kCGNullDirectDisplay;
  }

  CFUUIDRef uuid = CFUUIDCreateFromString(kCFAllocatorDefault, string);
  CFRelease(string);
  if (uuid == NULL) {
    return kCGNullDirectDisplay;
  }

  CGDirectDisplayID id = CGDisplayGetDisplayIDFromUUID(uuid);
  CFRelease(uuid);
  return id;
}

static const SavedDisplay *find_saved_uuid(const SavedDisplay displays[],
                                           size_t count, const char *uuid) {
  for (size_t i = 0; i < count; i++) {
    if (strcasecmp(displays[i].uuid, uuid) == 0) {
      return &displays[i];
    }
  }
  return NULL;
}

static CGDirectDisplayID resolve_display_id(
    const Display displays[], CGDisplayCount count,
    const SavedDisplay saved_displays[], size_t saved_count, const char *uuid) {
  const Display *online = find_uuid(displays, count, uuid);
  if (online != NULL) {
    return online->id;
  }

  CGDirectDisplayID id = display_id_from_uuid(uuid);
  if (id != kCGNullDirectDisplay) {
    return id;
  }

  const SavedDisplay *saved =
      find_saved_uuid(saved_displays, saved_count, uuid);
  return saved == NULL ? kCGNullDirectDisplay : saved->id;
}

static CGError set_display_enabled(ConfigureDisplayEnabledFn configure,
                                   CGDirectDisplayID display_id,
                                   bool enabled) {
  CGDisplayConfigRef config = NULL;
  CGError error = CGBeginDisplayConfiguration(&config);
  if (error != kCGErrorSuccess) {
    return error;
  }

  error = configure(config, display_id, enabled);
  if (error != kCGErrorSuccess) {
    CGCancelDisplayConfiguration(config);
    return error;
  }
  return CGCompleteDisplayConfiguration(config, kCGConfigureForSession);
}

static int apply_preset(const Display displays[], CGDisplayCount count,
                        size_t known_index) {
  const KnownDisplay *preset = &known_displays[known_index];
  const Display *target = find_uuid(displays, count, preset->uuid);
  bool target_enabled = target != NULL && target->enabled;
  bool other_displays_enabled =
      enabled_display_count(displays, count) > (target_enabled ? 1U : 0U);

  SavedDisplay saved_displays[ARRAY_COUNT(known_displays)];
  if (full_setup_enabled(displays, count)) {
    if (!save_display_state(displays, count)) {
      fputs("Refusing to disable displays without a recovery state.\n", stderr);
      return EXIT_FAILURE;
    }
  }
  size_t saved_count =
      load_display_state(saved_displays, ARRAY_COUNT(saved_displays));

  CGDirectDisplayID target_id =
      resolve_display_id(displays, count, saved_displays, saved_count,
                         preset->uuid);
  if (target_id == kCGNullDirectDisplay) {
    fprintf(stderr, "Could not resolve the %s display UUID: %s\n",
            preset->role, preset->uuid);
    return EXIT_FAILURE;
  }

  ConfigureDisplayEnabledFn configure = NULL;
  if (!target_enabled || other_displays_enabled) {
    configure = configure_display_enabled();
    if (configure == NULL) {
      fputs("CGSConfigureDisplayEnabled is unavailable on this macOS version.\n",
            stderr);
      return EXIT_FAILURE;
    }
  }

  Display preset_display = {
      .id = target_id,
      .enabled = true,
      .orientation = -1,
  };
  snprintf(preset_display.name, sizeof(preset_display.name), "%s display",
           preset->role);

  if (!target_enabled) {
    CGError error = set_display_enabled(configure, target_id, true);
    if (error != kCGErrorSuccess) {
      fprintf(stderr, "Could not enable the %s display: %d\n", preset->role,
              error);
      return EXIT_FAILURE;
    }
    usleep(250000);
  } else {
    preset_display = *target;
  }

  if (rotate_display(&preset_display, preset->solo_orientation, false) !=
      EXIT_SUCCESS) {
    return EXIT_FAILURE;
  }

  if (other_displays_enabled) {
    CGDisplayConfigRef config = NULL;
    CGError error = CGBeginDisplayConfiguration(&config);
    for (CGDisplayCount i = 0;
         error == kCGErrorSuccess && i < count; i++) {
      if (displays[i].enabled && displays[i].id != target_id) {
        error = configure(config, displays[i].id, false);
      }
    }

    if (error != kCGErrorSuccess) {
      if (config != NULL) {
        CGCancelDisplayConfiguration(config);
      }
      fprintf(stderr, "Could not configure the %s display preset: %d\n",
              preset->role, error);
      return EXIT_FAILURE;
    }

    error = CGCompleteDisplayConfiguration(config, kCGConfigureForSession);
    if (error != kCGErrorSuccess) {
      fprintf(stderr, "Could not apply the %s display preset: %d\n",
              preset->role, error);
      return EXIT_FAILURE;
    }
  }

  printf("Enabled only the %s display at %d°.\n", preset->role,
         preset->solo_orientation);
  return EXIT_SUCCESS;
}

static int reset_displays(const Display displays[], CGDisplayCount count) {
  SavedDisplay saved_displays[ARRAY_COUNT(known_displays)];
  size_t saved_count =
      load_display_state(saved_displays, ARRAY_COUNT(saved_displays));

  CGDirectDisplayID ids[ARRAY_COUNT(known_displays)];
  for (size_t i = 0; i < ARRAY_COUNT(known_displays); i++) {
    ids[i] = resolve_display_id(displays, count, saved_displays, saved_count,
                                known_displays[i].uuid);
    if (ids[i] == kCGNullDirectDisplay) {
      fprintf(stderr, "Could not resolve the %s display UUID: %s\n",
              known_displays[i].role, known_displays[i].uuid);
      return EXIT_FAILURE;
    }
  }

  ConfigureDisplayEnabledFn configure = configure_display_enabled();
  if (configure == NULL) {
    fputs("CGSConfigureDisplayEnabled is unavailable on this macOS version.\n",
          stderr);
    return EXIT_FAILURE;
  }

  bool reenabled = false;
  for (size_t i = 0; i < ARRAY_COUNT(known_displays); i++) {
    const Display *display =
        find_uuid(displays, count, known_displays[i].uuid);
    if (display != NULL && display->enabled) {
      continue;
    }

    CGError error = set_display_enabled(configure, ids[i], true);
    if (error != kCGErrorSuccess) {
      fprintf(stderr, "Could not re-enable the %s display: %d\n",
              known_displays[i].role, error);
      return EXIT_FAILURE;
    }
    reenabled = true;
  }

  if (reenabled) {
    usleep(250000);
  }

  bool failed = false;
  for (size_t i = 0; i < ARRAY_COUNT(known_displays); i++) {
    const Display *current =
        find_uuid(displays, count, known_displays[i].uuid);
    Display display = {
        .id = ids[i],
        .enabled = true,
        .orientation = -1,
    };
    snprintf(display.name, sizeof(display.name), "%s display",
             known_displays[i].role);
    if (current != NULL && current->enabled) {
      display = *current;
    }

    const SavedDisplay *saved =
        find_saved_uuid(saved_displays, saved_count, known_displays[i].uuid);
    int orientation = saved == NULL ? known_displays[i].normal_orientation
                                    : saved->orientation;
    if (rotate_display(&display, orientation, false) != EXIT_SUCCESS) {
      failed = true;
    }
  }

  if (failed) {
    return EXIT_FAILURE;
  }

  clear_display_state();
  puts("Restored all three displays and their orientations.");
  return EXIT_SUCCESS;
}

int main(int argc, char *argv[]) {
  if (argc < 2) {
    usage(stderr, argv[0]);
    return EXIT_FAILURE;
  }

  Display displays[MAX_DISPLAYS];
  CGDisplayCount count = 0;
  CGError error = load_displays(displays, &count);
  if (error != kCGErrorSuccess) {
    fprintf(stderr, "Could not enumerate displays: %d\n", error);
    return EXIT_FAILURE;
  }

  if (strcmp(argv[1], "list") == 0 && argc == 2) {
    print_displays(displays, count);
    return EXIT_SUCCESS;
  }
  if (strcmp(argv[1], "main") == 0 && argc == 2) {
    return apply_preset(displays, count, MAIN_DISPLAY);
  }
  if (strcmp(argv[1], "fitness") == 0 && argc == 2) {
    return apply_preset(displays, count, FITNESS_DISPLAY);
  }
  if (strcmp(argv[1], "reset") == 0 && argc == 2) {
    return reset_displays(displays, count);
  }
  if (strcmp(argv[1], "brightness") == 0) {
    int result = brightness_command(displays, count, argc, argv);
    if (result >= 0) {
      return result;
    }
  } else if (strcmp(argv[1], "orientation") == 0 && argc == 4) {
    return orientation_command(displays, count, argv[2], argv[3]);
  }

  usage(stderr, argv[0]);
  return EXIT_FAILURE;
}
