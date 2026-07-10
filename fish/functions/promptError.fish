function promptError
    set -l prompt (set_color red)"✗ $argv[1] "
    set -l user_input (read -n 1 -P "$prompt" -s)

    echo -en "\033[2A"
    if test -n "$user_input"
        commandline -r $user_input
    end
    commandline -f repaint
end
