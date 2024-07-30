function open_history_search
    # Use history command to get the command history, reverse it, and pass it to fzf for filtering
    set selected_command (history | fzf --query "$argv")

    # If a command was selected, execute it
    if test -n "$selected_command"
        eval $selected_command
    end
    commandline -f repaint
end
