function promptConfirmation
    set -l formatted_command (echo $argv[1] | fish_indent --ansi)
    set -l prompt (set_color green)"→ "(set_color normal)"$formatted_command"(set_color brblack)"[y/N] "(set_color normal)
    read -n 1 -P "$prompt" confirmation

    if test "$confirmation" = y -o "$confirmation" = Y
        echo -en "\033[2A\033[J"

        echo (set_color green)"→ "(set_color normal)"$formatted_command"(set_color brblack)"[y/N] "(set_color normal)
        return 0
    else
        echo -en "\033[3A"
        commandline -f repaint
        return 1
    end
end
