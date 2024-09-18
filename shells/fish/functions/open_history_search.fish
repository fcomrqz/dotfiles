function open_history_search
    set selected_command (history | gum filter --placeholder="" --prompt="→ " --height 6 --prompt.foreground 2 --indicator.foreground 12 --match.foreground 12)

    if test -n "$selected_command"
        eval $selected_command
    end
    commandline -f repaint
end
