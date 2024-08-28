function screen-windows
    set -l windows (screen -Q windows '%t ' | sed 's/screen-windows //g' | tr ' ' '\n')
    set -l selected (printf '%s\n' $windows | gum filter --placeholder "" --prompt "→ " --prompt.foreground 2 --indicator '▌' --indicator.foreground 4 --match.foreground 4)
    if test -n "$selected"
        set -l window_number (screen -Q windows '%n %t ' | sed -n "s/.*\([0-9]\) $selected.*/\1/p")
        screen -X select $window_number
        screen -p screen-windows -X kill
    end
end
