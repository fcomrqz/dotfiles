function screen-windows
    set -l windows (screen -Q windows '%t ' | sed 's/screen-windows //g' | tr ' ' '\n')
    set -l selected (printf '%s\n' $windows | gum filter --placeholder "" --prompt "→ " --prompt.foreground 2 --indicator '▌' --indicator.foreground 4 --match.foreground 4)
    if test -n "$selected"
        # Get the full window list with numbers and titles
        set -l full_list (screen -Q windows '%n %t ')
        # Use awk to find the window number for the selected title
        set -l window_number (echo "$full_list" | awk -v title="$selected" '
            { for(i=1; i<=NF; i+=2) if($(i+1) == title) print $i }
        ')
        screen -X select $window_number
        screen -p screen-windows -X kill
    end
end
