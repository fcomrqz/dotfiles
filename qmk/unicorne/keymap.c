#include QMK_KEYBOARD_H

enum custom_keycodes {
  ALT_NN = SAFE_RANGE,
};

bool process_record_user(uint16_t keycode, keyrecord_t *record) {
  switch (keycode) {
    case ALT_NN:
      if (record->event.pressed) {
        tap_code16(A(KC_N));
      }
      return false;            // Don't let QMK send anything else for this key
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

// Option
const key_override_t pageup_key_override = ko_make_basic(MOD_BIT_LALT, KC_P, KC_PGUP);
const key_override_t pagedown_key_override = ko_make_basic(MOD_BIT_LALT, KC_N, KC_PGDN);
const key_override_t opt_enter_key_override = ko_make_basic(MOD_BIT_LALT, RSFT_T(KC_J), A(KC_ENT));
const key_override_t opt_backspace_key_override = ko_make_basic(MOD_BIT_LALT, KC_H, A(KC_BSPC));
const key_override_t right_bracket_key_override = ko_make_basic(MOD_BIT_LALT, KC_LBRC, KC_RBRC);

const key_override_t opt_right_key_override = ko_make_basic(MOD_BIT_RALT, LSFT_T(KC_F), A(KC_RIGHT));
const key_override_t opt_left_key_override = ko_make_basic(MOD_BIT_RALT, KC_B, A(KC_LEFT));
const key_override_t opt_delete_key_override = ko_make_basic(MOD_BIT_RALT, LCMD_T(KC_D), A(KC_DEL));

// Control Option
const key_override_t ctrl_opt_up_key_override = ko_make_basic(MOD_BIT_LCTRL | MOD_BIT_LALT, KC_P, LCA(KC_UP));
const key_override_t ctrl_opt_down_key_override = ko_make_basic(MOD_BIT_LCTRL | MOD_BIT_LALT, KC_N, LCA(KC_DOWN));
const key_override_t ctrl_opt_enter_key_override = ko_make_basic(MOD_BIT_LCTRL | MOD_BIT_LALT, RSFT_T(KC_J), LCA(KC_ENT));
const key_override_t ctrl_opt_backspace_key_override = ko_make_basic(MOD_BIT_LCTRL | MOD_BIT_LALT, KC_H, LCA(KC_H));

const key_override_t ctrl_opt_right_key_override = ko_make_basic(MOD_BIT_RCTRL | MOD_BIT_RALT, LSFT_T(KC_F), LCA(KC_RIGHT));
const key_override_t ctrl_opt_left_key_override = ko_make_basic(MOD_BIT_RCTRL | MOD_BIT_RALT, KC_B, LCA(KC_LEFT));
const key_override_t ctrl_opt_delete_key_override = ko_make_basic(MOD_BIT_RCTRL | MOD_BIT_RALT, LCMD_T(KC_D), LCA(KC_DEL));

// Command Option
const key_override_t opt_cmd_up_override = ko_make_basic(MOD_BIT_LGUI | MOD_BIT_LALT, KC_P, LAG(KC_P));
const key_override_t opt_cmd_down_override = ko_make_basic(MOD_BIT_LGUI | MOD_BIT_LALT, KC_N, LAG(KC_N));

// Shift Command
const key_override_t shift_cmd_h_key_override = ko_make_basic(MOD_BIT_LSHIFT | MOD_BIT_LGUI, KC_H, RSG(KC_H));

// Option Shift
const key_override_t opt_shift_up_key_override = ko_make_basic(MOD_BIT_LSHIFT | MOD_BIT_LALT, KC_P, RSA(KC_UP));
const key_override_t opt_shift_down_key_override = ko_make_basic(MOD_BIT_LSHIFT | MOD_BIT_LALT, KC_N, RSA(KC_DOWN));
const key_override_t opt_shift_enter_key_override = ko_make_basic(MOD_BIT_LSHIFT | MOD_BIT_LALT, RSFT_T(KC_J), RSA(KC_ENT));
const key_override_t opt_shift_backspace_key_override = ko_make_basic(MOD_BIT_LSHIFT | MOD_BIT_LALT, KC_H, RSA(KC_BSPC));

const key_override_t opt_shift_right_key_override = ko_make_basic(MOD_BIT_RSHIFT | MOD_BIT_RALT, LSFT_T(KC_F), RSA(KC_RIGHT));
const key_override_t opt_shift_left_key_override = ko_make_basic(MOD_BIT_RSHIFT | MOD_BIT_RALT, KC_B, RSA(KC_LEFT));
const key_override_t opt_shift_delete_key_override = ko_make_basic(MOD_BIT_RSHIFT | MOD_BIT_RALT, LCMD_T(KC_D), RSA(KC_DEL));

// Command
const key_override_t cmd_enter_key_override = ko_make_basic(MOD_BIT_LGUI, RSFT_T(KC_J), G(KC_ENT));
const key_override_t cmd_backspace_key_override = ko_make_basic(MOD_BIT_LGUI, KC_H, G(KC_BSPC));

bool duplicate_line(bool key_down, void *layer) {
    if(key_down) {
      clear_keyboard();
      tap_code16(G(KC_LEFT));
      tap_code16(LSG(KC_RIGHT));
      tap_code16(G(KC_C));
      tap_code(KC_RIGHT);
      tap_code16(C(KC_ENT));
      tap_code16(G(KC_V));
    }
    return false;
}

const key_override_t duplicate_key_overrides = {
  .trigger_mods = MOD_BIT(KC_RGUI) | MOD_BIT(KC_RALT),
  .layers = ~0,
  .custom_action = duplicate_line,
  .trigger = LCMD_T(KC_D),
  .replacement = KC_NO,
  .enabled = NULL
};

bool move_line_up(bool key_down, void *layer) {
    if(key_down) {
      clear_keyboard();
      SEND_STRING(SS_LCTL("a" SS_LSFT("e")));
      SEND_STRING(SS_LGUI("x"));
      tap_code(KC_BSPC);
      tap_code16(G(KC_RIGHT));
      tap_code16(C(KC_ENT));
      tap_code(KC_UP);
      tap_code16(G(KC_V));
    }
    return false;
}

const key_override_t move_line_up_key_overrides = {
  .trigger_mods = MOD_BIT(KC_LGUI) | MOD_BIT(KC_LALT),
  .layers = ~0,
  .custom_action = move_line_up,
  .trigger = KC_P,
  .replacement = KC_NO,
  .enabled = NULL
};

const key_override_t *key_overrides[] = {
  // &move_line_up_key_overrides,
  // &duplicate_key_overrides,
  &shift_cmd_h_key_override,
  &opt_cmd_down_override,
  &opt_cmd_up_override,
  &ctrl_opt_up_key_override,
  &ctrl_opt_down_key_override,
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
  &pageup_key_override,
  &pagedown_key_override,
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
       KC_TAB, KC_EXLM,   KC_AT, KC_HASH,  KC_DLR, KC_PERC,                      KC_CIRC, KC_AMPR, KC_ASTR, KC_LPRN, KC_RPRN, KC_UNDS,
  //|--------+--------+--------+--------+--------+--------|                    |--------+--------+--------+--------+--------+--------|
      CW_TOGG,   KC_1,    KC_2,    KC_3,    KC_4,    KC_5,                         KC_6,    KC_7,    KC_8,    KC_9,    KC_0, KC_MINUS,
  //|--------+--------+--------+--------+--------+--------|                    |--------+--------+--------+--------+--------+--------|
       KC_PWR, KC_BSLS, KC_SCRL, KC_PAUS, KC_PIPE, KC_MPRV,                      KC_MNXT, KC_MUTE, KC_VOLD, KC_VOLU, KC_MPLY, KC_MCTL,
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
