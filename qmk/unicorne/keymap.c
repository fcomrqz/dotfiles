#include QMK_KEYBOARD_H

#define ALTERNATE_HOLD_TERM 300
#define DEAD_KEY_DELAY 20
#define ACCENT_QUEUE_CAPACITY 3
#define CAPS_WORD_TIMEOUT 3000
#define APP_SEARCH_DELAY 100

enum custom_keycodes {
  SYM_EXLM = SAFE_RANGE,
  SYM_AT,
  SYM_HASH,
  SYM_DLR,
  SYM_PERC,
  SYM_CIRC,
  SYM_AMPR,
  SYM_ASTR,
  SYM_LPRN,
  SYM_RPRN,
  SYM_UNDS,
};

static bool caps_word_active;
static uint16_t caps_word_timer;

static void caps_word_reset_timer(void) {
  caps_word_timer = timer_read();
}

static void caps_word_start(void) {
  caps_word_active = true;
  caps_word_reset_timer();
}

static void caps_word_stop(void) {
  caps_word_active = false;
  del_weak_mods(MOD_BIT(KC_LSFT));
  send_keyboard_report();
}

static bool caps_word_key_continues(uint16_t keycode, keyrecord_t *record) {
  const uint8_t mods = get_mods();

  // Classify navigation overrides by their output, not their home-row key.
  if ((mods & MOD_BIT(KC_LCTL)) && keycode == RSFT_T(KC_J)) {
    return false;  // Ctrl+J sends Enter, which ends Caps Word.
  }
  if ((mods & (MOD_BIT(KC_RCTL) | MOD_BIT(KC_RALT))) && keycode == LCMD_T(KC_D)) {
    return true;  // Right Ctrl/Alt+D sends Delete, which continues Caps Word.
  }

  if (IS_QK_MOD_TAP(keycode)) {
    if (record->tap.count == 0) {
      const uint8_t allowed_mods = MOD_LCTL | MOD_RCTL | MOD_LSFT | MOD_RSFT | MOD_RALT;
      return (QK_MOD_TAP_GET_MODS(keycode) & ~allowed_mods) == 0;
    }
    keycode = QK_MOD_TAP_GET_TAP_KEYCODE(keycode);
  } else if (IS_QK_LAYER_TAP(keycode)) {
    if (record->tap.count == 0) {
      return true;
    }
    keycode = QK_LAYER_TAP_GET_TAP_KEYCODE(keycode);
  }

  switch (keycode) {
    case KC_A ... KC_Z:
    case KC_1 ... KC_0:
    case KC_KP_1 ... KC_KP_0:
    case KC_MINS:
    case KC_UNDS:
    case KC_BSPC:
    case KC_DEL:
    case KC_RIGHT ... KC_UP:
    case KC_LCTL:
    case KC_RCTL:
    case KC_LSFT:
    case KC_RSFT:
    case KC_RALT:
    case SYM_EXLM ... SYM_UNDS:
      return true;
    default:
      return false;
  }
}

static bool caps_word_key_is_shifted(uint16_t keycode, keyrecord_t *record) {
  if (IS_QK_MOD_TAP(keycode)) {
    if (record->tap.count == 0) {
      return false;
    }
    keycode = QK_MOD_TAP_GET_TAP_KEYCODE(keycode);
  } else if (IS_QK_LAYER_TAP(keycode)) {
    if (record->tap.count == 0) {
      return false;
    }
    keycode = QK_LAYER_TAP_GET_TAP_KEYCODE(keycode);
  }

  return (keycode >= KC_A && keycode <= KC_Z) || keycode == KC_MINS;
}

static bool caps_word_key_is_navigation_override(uint16_t keycode) {
  const uint8_t mods = get_mods();
  if (IS_QK_MOD_TAP(keycode)) {
    keycode = QK_MOD_TAP_GET_TAP_KEYCODE(keycode);
  }

  if ((mods & MOD_BIT(KC_LCTL)) &&
      (keycode == KC_P || keycode == KC_N || keycode == KC_H)) {
    return true;
  }
  return (mods & (MOD_BIT(KC_RCTL) | MOD_BIT(KC_RALT))) &&
         (keycode == KC_F || keycode == KC_B || keycode == KC_D);
}

static void process_caps_word_key(uint16_t keycode, keyrecord_t *record) {
  if (!record->event.pressed) {
    return;
  }

  del_weak_mods(MOD_BIT(KC_LSFT));
  if (!caps_word_active) {
    return;
  }

  if (!caps_word_key_continues(keycode, record)) {
    caps_word_stop();
    return;
  }

  caps_word_reset_timer();
  if (caps_word_key_is_shifted(keycode, record) &&
      !caps_word_key_is_navigation_override(keycode)) {
    add_weak_mods(MOD_BIT(KC_LSFT));
  }
}

void housekeeping_task_user(void) {
  if (caps_word_active && timer_elapsed(caps_word_timer) >= CAPS_WORD_TIMEOUT) {
    caps_word_stop();
  }
}

typedef struct {
  bool active;
  bool hold_sent;
  bool shift_tap;
  deferred_token token;
  uint16_t tap_keycode;
  uint16_t hold_dead_keycode;
  uint16_t hold_keycode;
} alternate_hold_state_t;

typedef enum {
  ACCENT_DEAD_UP,
  ACCENT_BASE_DOWN,
  ACCENT_BASE_UP,
  ACCENT_RESTORE,
} accent_phase_t;

typedef struct {
  bool active;
  accent_phase_t phase;
  uint16_t base_keycode;
} accent_sequence_t;

static alternate_hold_state_t n_hold = {
  .tap_keycode = KC_N,
  .hold_dead_keycode = A(KC_N),
  .hold_keycode = KC_N,
};

static alternate_hold_state_t u_hold = {
  .tap_keycode = KC_U,
  .hold_dead_keycode = A(KC_U),
  .hold_keycode = KC_U,
};

static alternate_hold_state_t o_hold = {
  .tap_keycode = KC_O,
  .hold_dead_keycode = A(KC_U),
  .hold_keycode = KC_O,
};

static alternate_hold_state_t exlm_hold = {
  .tap_keycode = KC_EXLM,
  .hold_keycode = A(KC_1),
};

static alternate_hold_state_t dlr_hold = {
  .tap_keycode = KC_DLR,
  .hold_keycode = LSA(KC_2),
};

static const uint16_t PROGMEM symbol_keycodes[] = {
  [SYM_AT - SYM_AT] = KC_AT,
  [SYM_HASH - SYM_AT] = KC_HASH,
  [SYM_DLR - SYM_AT] = KC_NO,
  [SYM_PERC - SYM_AT] = KC_PERC,
  [SYM_CIRC - SYM_AT] = KC_CIRC,
  [SYM_AMPR - SYM_AT] = KC_AMPR,
  [SYM_ASTR - SYM_AT] = KC_ASTR,
  [SYM_LPRN - SYM_AT] = KC_LPRN,
  [SYM_RPRN - SYM_AT] = KC_RPRN,
  [SYM_UNDS - SYM_AT] = KC_UNDS,
};

static accent_sequence_t accent_sequence;
static uint16_t accent_dead_queue[ACCENT_QUEUE_CAPACITY];
static uint16_t accent_base_queue[ACCENT_QUEUE_CAPACITY];
static uint8_t accent_queue_head;
static uint8_t accent_queue_size;

static void send_accent_report(uint16_t keycode) {
  report_keyboard_t report = *keyboard_report;
  report.mods = 0;

  if (keycode != KC_NO) {
    report.mods = QK_MODS_GET_MODS(keycode);
    add_key_byte(&report, QK_MODS_GET_BASIC_KEYCODE(keycode));
  }

  host_keyboard_send(&report);
}

static void start_accent_sequence(uint16_t dead_keycode, uint16_t base_keycode) {
  accent_sequence.active = true;
  accent_sequence.phase = ACCENT_DEAD_UP;
  accent_sequence.base_keycode = base_keycode;
  send_accent_report(dead_keycode);
}

static bool start_queued_accent_sequence(void) {
  if (accent_queue_size == 0) {
    accent_sequence.active = false;
    return false;
  }

  const uint16_t dead_keycode = accent_dead_queue[accent_queue_head];
  const uint16_t base_keycode = accent_base_queue[accent_queue_head];
  accent_queue_head = (accent_queue_head + 1) % ACCENT_QUEUE_CAPACITY;
  accent_queue_size--;
  start_accent_sequence(dead_keycode, base_keycode);
  return true;
}

static uint32_t advance_accent_sequence(uint32_t trigger_time, void *cb_arg) {
  (void)trigger_time;
  (void)cb_arg;

  switch (accent_sequence.phase) {
    case ACCENT_DEAD_UP:
      send_accent_report(KC_NO);
      accent_sequence.phase = ACCENT_BASE_DOWN;
      break;
    case ACCENT_BASE_DOWN:
      send_accent_report(accent_sequence.base_keycode);
      accent_sequence.phase = ACCENT_BASE_UP;
      break;
    case ACCENT_BASE_UP:
      send_accent_report(KC_NO);
      accent_sequence.phase = ACCENT_RESTORE;
      break;
    case ACCENT_RESTORE: {
      report_keyboard_t report = *keyboard_report;
      host_keyboard_send(&report);

      if (!start_queued_accent_sequence()) {
        return 0;
      }
      break;
    }
  }

  return DEAD_KEY_DELAY;
}

static void queue_accent_sequence(uint16_t dead_keycode, uint16_t base_keycode) {
  if (!accent_sequence.active) {
    start_accent_sequence(dead_keycode, base_keycode);
    defer_exec(DEAD_KEY_DELAY, advance_accent_sequence, NULL);
    return;
  }

  if (accent_queue_size < ACCENT_QUEUE_CAPACITY) {
    const uint8_t tail = (accent_queue_head + accent_queue_size) % ACCENT_QUEUE_CAPACITY;
    accent_dead_queue[tail] = dead_keycode;
    accent_base_queue[tail] = base_keycode;
    accent_queue_size++;
  }
}

static uint32_t send_alternate_hold(uint32_t trigger_time, void *cb_arg) {
  (void)trigger_time;
  alternate_hold_state_t *state = (alternate_hold_state_t *)cb_arg;
  state->token = INVALID_DEFERRED_TOKEN;

  if (!state->active) {
    return 0;
  }

  if (state->hold_dead_keycode != KC_NO) {
    queue_accent_sequence(state->hold_dead_keycode, state->hold_keycode);
  } else {
    tap_code16(state->hold_keycode);
  }

  state->hold_sent = true;
  return 0;
}

static bool process_alternate_hold(keyrecord_t *record, alternate_hold_state_t *state) {
  if (record->event.pressed) {
    state->active = true;
    state->hold_sent = false;
    state->shift_tap = (get_mods() & MOD_MASK_SHIFT) || caps_word_active;

    if (caps_word_active) {
      caps_word_reset_timer();
    }

    state->token = defer_exec(ALTERNATE_HOLD_TERM, send_alternate_hold, state);
  } else if (state->active) {
    if (!state->hold_sent) {
      if (state->token != INVALID_DEFERRED_TOKEN) {
        cancel_deferred_exec(state->token);
      }
      tap_code16(state->shift_tap ? S(state->tap_keycode) : state->tap_keycode);
    }

    state->active = false;
    state->token = INVALID_DEFERRED_TOKEN;
  }

  return false;
}

static uint32_t finish_app_search(uint32_t trigger_time, void *cb_arg) {
  (void)trigger_time;
  (void)cb_arg;

  clear_keyboard();
  SEND_STRING("sa");
  tap_code(KC_ENT);
  return 0;
}

static void start_app_search(void) {
  // Release the home-row modifiers before sending the Spotlight sequence.
  clear_keyboard();
  tap_code16(G(KC_SPC));
  defer_exec(APP_SEARCH_DELAY, finish_app_search, NULL);
}

bool process_record_user(uint16_t keycode, keyrecord_t *record) {
  if (keycode == CW_TOGG) {
    if (record->event.pressed) {
      if (caps_word_active) {
        caps_word_reset_timer();
      } else {
        caps_word_start();
      }
    }
    return false;
  }

  if (keycode == KC_O && record->event.pressed) {
    const uint8_t mods = get_mods();
    if ((mods & MOD_MASK_GUI) && (mods & MOD_MASK_ALT)) {
      start_app_search();
      return false;
    }
  }

  process_caps_word_key(keycode, record);

  switch (keycode) {
    case KC_N:
      // Match Kanata's fork: left-side modifiers keep N as a normal key.
      if ((record->event.pressed &&
           (get_mods() & (MOD_BIT(KC_LCTL) | MOD_BIT(KC_LSFT) | MOD_BIT(KC_LALT) | MOD_BIT(KC_LGUI)))) ||
          (!record->event.pressed && !n_hold.active)) {
        return true;
      }
      return process_alternate_hold(record, &n_hold);
    case KC_U:
      return process_alternate_hold(record, &u_hold);
    case KC_O:
      return process_alternate_hold(record, &o_hold);
    case SYM_EXLM:
      return process_alternate_hold(record, &exlm_hold);
    case SYM_DLR:
      return process_alternate_hold(record, &dlr_hold);
    case SYM_AT:
    case SYM_HASH:
    case SYM_PERC:
    case SYM_CIRC:
    case SYM_AMPR:
    case SYM_ASTR:
    case SYM_LPRN:
    case SYM_RPRN:
    case SYM_UNDS:
      if (record->event.pressed) {
        tap_code16(pgm_read_word(&symbol_keycodes[keycode - SYM_AT]));
      }
      return false;
  }
  return true;
}

// Control
const key_override_t up_key_override = ko_make_basic(MOD_BIT_LCTRL, KC_P, KC_UP);
const key_override_t down_key_override = ko_make_basic(MOD_BIT_LCTRL, KC_N, KC_DOWN);
const key_override_t enter_key_override = ko_make_basic(MOD_BIT_LCTRL, RSFT_T(KC_J), KC_ENT);
const key_override_t backspace_key_override = ko_make_basic(MOD_BIT_LCTRL, KC_H, KC_BSPC);

const key_override_t right_key_override = ko_make_basic(MOD_BIT_RCTRL, LSFT_T(KC_F), KC_RIGHT);
const key_override_t left_key_override = ko_make_basic(MOD_BIT_RCTRL, KC_B, KC_LEFT);
const key_override_t delete_key_override = ko_make_basic(MOD_BIT_RCTRL, LCMD_T(KC_D), KC_DEL);

// Hyper
const key_override_t hyper_scroll_up_key_override = ko_make_basic(MOD_MASK_CSAG, KC_P, MS_WHLU);
const key_override_t hyper_scroll_down_key_override = ko_make_basic(MOD_MASK_CSAG, KC_N, MS_WHLD);

// Option
const key_override_t opt_up_key_override = ko_make_basic(MOD_BIT_LALT, KC_P, A(KC_UP));
const key_override_t opt_down_key_override = ko_make_basic(MOD_BIT_LALT, KC_N, A(KC_DOWN));
const key_override_t opt_enter_key_override = ko_make_basic(MOD_BIT_LALT, RSFT_T(KC_J), A(KC_ENT));
const key_override_t opt_backspace_key_override = ko_make_basic(MOD_BIT_LALT, KC_H, A(KC_BSPC));
const key_override_t right_bracket_key_override = ko_make_basic(MOD_BIT_LALT, KC_LBRC, KC_RBRC);

const key_override_t opt_right_key_override = ko_make_basic(MOD_BIT_RALT, LSFT_T(KC_F), RALT(KC_RIGHT));
const key_override_t opt_left_key_override = ko_make_basic(MOD_BIT_RALT, KC_B, RALT(KC_LEFT));
const key_override_t opt_delete_key_override = ko_make_basic(MOD_BIT_RALT, LCMD_T(KC_D), RALT(KC_DEL));

// Control Option
const key_override_t ctrl_opt_pageup_key_override = ko_make_basic(MOD_BIT_LCTRL | MOD_BIT_LALT, KC_P, KC_PGUP);
const key_override_t ctrl_opt_pagedown_key_override = ko_make_basic(MOD_BIT_LCTRL | MOD_BIT_LALT, KC_N, KC_PGDN);
const key_override_t ctrl_opt_enter_key_override = ko_make_basic(MOD_BIT_LCTRL | MOD_BIT_LALT, RSFT_T(KC_J), LCA(KC_ENT));
const key_override_t ctrl_opt_backspace_key_override = ko_make_basic(MOD_BIT_LCTRL | MOD_BIT_LALT, KC_H, LCA(KC_BSPC));

const key_override_t ctrl_opt_right_key_override = ko_make_basic(MOD_BIT_RCTRL | MOD_BIT_RALT, LSFT_T(KC_F), RCA(KC_RIGHT));
const key_override_t ctrl_opt_left_key_override = ko_make_basic(MOD_BIT_RCTRL | MOD_BIT_RALT, KC_B, RCA(KC_LEFT));
const key_override_t ctrl_opt_delete_key_override = ko_make_basic(MOD_BIT_RCTRL | MOD_BIT_RALT, LCMD_T(KC_D), RCA(KC_DEL));

// Shift Command
const key_override_t shift_cmd_h_key_override = ko_make_basic(MOD_BIT_LSHIFT | MOD_BIT_LGUI, KC_H, LSG(KC_H));

// Option Shift
const key_override_t opt_shift_up_key_override = ko_make_basic(MOD_BIT_LSHIFT | MOD_BIT_LALT, KC_P, LSA(KC_UP));
const key_override_t opt_shift_down_key_override = ko_make_basic(MOD_BIT_LSHIFT | MOD_BIT_LALT, KC_N, LSA(KC_DOWN));
const key_override_t opt_shift_enter_key_override = ko_make_basic(MOD_BIT_LSHIFT | MOD_BIT_LALT, RSFT_T(KC_J), LSA(KC_ENT));
const key_override_t opt_shift_backspace_key_override = ko_make_basic(MOD_BIT_LSHIFT | MOD_BIT_LALT, KC_H, LSA(KC_BSPC));

const key_override_t opt_shift_right_key_override = ko_make_basic(MOD_BIT_RSHIFT | MOD_BIT_RALT, LSFT_T(KC_F), RSA(KC_RIGHT));
const key_override_t opt_shift_left_key_override = ko_make_basic(MOD_BIT_RSHIFT | MOD_BIT_RALT, KC_B, RSA(KC_LEFT));
const key_override_t opt_shift_delete_key_override = ko_make_basic(MOD_BIT_RSHIFT | MOD_BIT_RALT, LCMD_T(KC_D), RSA(KC_DEL));

// Command
const key_override_t cmd_enter_key_override = ko_make_basic(MOD_BIT_LGUI, RSFT_T(KC_J), G(KC_ENT));
const key_override_t cmd_backspace_key_override = ko_make_basic(MOD_BIT_LGUI, KC_H, G(KC_BSPC));

const key_override_t *key_overrides[] = {
  &hyper_scroll_up_key_override,
  &hyper_scroll_down_key_override,
  &shift_cmd_h_key_override,
  &ctrl_opt_pageup_key_override,
  &ctrl_opt_pagedown_key_override,
  &ctrl_opt_right_key_override,
  &ctrl_opt_left_key_override,
  &ctrl_opt_enter_key_override,
  &ctrl_opt_backspace_key_override,
  &ctrl_opt_delete_key_override,
  &opt_shift_up_key_override,
  &opt_shift_down_key_override,
  &opt_shift_right_key_override,
  &opt_shift_left_key_override,
  &opt_shift_enter_key_override,
  &opt_shift_backspace_key_override,
  &opt_shift_delete_key_override,
  &opt_right_key_override,
  &opt_left_key_override,
  &opt_enter_key_override,
  &opt_backspace_key_override,
  &opt_delete_key_override,
  &up_key_override,
  &down_key_override,
  &right_key_override,
  &left_key_override,
  &enter_key_override,
  &backspace_key_override,
  &delete_key_override,
  &opt_up_key_override,
  &opt_down_key_override,
  &right_bracket_key_override,
  &cmd_enter_key_override,
  &cmd_backspace_key_override,
};

const uint16_t PROGMEM keymaps[][MATRIX_ROWS][MATRIX_COLS] = {
  // BASE LAYER
  [0] = LAYOUT_split_3x6_3(
  //,-----------------------------------------------------.                    ,-----------------------------------------------------.
       KC_TAB,    KC_Q,    KC_W,    KC_E,    KC_R,    KC_T,                         KC_Y,    KC_U,    KC_I,    KC_O,   KC_P,  KC_LBRC,
  //|--------+--------+--------+--------+--------+--------|                    |--------+--------+--------+--------+--------+--------|
HYPR_T(KC_ESC), LCTL_T(KC_A), LOPT_T(KC_S), LCMD_T(KC_D), LSFT_T(KC_F), KC_G,       KC_H, RSFT_T(KC_J), RCMD_T(KC_K), ROPT_T(KC_L), RCTL_T(KC_SCLN), KC_QUOT,
  //|--------+--------+--------+--------+--------+--------|                    |--------+--------+--------+--------+--------+--------|
      KC_GRV,    KC_Z,    KC_X,    KC_C,    KC_V,    KC_B,                          KC_N,    KC_M, KC_COMM,  KC_DOT, KC_SLSH,  KC_EQL,
  //|--------+--------+--------+--------+--------+--------+--------|  |--------+--------+--------+--------+--------+--------+--------|
                                          KC_NO, LT(9, KC_SPC), KC_NO, KC_NO, LT(9, KC_SPC), KC_NO
  ),

  [9] = LAYOUT_split_3x6_3(
  //,-----------------------------------------------------.                    ,-----------------------------------------------------.
       KC_TAB, SYM_EXLM, SYM_AT, SYM_HASH, SYM_DLR, SYM_PERC,                    SYM_CIRC, SYM_AMPR, SYM_ASTR, SYM_LPRN, SYM_RPRN, SYM_UNDS,
  //|--------+--------+--------+--------+--------+--------|                    |--------+--------+--------+--------+--------+--------|
      CW_TOGG,   KC_1,    KC_2,    KC_3,    KC_4,    KC_5,                         KC_6,    KC_7,    KC_8,    KC_9,    KC_0, KC_MINUS,
  //|--------+--------+--------+--------+--------+--------|                    |--------+--------+--------+--------+--------+--------|
        KC_NO, KC_BSLS,  KC_F14,  KC_F15, KC_PIPE, KC_MPRV,                      KC_MNXT, KC_MUTE, KC_VOLD, KC_VOLU, KC_MPLY, KC_MCTL,
  //|--------+--------+--------+--------+--------+--------+--------|  |--------+--------+--------+--------+--------+--------+--------|
                                          KC_NO, LT(9, KC_SPC), KC_NO, KC_NO, LT(9, KC_SPC), KC_NO
  ),
};

uint16_t get_quick_tap_term(uint16_t keycode, keyrecord_t *record) {
    switch (keycode) {
        case LT(9, KC_SPC):
            return 0;
        default:
            return QUICK_TAP_TERM;
    }
}
