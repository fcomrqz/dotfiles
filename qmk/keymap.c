// https://docs.qmk.fm/keycodes

#include QMK_KEYBOARD_H

const uint16_t PROGMEM keymaps[][MATRIX_ROWS][MATRIX_COLS] = {

	[0] = LAYOUT_all(
		KC_NO,          KC_NO,       KC_NO,       KC_NO,       KC_NO,       KC_NO, KC_NO, KC_NO,       KC_NO,       KC_NO,       KC_NO,          KC_NO,         KC_NO,  KC_NO, KC_NO,
		KC_TAB,         KC_Q,        KC_W,        KC_E,        KC_R,        KC_T,  KC_Y,  KC_U,        KC_I,        KC_O,        KC_P,           KC_LBRC,       KC_NO,  KC_NO,
		HYPR_T(KC_ESC), LT(1, KC_A), LT(3, KC_S), CMD_T(KC_D), SFT_T(KC_F), KC_G,  KC_H,  SFT_T(KC_J), CMD_T(KC_K), LT(4, KC_L), LT(2, KC_SCLN), KC_QUOT,       KC_NO,
		LT(5, KC_GRV),  KC_Z,        KC_X,        KC_C,        KC_V,        KC_B,  KC_N,  KC_M,        KC_COMM,     KC_DOT,      KC_SLSH,        LT(6, KC_EQL), KC_NO,
		KC_NO,          MO(3),       KC_LGUI,                               LT(9, KC_SPC),                          KC_RGUI,     MO(4),          KC_NO,         KC_NO),

	[1] = LAYOUT_all(
		KC_NO, KC_NO, KC_NO,   KC_NO,   KC_NO,   KC_NO, KC_NO,   KC_NO,   KC_NO,      KC_NO,     KC_NO,      KC_NO,      KC_NO,  KC_NO, KC_NO,
		KC_NO, KC_NO, KC_NO,   KC_NO,   KC_NO,   KC_NO, C(KC_Y), C(KC_U), C(KC_I),    C(KC_O),   KC_UP,      C(KC_LBRC), KC_NO,  KC_NO,
		KC_NO, KC_NO, KC_LALT, KC_LGUI, KC_LSFT, KC_NO, KC_BSPC, KC_ENT,  C(KC_K),    C(KC_L),   C(KC_SCLN), C(KC_QUOT), KC_NO,
		KC_NO, KC_NO, KC_NO,   KC_NO,   KC_NO,   KC_NO, KC_DOWN, C(KC_M), C(KC_COMM), C(KC_DOT), C(KC_SLSH), KC_NO,      KC_NO,
		KC_NO, KC_NO, KC_NO,                     C(KC_SPC),                           KC_NO,     KC_NO,      KC_NO,      KC_NO),

	[2] = LAYOUT_all(
		KC_NO, KC_NO,   KC_NO,   KC_NO,   KC_NO,    KC_NO,   KC_NO, KC_NO,   KC_NO,   KC_NO,   KC_NO, KC_NO, KC_NO, KC_NO, KC_NO,
		KC_NO, C(KC_Q), C(KC_W), C(KC_E), C(KC_R),  C(KC_T), KC_NO, KC_NO,   KC_NO,   KC_NO,   KC_NO, KC_NO, KC_NO, KC_NO,
		KC_NO, C(KC_A), C(KC_S), KC_DEL,  KC_RIGHT, C(KC_G), KC_NO, KC_RSFT, KC_LGUI, KC_LALT, KC_NO, KC_NO, KC_NO,
		KC_NO, C(KC_Z), C(KC_X), C(KC_C), C(KC_V),  KC_LEFT, KC_NO, KC_NO,   KC_NO,   KC_NO,   KC_NO, KC_NO, KC_NO,
		KC_NO, KC_NO, KC_NO,                        C(KC_SPC),                        KC_NO,   KC_NO, KC_NO, KC_NO),

	[3] = LAYOUT_all(
		KC_NO,     KC_NO,   KC_NO,   KC_NO,   KC_NO,   KC_NO, KC_NO,      KC_NO,   KC_NO,      KC_NO,     KC_NO,      KC_NO,      KC_NO,  KC_NO, KC_NO,
		A(KC_TAB), KC_NO,   KC_NO,   KC_NO,   KC_NO,   KC_NO, A(KC_Y),    A(KC_U), A(KC_I),    A(KC_O),   KC_PGUP,    KC_RBRC,    KC_NO,  KC_NO,
		KC_NO,     KC_LCTL, KC_NO,   KC_LGUI, KC_LSFT, KC_NO, A(KC_BSPC), KC_ENT,  A(KC_K),    A(KC_L),   A(KC_SCLN), A(KC_QUOT), KC_NO,
		MO(7),     KC_NO,   KC_NO,   KC_NO,   KC_NO,   KC_NO, KC_PGDN,    A(KC_M), A(KC_COMM), A(KC_DOT), A(KC_SLSH), A(KC_SLSH), KC_NO,
		KC_NO,     KC_NO,   KC_LGUI,                   A(KC_SPC),                              KC_NO,     KC_NO,      KC_NO,      KC_NO),

	[4] = LAYOUT_all(
		KC_NO,     KC_NO,   KC_NO,   KC_NO,     KC_NO,       KC_NO,      KC_NO, KC_NO,   KC_NO,   KC_NO,   KC_NO,   KC_NO,   KC_NO, KC_NO, KC_NO,
		A(KC_TAB), A(KC_Q), A(KC_W), A(KC_E),   A(KC_R),     A(KC_T),    KC_NO, KC_NO,   KC_NO,   KC_NO,   KC_NO,   KC_NO,   KC_NO, KC_NO,
		KC_NO,     A(KC_A), A(KC_S), A(KC_DEL), A(KC_RIGHT), A(KC_G),    KC_NO, KC_RSFT, KC_LGUI, KC_NO,   KC_RCTL, KC_NO,   KC_NO,
		KC_NO,     A(KC_Z), A(KC_X), A(KC_C),   A(KC_V),     A(KC_LEFT), KC_NO, KC_NO,   KC_NO,   KC_NO,   KC_NO,   MO(8),   KC_NO,
		KC_NO,     KC_NO,   KC_NO,                           A(KC_SPC),                           KC_RGUI, KC_NO,   KC_NO,   KC_NO),

	[5] = LAYOUT_all(
		KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO,   KC_NO,   KC_NO,      KC_NO,     KC_NO,      KC_NO,      KC_NO,  KC_NO, KC_NO,
		KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, S(KC_Y), S(KC_U), S(KC_I),    S(KC_O),   S(KC_P),    S(KC_LBRC), KC_NO,  KC_NO,
		KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, S(KC_H), S(KC_J), S(KC_K),    S(KC_L),   S(KC_SCLN), S(KC_QUOT), KC_NO,
		KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, S(KC_N), S(KC_M), S(KC_COMM), S(KC_DOT), S(KC_SLSH), KC_PPLS,    KC_NO,
		KC_NO, MO(7), KC_LGUI,             KC_NO,                               KC_NO,     KC_NO,      KC_NO,      KC_NO),

	[6] = LAYOUT_all(
		KC_NO,    KC_NO,   KC_NO,   KC_NO,   KC_NO,   KC_NO,   KC_NO, KC_NO, KC_NO, KC_NO,   KC_NO, KC_NO, KC_NO, KC_NO, KC_NO,
		KC_NO,    S(KC_Q), S(KC_W), S(KC_E), S(KC_R), S(KC_T), KC_NO, KC_NO, KC_NO, KC_NO,   KC_NO, KC_NO, KC_NO, KC_NO,
		KC_NO,    S(KC_A), S(KC_S), S(KC_D), S(KC_F), S(KC_G), KC_NO, KC_NO, KC_NO, KC_NO,   KC_NO, KC_NO, KC_NO,
		KC_TILDE, S(KC_Z), S(KC_X), S(KC_C), S(KC_V), S(KC_B), KC_NO, KC_NO, KC_NO, KC_NO,   KC_NO, KC_NO, KC_NO,
		KC_NO,    KC_NO,   KC_NO,                     KC_NO,                        KC_RGUI, MO(8), KC_NO, KC_NO),

	[7] = LAYOUT_all(
		KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO,      KC_NO,     KC_NO,        KC_NO,       KC_NO,        KC_NO,        KC_NO,  KC_NO, KC_NO,
		KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, RSA(KC_Y),  RSA(KC_U), RSA(KC_I),    RSA(KC_O),   S(KC_UP),     S(KC_RBRC),   KC_NO,  KC_NO,
		KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, RSA(KC_H),  RSA(KC_J), RSA(KC_K),    RSA(KC_L),   RSA(KC_SCLN), RSA(KC_QUOT), KC_NO,
		KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, S(KC_DOWN), RSA(KC_M), RSA(KC_COMM), RSA(KC_DOT), RSA(KC_SLSH), KC_NO,        KC_NO,
		KC_NO, KC_NO, KC_LGUI,             KC_NO,                                      KC_NO,       KC_NO,        KC_NO,        KC_NO),

	[8] = LAYOUT_all(
		KC_NO, KC_NO,     KC_NO,     KC_NO,     KC_NO,         KC_NO,        KC_NO, KC_NO, KC_NO, KC_NO,   KC_NO, KC_NO, KC_NO, KC_NO, KC_NO,
		KC_NO, LSA(KC_Q), LSA(KC_W), LSA(KC_E), LSA(KC_R),     LSA(KC_T),    KC_NO, KC_NO, KC_NO, KC_NO,   KC_NO, KC_NO, KC_NO, KC_NO,
		KC_NO, LSA(KC_A), LSA(KC_S), LSA(KC_D), LSA(KC_RIGHT), LSA(KC_G),    KC_NO, KC_NO, KC_NO, KC_NO,   KC_NO, KC_NO, KC_NO,
		KC_NO, LSA(KC_Z), LSA(KC_X), LSA(KC_C), LSA(KC_V),     LSA(KC_LEFT), KC_NO, KC_NO, KC_NO, KC_NO,   KC_NO, KC_NO, KC_NO,
		KC_NO, KC_NO,     KC_NO,                               KC_NO,                             KC_LGUI, KC_NO, KC_NO, KC_NO),

	[9] = LAYOUT_all(
		KC_NO, KC_NO,   KC_NO, KC_NO,   KC_NO,   KC_NO,   KC_NO,   KC_NO,   KC_NO,   KC_NO,   KC_NO,   KC_NO,    KC_NO,  KC_NO, KC_NO,
		KC_NO, KC_EXLM, KC_AT, KC_HASH, KC_DLR,  KC_PERC, KC_CIRC, KC_AMPR, KC_ASTR, KC_LPRN, KC_RPRN, KC_UNDS,  KC_NO,  KC_NO,
		KC_NO, KC_P1,   KC_P2, KC_P3,   KC_P4,   KC_P5,   KC_P6,   KC_P7,   KC_P8,   KC_P9,   KC_P0,   KC_MINUS, KC_NO,
		KC_NO, KC_BSLS, KC_NO, KC_NO,   KC_PIPE, KC_BRIU, KC_BRID, KC_MUTE, KC_VOLD, KC_VOLU, KC_MPLY, KC_NO,    KC_NO,
		KC_NO, KC_LALT, KC_LGUI,                 KC_SPC,                             KC_RGUI, KC_RALT, KC_NO,    KC_NO),

};

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
