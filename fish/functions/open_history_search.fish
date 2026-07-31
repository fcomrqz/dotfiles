function open_history_search
    set -l history_list (history)
    test (count $history_list) -gt 0; or return

    set -l term_lines $LINES
    if not set -q term_lines[1]
        set term_lines 24
    end
    set -l filter_height (math "max(1, min("(count $history_list)", $term_lines - 3))")
    set -l styled_history (printf '%s\n' $history_list | fish_indent --ansi)
    set -l selected_command (__gum_filter --height $filter_height -- $styled_history)
    set -l filter_status $status

    if test $filter_status -eq 0 -a -n "$selected_command"
        commandline -r -- "$selected_command"
    end
    commandline -f repaint
end
