function open_history_search
    set -l history_list (history)
    set -l history_lines (math (count $history_list) + 3)

    set -l term_lines $LINES
    if not set -q term_lines[1]
        set term_lines (tput lines)
    end

    set -l gum_lines (math "max(1, min($history_lines, $term_lines - 3))")

    set -l selected_command (printf '%s\n' $history_list | fish_indent --ansi | ~/.gum/gum filter --placeholder="" --prompt="→ " --prompt.foreground 2 --indicator '▌' --indicator.foreground 4 --match.foreground 4 --height $gum_lines | string replace -ra '\e\\[[0-9;]*m' '')

    if test -n "$selected_command"
        commandline -r $selected_command
    end

    commandline -f repaint
end
