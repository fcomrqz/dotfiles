# TODO: Check all branches to represent repository status and print if is synced

function open_project
    set projects (command find ~/Developer -type d -maxdepth 2 -mindepth 2 -exec test -d '{}/.git' ';' -print)
    set formatted_projects (
        for project in $projects
            set relative_path (string replace -r '/Users/fran/Developer/' '' $project)
            set git_status (git -C $project status -s)
            set git_ahead_behind (git -C $project rev-list --left-right --count HEAD...@{u} 2>/dev/null)
            set ahead (echo $git_ahead_behind | awk '{print $1}' | string trim)
            set behind (echo $git_ahead_behind | awk '{print $2}' | string trim)

            # Default to 0 if not a number
            if not string match -q '[0-9]*' $ahead
                set ahead 0
            end
            if not string match -q '[0-9]*' $behind
                set behind 0
            end

            set status_indicator ""
            if test -n "$git_status"
                set status_indicator (set_color yellow)"*"(set_color normal)" "
            end
            set direction_indicator ""
            if test "$ahead" -gt 0
                set direction_indicator (set_color blue)"↑"(set_color normal)" "
            else if test "$behind" -gt 0
                set direction_indicator (set_color red)"↓"(set_color normal)" "
            end
            if test -n "$git_status" -o -n "$direction_indicator"
                echo "1$relative_path $status_indicator$direction_indicator"
            else
                echo "0$relative_path"
            end
        end
    )

    set sorted_projects (
        printf "%s\n" $formatted_projects | sort -r | sed 's/^[01]//'
    )

    set selected_project (printf "%s\n" $sorted_projects | gum filter --height 6 --placeholder "" --prompt "→ " --prompt.foreground 2 --indicator.foreground 4 --match.foreground 4)

    if test -n "$selected_project"
        # Remove color codes and status indicators
        set clean_project (echo $selected_project | sed -E 's/\x1B\[[0-9;]*[mK]//g' | sed 's/[*↑↓]//g' | string trim)
        # Use the full path
        set full_path ~/Developer/$clean_project
        if test -d $full_path
            cd $full_path
        else
            echo "Directory not found: $full_path"
        end
    end

    commandline -f repaint
end
