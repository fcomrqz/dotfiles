#!/bin/sh
# shellcheck disable=SC2016

set -eu

state_file="${MOCK_YABAI_STATE:?MOCK_YABAI_STATE is required}"
log_file="${MOCK_YABAI_LOG:?MOCK_YABAI_LOG is required}"
jq_bin="${JQ_BIN:-/opt/homebrew/bin/jq}"

[ "${1:-}" = -m ] || exit 1
shift

printf '%s\n' "$*" >>"$log_file"

write_state() {
    update_filter="$1"
    update_tmp="$(mktemp "${state_file}.tmp.XXXXXX")"
    "$jq_bin" "$update_filter" "$state_file" >"$update_tmp"
    mv -f "$update_tmp" "$state_file"
}

domain="${1:-}"
shift || true

case "$domain" in
    query)
        collection="${1:-}"
        shift || true
        case "$collection" in
            --displays)
                "$jq_bin" '.displays' "$state_file"
                ;;
            --spaces)
                if [ "${1:-}" = --space ]; then
                    selector="${2:-}"
                    "$jq_bin" --arg selector "$selector" \
                        '.spaces[]
                        | select(
                            (.index | tostring) == $selector
                            or .label == $selector
                        )' \
                        "$state_file"
                else
                    "$jq_bin" '.spaces' "$state_file"
                fi
                ;;
            --windows)
                if [ "${1:-}" = --window ]; then
                    selector="${2:-}"
                    if [ -n "$selector" ]; then
                        "$jq_bin" --argjson window "$selector" \
                            '.windows[] | select(.id == $window)' \
                            "$state_file"
                    else
                        "$jq_bin" \
                            '.windows[] | select(."has-focus" == true)' \
                            "$state_file"
                    fi
                else
                    "$jq_bin" '.windows' "$state_file"
                fi
                ;;
            *)
                exit 1
                ;;
        esac
        ;;
    space)
        selector="${1:-}"
        command="${2:-}"
        target="${3:-}"
        if [ "$selector" != --focus ]; then
            exit 0
        fi
        [ "$command" ] && [ -z "$target" ] || exit 1
        write_state \
            ".spaces as \$spaces
            | (\$spaces[] | select(.index == $command)) as \$target
            | .spaces |= map(.\"has-focus\" = (.index == $command))
            | .displays |= map(.\"has-focus\" = (.index == \$target.display))
            | .windows |= map(.\"has-focus\" = false)"
        ;;
    display)
        selector="${1:-}"
        target="${2:-}"
        [ "$selector" = --focus ] || exit 1
        if [ "${MOCK_IGNORE_DISPLAY_FOCUS:-0}" = 1 ]; then
            exit 0
        fi
        write_state \
            ".displays |= map(.\"has-focus\" = (.index == $target))"
        ;;
    window)
        window_id="${1:-}"
        command="${2:-}"
        argument="${3:-}"
        following_command="${4:-}"
        case "$command" in
            --focus)
                write_state \
                    "(.windows[] | select(.id == $window_id)) as \$target
                    | .windows |= map(.\"has-focus\" = (.id == $window_id))
                    | .spaces |= map(.\"has-focus\" = (.index == \$target.space))
                    | .displays |= map(.\"has-focus\" = (.index == \$target.display))"
                ;;
            --space)
                if [ "${MOCK_FAIL_WINDOW_SPACE:-0}" = 1 ]; then
                    exit 1
                fi
                if ! "$jq_bin" -e --argjson space "$argument" \
                    'any(.spaces[]; .index == $space)' \
                    "$state_file" >/dev/null
                then
                    exit 1
                fi
                write_state \
                    "(.spaces[] | select(.index == $argument)) as \$target
                    | .windows |= map(
                        if .id == $window_id
                        then .space = $argument
                            | .display = \$target.display
                            | .\"is-native-fullscreen\" = false
                            | .\"can-move\" = true
                        else .
                        end
                    )
                    | if \"$following_command\" == \"--focus\"
                      then .windows |= map(
                               .\"has-focus\" = (.id == $window_id)
                           )
                           | .spaces |= map(
                               .\"has-focus\" = (.index == $argument)
                           )
                           | .displays |= map(
                               .\"has-focus\" = (.index == \$target.display)
                           )
                      else .
                      end"
                ;;
            --toggle)
                [ "$argument" = native-fullscreen ] || exit 1
                is_native="$(
                    "$jq_bin" -r --argjson window "$window_id" \
                        '.windows[]
                        | select(.id == $window)
                        | ."is-native-fullscreen"' \
                        "$state_file"
                )"
                if [ "$is_native" = true ]; then
                    write_state \
                        "(.windows[] | select(.id == $window_id)) as \$window
                        | (
                            [
                                .spaces[]
                                | select(
                                    .display == \$window.display
                                    and .\"is-native-fullscreen\" == false
                                )
                            ]
                            | sort_by(.index)
                            | .[0]
                          ) as \$normal
                        | .windows |= map(
                            if .id == $window_id
                            then .space = \$normal.index
                                | .display = \$normal.display
                                | .\"is-native-fullscreen\" = false
                                | .\"can-move\" = true
                            else .
                            end
                          )
                        | .spaces |= map(
                            select(.index != \$window.space)
                            | .\"has-focus\" = (.index == \$normal.index)
                          )
                        | .displays |= map(
                            .\"has-focus\" = (.index == \$normal.display)
                          )"
                else
                    write_state \
                        "(.windows[] | select(.id == $window_id)) as \$window
                        | (([.spaces[].index] | max) + 1) as \$new_space
                        | .spaces |= map(.\"has-focus\" = false)
                        | .spaces += [{
                            \"id\": (600 + \$new_space),
                            \"index\": \$new_space,
                            \"label\": \"\",
                            \"display\": \$window.display,
                            \"has-focus\": true,
                            \"is-native-fullscreen\": true
                          }]
                        | .windows |= map(
                            if .id == $window_id
                            then .space = \$new_space
                                | .\"is-native-fullscreen\" = true
                                | .\"can-move\" = false
                                | .\"has-focus\" = true
                            else .\"has-focus\" = false
                            end
                          )
                        | .displays |= map(
                            .\"has-focus\" = (.index == \$window.display)
                          )"
                fi
                ;;
            *)
                exit 1
                ;;
        esac
        ;;
    config | rule | signal)
        exit 0
        ;;
    *)
        exit 1
        ;;
esac
