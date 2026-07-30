# Shared window classification for focus, placement, and memory.
#
# Yabai manages root AXStandardWindow windows at the normal window level when
# they can move. Native-fullscreen windows temporarily report can-move=false,
# so they are a separate eligible class.

def yabai_has_standard_role:
    .role == "AXWindow"
    and .subrole == "AXStandardWindow"
    and ."root-window" == true;

def yabai_has_normal_level:
    # The default keeps recorded test fixtures and older query snapshots
    # compatible. Current Yabai always reports the level field.
    (.level // 0) == 0;

def yabai_can_move:
    if has("can-move")
    then ."can-move" == true
    else true
    end;

def yabai_can_resize:
    if has("can-resize")
    then ."can-resize" == true
    else true
    end;

def yabai_is_native_fullscreen:
    (."is-native-fullscreen" // false) == true;

def yabai_is_normal_window:
    yabai_has_standard_role
    and yabai_has_normal_level
    and (yabai_is_native_fullscreen | not)
    and yabai_can_move;

def yabai_is_native_fullscreen_window:
    yabai_has_standard_role
    and yabai_has_normal_level
    and yabai_is_native_fullscreen;

def yabai_is_focus_window:
    yabai_is_normal_window or yabai_is_native_fullscreen_window;

def yabai_is_visible_focus_window:
    yabai_is_focus_window
    and (."is-minimized" // false) == false
    and (."is-hidden" // false) == false;

def yabai_is_visible_normal_window:
    yabai_is_normal_window
    and (."is-minimized" // false) == false
    and (."is-hidden" // false) == false;

# Dialogs remain real macOS windows, but do not participate in this setup's
# normal/native-fullscreen focus cycle.
def yabai_is_dialog_window:
    .role == "AXWindow"
    and ."root-window" == true
    and yabai_has_normal_level
    and .subrole != "AXStandardWindow";

def yabai_should_float_as_dialog:
    yabai_is_dialog_window
    or (yabai_is_normal_window and (yabai_can_resize | not));

def yabai_is_move_window:
    yabai_is_normal_window
    or yabai_is_native_fullscreen_window
    or (yabai_is_dialog_window and yabai_can_move);

# Everything outside the three explicit classes is an auxiliary popup or an
# otherwise ineligible window. It must not be relocated or remembered.
def yabai_is_popup_window:
    (
        yabai_is_normal_window
        or yabai_is_native_fullscreen_window
        or yabai_is_dialog_window
    )
    | not;
