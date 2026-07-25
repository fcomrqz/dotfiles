#define QUICK_TAP_TERM_PER_KEY
#define TAPPING_TERM 200
#define POINTING_DEVICE_HIRES_SCROLL_ENABLE
#define POINTING_DEVICE_HIRES_SCROLL_MULTIPLIER 65
#define POINTING_DEVICE_HIRES_SCROLL_EXPONENT 3
#define MOUSEKEY_WHEEL_INTERVAL 68
#define MOUSEKEY_WHEEL_MAX_SPEED 1

// The Unicorne board compiles its OLED helper even when OLED support is off.
#if !defined(OLED_ENABLE) && !defined(__ASSEMBLER__)
#  include <stdint.h>
void oled_write_raw_P(const char *data, uint16_t size);
#endif
