#!/bin/sh
# shellcheck disable=SC2016
# shellcheck source-path=SCRIPTDIR

set -u

action="${1:-}"
script_dir="$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)"

# shellcheck source=focus-lib.sh
. "$script_dir/focus-lib.sh"

focus_resolve_tools || exit 1
focus_ensure_state_dir || exit 1

store_window_metadata() {
    store_window_id="$1"
    store_window_json="$(
        "$FOCUS_YABAI_BIN" -m query --windows --window \
            "$store_window_id" 2>/dev/null
    )" || return 1

    store_window_details="$(
        printf '%s\n' "$store_window_json" |
            "$FOCUS_JQ_BIN" -L "$FOCUS_JQ_LIB" -r \
                'include "focus-window";
                [
                    yabai_is_focus_window,
                    .display,
                    .space,
                    (."is-native-fullscreen" // false)
                ]
                | @tsv'
    )"
    [ -n "$store_window_details" ] || return 1
    IFS='	' read -r \
        store_is_eligible \
        store_display_index \
        store_space_index \
        store_window_native <<EOF
$store_window_details
EOF

    if [ "$store_is_eligible" != true ]; then
        forget_window "$store_window_id"
        return 1
    fi

    store_display_key="$(focus_display_key "$store_display_index")"
    [ -n "$store_display_key" ] || return 1

    store_space_native="$(
        "$FOCUS_YABAI_BIN" -m query --spaces --space \
            "$store_space_index" 2>/dev/null |
            "$FOCUS_JQ_BIN" -r '."is-native-fullscreen" // false'
    )"
    if [ "$store_space_native" = false ]; then
        store_kind=normal
    elif [ "$store_window_native" = true ]; then
        store_kind=native
    else
        store_kind=other
    fi

    focus_atomic_write \
        "$FOCUS_STATE_DIR/windows/$store_window_id" \
        "$store_display_key	$store_display_index	$store_space_index	$store_kind"
}

snapshot_display() {
    snapshot_display_index="$1"
    snapshot_display_key="$(focus_display_key "$snapshot_display_index")"
    [ -n "$snapshot_display_key" ] || return 1

    snapshot_normal_space="$(focus_normal_space "$snapshot_display_index")"
    if [ -z "$snapshot_normal_space" ]; then
        focus_atomic_write \
            "$FOCUS_STATE_DIR/displays/$snapshot_display_key.order" ""
        return 0
    fi

    snapshot_ordered_windows="$(
        "$FOCUS_YABAI_BIN" -m query --windows 2>/dev/null |
            "$FOCUS_JQ_BIN" -L "$FOCUS_JQ_LIB" -c \
                --argjson display "$snapshot_display_index" \
                --argjson space "$snapshot_normal_space" \
                'include "focus-window";
                [
                    .[]
                    | select(
                        .display == $display
                        and .space == $space
                        and yabai_is_visible_normal_window
                    )
                ]
                | sort_by(.frame.y, .frame.x, .id)'
    )"
    snapshot_order="$(
        printf '%s\n' "$snapshot_ordered_windows" |
            "$FOCUS_JQ_BIN" -r '.[].id'
    )"

    focus_atomic_write \
        "$FOCUS_STATE_DIR/displays/$snapshot_display_key.order" \
        "$snapshot_order"

    printf '%s\n' "$snapshot_ordered_windows" |
        "$FOCUS_JQ_BIN" -r \
            'to_entries
            | . as $entries
            | .[]
            | .key as $position
            | [
                .value.id,
                (
                    if $position > 0
                    then $entries[$position - 1].value.id
                    else "-"
                    end
                ),
                (
                    if ($position + 1) < ($entries | length)
                    then $entries[$position + 1].value.id
                    else "-"
                    end
                )
            ]
            | @tsv' |
        while IFS='	' read -r \
            snapshot_window_id \
            snapshot_previous_window \
            snapshot_next_window
        do
            focus_atomic_write \
                "$FOCUS_STATE_DIR/windows/$snapshot_window_id.neighbors" \
                "$snapshot_previous_window	$snapshot_next_window"
        done
}

record_window() {
    record_window_id="$1"
    store_window_metadata "$record_window_id" || return 0

    IFS='	' read -r \
        record_display_key \
        record_display_index \
        record_space_index \
        record_kind \
        <"$FOCUS_STATE_DIR/windows/$record_window_id"
    : "$record_space_index"

    case "$record_kind" in
        normal)
            focus_atomic_write \
                "$FOCUS_STATE_DIR/displays/$record_display_key.candidate" \
                "$record_window_id"
            focus_atomic_write \
                "$FOCUS_STATE_DIR/displays/$record_display_key.normal" \
                "$record_window_id"
            ;;
        native)
            focus_atomic_write \
                "$FOCUS_STATE_DIR/displays/$record_display_key.candidate" \
                "$record_window_id"
            ;;
        other) ;;
    esac

    : "$record_display_index"
}

forget_window() {
    forget_window_id="$1"

    for forget_memory_file in \
        "$FOCUS_STATE_DIR"/displays/*.candidate \
        "$FOCUS_STATE_DIR"/displays/*.normal
    do
        [ -f "$forget_memory_file" ] || continue
        forget_remembered_id="$(sed -n '1p' "$forget_memory_file")"
        if [ "$forget_remembered_id" = "$forget_window_id" ]; then
            rm -f "$forget_memory_file"
        fi
    done

    rm -f \
        "$FOCUS_STATE_DIR/windows/$forget_window_id" \
        "$FOCUS_STATE_DIR/windows/$forget_window_id.neighbors"
}

relocate_window() {
    relocate_window_id="$1"
    relocate_source_display="$2"

    forget_window "$relocate_window_id"
    snapshot_display "$relocate_source_display" || true
    record_window "$relocate_window_id" || return 1

    IFS='	' read -r \
        relocate_display_key \
        relocate_display_index \
        relocate_space_index \
        relocate_kind \
        <"$FOCUS_STATE_DIR/windows/$relocate_window_id"
    : "$relocate_space_index" "$relocate_kind"

    snapshot_display "$relocate_display_index" || true
    focus_remember_display \
        "$relocate_display_key" \
        "$relocate_display_index"
}

case "$action" in
    record)
        window_id="${2:-}"
        focus_is_number "$window_id" || exit 0
        record_window "$window_id"
        ;;
    snapshot-window)
        window_id="${2:-}"
        focus_is_number "$window_id" || exit 0
        store_window_metadata "$window_id" || exit 0
        IFS='	' read -r \
            display_key \
            display_index \
            space_index \
            window_kind \
            <"$FOCUS_STATE_DIR/windows/$window_id"
        : "$display_key" "$space_index" "$window_kind"
        snapshot_display "$display_index"
        ;;
    debounce-window-moved)
        window_id="${2:-}"
        focus_is_number "$window_id" || exit 0
        debounce_delay="${YABAI_SNAPSHOT_DEBOUNCE_DELAY:-0.05}"
        debounce_token="$$:$window_id"
        debounce_file="$FOCUS_STATE_DIR/window-moved.token"
        focus_atomic_write "$debounce_file" "$debounce_token" || exit 0
        (
            sleep "$debounce_delay"
            current_token="$(sed -n '1p' "$debounce_file" 2>/dev/null)"
            [ "$current_token" = "$debounce_token" ] || exit 0
            "$script_dir/focus-memory.sh" snapshot-window "$window_id" \
                >/dev/null 2>&1 || true
        ) >/dev/null 2>&1 &
        ;;
    snapshot-display)
        display_index="${2:-}"
        focus_is_number "$display_index" || exit 0
        snapshot_display "$display_index"
        ;;
    sync)
        focused_window="$(
            "$FOCUS_YABAI_BIN" -m query --windows 2>/dev/null |
                "$FOCUS_JQ_BIN" -r \
                    '.[] | select(."has-focus") | .id' |
                head -n 1
        )"
        focus_is_number "$focused_window" && record_window "$focused_window"
        ;;
    seed)
        seed_windows_json="$(
            "$FOCUS_YABAI_BIN" -m query --windows 2>/dev/null
        )" || seed_windows_json='[]'
        seed_eligible_ids="$(
            printf '%s\n' "$seed_windows_json" |
                "$FOCUS_JQ_BIN" -L "$FOCUS_JQ_LIB" -r \
                    'include "focus-window";
                    .[]
                    | select(yabai_is_focus_window)
                    | .id'
        )"

        # State survives service reloads. Remove metadata and remembered focus
        # for windows that disappeared or are no longer eligible.
        for seed_window_file in "$FOCUS_STATE_DIR"/windows/*; do
            [ -f "$seed_window_file" ] || continue
            seed_window_name="${seed_window_file##*/}"
            seed_window_id="${seed_window_name%.neighbors}"
            focus_is_number "$seed_window_id" || continue
            if ! printf '%s\n' "$seed_eligible_ids" |
                grep -Fx "$seed_window_id" >/dev/null
            then
                forget_window "$seed_window_id"
            fi
        done

        printf '%s\n' "$seed_eligible_ids" |
            while IFS= read -r window_id; do
                focus_is_number "$window_id" || continue
                store_window_metadata "$window_id" || true
            done

        "$FOCUS_YABAI_BIN" -m query --displays 2>/dev/null |
            "$FOCUS_JQ_BIN" -r '.[].index' |
            while IFS= read -r display_index; do
                snapshot_display "$display_index" || true
            done

        focused_display="$(
            "$FOCUS_YABAI_BIN" -m query --displays 2>/dev/null |
                "$FOCUS_JQ_BIN" -r \
                    '.[] | select(."has-focus") | .index' |
                head -n 1
        )"
        if focus_is_number "$focused_display"; then
            focused_display_key="$(focus_display_key "$focused_display")"
            if [ -n "$focused_display_key" ]; then
                focus_atomic_write \
                    "$FOCUS_STATE_DIR/active-display" \
                    "$focused_display_key	$focused_display"
            fi
        fi

        focused_window="$(
            "$FOCUS_YABAI_BIN" -m query --windows 2>/dev/null |
                "$FOCUS_JQ_BIN" -r \
                    '.[] | select(."has-focus") | .id' |
                head -n 1
        )"
        focus_is_number "$focused_window" && record_window "$focused_window"
        ;;
    get)
        display_index="${2:-}"
        memory_kind="${3:-}"
        focus_is_number "$display_index" || exit 0
        case "$memory_kind" in
            candidate | normal) ;;
            *) exit 0 ;;
        esac
        display_key="$(focus_display_key "$display_index")"
        [ -n "$display_key" ] || exit 0
        memory_file="$FOCUS_STATE_DIR/displays/$display_key.$memory_kind"
        [ -f "$memory_file" ] && sed -n '1p' "$memory_file"
        ;;
    set-active-display)
        display_index="${2:-}"
        focus_is_number "$display_index" || exit 0
        display_key="$(focus_display_key "$display_index")"
        [ -n "$display_key" ] || exit 0
        focus_atomic_write \
            "$FOCUS_STATE_DIR/active-display" \
            "$display_key	$display_index"
        ;;
    get-active-display)
        active_display_file="$FOCUS_STATE_DIR/active-display"
        [ -f "$active_display_file" ] || exit 0
        IFS='	' read -r \
            remembered_display_key \
            remembered_display_index \
            <"$active_display_file"
        focus_is_number "$remembered_display_key" || exit 0
        focus_is_number "$remembered_display_index" || exit 0
        current_display_key="$(
            focus_display_key "$remembered_display_index"
        )"
        if [ "$current_display_key" = "$remembered_display_key" ]; then
            printf '%s\n' "$remembered_display_index"
        else
            rm -f "$active_display_file"
        fi
        ;;
    metadata)
        window_id="${2:-}"
        focus_is_number "$window_id" || exit 0
        metadata_file="$FOCUS_STATE_DIR/windows/$window_id"
        [ -f "$metadata_file" ] && sed -n '1p' "$metadata_file"
        ;;
    neighbors)
        window_id="${2:-}"
        focus_is_number "$window_id" || exit 0
        neighbors_file="$FOCUS_STATE_DIR/windows/$window_id.neighbors"
        [ -f "$neighbors_file" ] && sed -n '1p' "$neighbors_file"
        ;;
    order)
        display_key="${2:-}"
        case "$display_key" in
            '' | *[!0-9]*) exit 0 ;;
        esac
        order_file="$FOCUS_STATE_DIR/displays/$display_key.order"
        [ -f "$order_file" ] && sed '/^$/d' "$order_file"
        ;;
    forget)
        window_id="${2:-}"
        focus_is_number "$window_id" || exit 0
        forget_window "$window_id"
        ;;
    relocate)
        window_id="${2:-}"
        source_display="${3:-}"
        focus_is_number "$window_id" || exit 0
        focus_is_number "$source_display" || exit 0
        relocate_window "$window_id" "$source_display"
        ;;
    *)
        printf '%s\n' \
            'Usage: focus-memory.sh record|snapshot-window|debounce-window-moved|snapshot-display|sync|seed|get|set-active-display|get-active-display|metadata|neighbors|order|forget|relocate [...]' \
            >&2
        exit 1
        ;;
esac

exit 0
