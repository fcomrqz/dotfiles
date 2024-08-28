#include QMK_KEYBOARD_H

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
const key_override_t ctrl_opt_backspace_key_override = ko_make_basic(MOD_BIT_LCTRL | MOD_BIT_LALT, KC_H, LCA(KC_BSPC));

const key_override_t ctrl_opt_right_key_override = ko_make_basic(MOD_BIT_RCTRL | MOD_BIT_RALT, LSFT_T(KC_F), LCA(KC_RIGHT));
const key_override_t ctrl_opt_left_key_override = ko_make_basic(MOD_BIT_RCTRL | MOD_BIT_RALT, KC_B, LCA(KC_LEFT));
const key_override_t ctrl_opt_delete_key_override = ko_make_basic(MOD_BIT_RCTRL | MOD_BIT_RALT, LCMD_T(KC_D), LCA(KC_DEL));

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
};

const uint16_t PROGMEM keymaps[][MATRIX_ROWS][MATRIX_COLS] = {
  // BASE
	[0] = LAYOUT_all(
		KC_NO,          KC_NO,        KC_NO,        KC_NO,        KC_NO,        KC_NO,        KC_NO, KC_NO,        KC_NO,        KC_NO,        KC_NO,           KC_NO,         KC_NO, KC_NO, KC_NO,
		KC_TAB,         KC_Q,         KC_W,         KC_E,         KC_R,         KC_T,         KC_Y,  KC_U,         KC_I,         KC_O,         KC_P,            KC_LBRC,       KC_NO, KC_NO,
		HYPR_T(KC_ESC), LCTL_T(KC_A), LOPT_T(KC_S), LCMD_T(KC_D), LSFT_T(KC_F), KC_G,         KC_H,  RSFT_T(KC_J), RCMD_T(KC_K), ROPT_T(KC_L), RCTL_T(KC_SCLN), KC_QUOT,       KC_NO,
		LT(5, KC_GRV),  KC_Z,         KC_X,         KC_C,         KC_V,         KC_B,         KC_N,  KC_M,         KC_COMM,      KC_DOT,       KC_SLSH,         LT(6, KC_EQL), KC_NO,
		KC_NO,          KC_LOPT,      KC_LGUI,                                  LT(9, KC_SPC),                                   KC_RGUI,      KC_ROPT,         KC_NO,         KC_NO),

	// SHIFT
	[5] = LAYOUT_all(
		KC_NO,   KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO,   KC_NO,   KC_NO,      KC_NO,     KC_NO,      KC_NO,      KC_NO,  KC_NO, KC_NO,
		KC_NO,   KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, S(KC_Y), S(KC_U), S(KC_I),    S(KC_O),   S(KC_P),    S(KC_LBRC), KC_NO,  KC_NO,
		CW_TOGG, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, S(KC_H), S(KC_J), S(KC_K),    S(KC_L),   S(KC_SCLN), S(KC_QUOT), KC_NO,
		KC_NO,   KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, S(KC_N), S(KC_M), S(KC_COMM), S(KC_DOT), S(KC_SLSH), KC_PPLS,    KC_NO,
		KC_NO,   MO(7), KC_LGUI,             KC_NO,                               KC_NO,     KC_NO,      KC_NO,      KC_NO),
	[6] = LAYOUT_all(
		KC_NO,    KC_NO,   KC_NO,   KC_NO,   KC_NO,   KC_NO,   KC_NO, KC_NO, KC_NO, KC_NO,   KC_NO, KC_NO, KC_NO, KC_NO, KC_NO,
		KC_NO,    S(KC_Q), S(KC_W), S(KC_E), S(KC_R), S(KC_T), KC_NO, KC_NO, KC_NO, KC_NO,   KC_NO, KC_NO, KC_NO, KC_NO,
		CW_TOGG,  S(KC_A), S(KC_S), S(KC_D), S(KC_F), S(KC_G), KC_NO, KC_NO, KC_NO, KC_NO,   KC_NO, KC_NO, KC_NO,
		KC_TILDE, S(KC_Z), S(KC_X), S(KC_C), S(KC_V), S(KC_B), KC_NO, KC_NO, KC_NO, KC_NO,   KC_NO, KC_NO, KC_NO,
		KC_NO,    KC_NO,   KC_NO,                     KC_NO,                        KC_RGUI, MO(8), KC_NO, KC_NO),

	// BACKSPACE
	[9] = LAYOUT_all(
		KC_NO, KC_NO,   KC_NO, KC_NO,   KC_NO,   KC_NO,   KC_NO,   KC_NO,   KC_NO,   KC_NO,   KC_NO,   KC_NO,    KC_NO,  KC_NO, KC_NO,
		KC_NO, KC_EXLM, KC_AT, KC_HASH, KC_DLR,  KC_PERC, KC_CIRC, KC_AMPR, KC_ASTR, KC_LPRN, KC_RPRN, KC_UNDS,  KC_NO,  KC_NO,
		KC_NO, KC_P1,   KC_P2, KC_P3,   KC_P4,   KC_P5,   KC_P6,   KC_P7,   KC_P8,   KC_P9,   KC_P0,   KC_MINUS, KC_NO,
		KC_NO, KC_BSLS, KC_NO, KC_NO,   KC_PIPE, KC_BRIU, KC_BRID, KC_MUTE, KC_VOLD, KC_VOLU, KC_MPLY, KC_NO,    KC_NO,
		KC_NO, KC_LALT, KC_LGUI,                 KC_SPC,                             KC_RGUI, KC_RALT, KC_NO,    KC_NO),

};

uint16_t get_quick_tap_term(uint16_t keycode, keyrecord_t *record) {
    switch (keycode) {
        case LT(9, KC_SPC):
            return 0;
        default:
            return QUICK_TAP_TERM;
    }
}

bool get_hold_on_other_key_press(uint16_t keycode, keyrecord_t *record) {
    switch (keycode) {
        case LT(5, KC_GRV):
            return true;
        case LT(6, KC_EQL):
            return true;
        default:
            return false;
    }
}
