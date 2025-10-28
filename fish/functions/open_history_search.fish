function open_history_search
    set -l history_list (history)
    set -l history_lines (math (count $history_list) + 3)

    set -l term_lines (tput lines)

    set -l gum_lines
    if test $history_lines -gt $term_lines
        set gum_lines $term_lines
    else
        set gum_lines $history_lines
    end

    set gum_lines (math "max(1, min($gum_lines, $term_lines - 3))")

    set -l selected_command (printf '%s\n' $history | fish_indent --ansi | ~/.gum/gum filter --placeholder="" --prompt="→ " --prompt.foreground 2 --indicator '▌' --indicator.foreground 4 --match.foreground 4 --height $gum_lines)

    if test -n "$selected_command"
        commandline -r $selected_command
    end

    commandline -f repaint
end
