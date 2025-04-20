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

            # Get last modified timestamp
            set modified_time (
                if test -d "$project/.git"
                    # Get the most recent timestamp from changed files
                    set -l changed_files (git -C $project status --porcelain | cut -c4-)
                    if test -n "$changed_files"
                        printf "%s\n" $changed_files |
                        while read -l file
                            stat -f %m "$project/$file" 2>/dev/null
                        end |
                        sort -nr |
                        head -1
                    else
                        # If no changes, use the last commit timestamp
                        git -C $project log -1 --format=%ct
                    end
                else
                    stat -f %m $project
                end
            )

            if not string match -q '[0-9]*' $ahead
                set ahead 0
            end
            if not string match -q '[0-9]*' $behind
                set behind 0
            end

            set status_indicator ""
            set is_dirty "0" # Default to clean
            if test -n "$git_status"
                set status_indicator (set_color yellow)"*"(set_color normal)" "
                set is_dirty "1" # Mark as dirty
            end
            set direction_indicator ""
            if test "$ahead" -gt 0
                set direction_indicator (set_color blue)"↑"(set_color normal)" "
                set is_dirty "1" # Consider ahead/behind as dirty
            else if test "$behind" -gt 0
                set direction_indicator (set_color red)"↓"(set_color normal)" "
                set is_dirty "1" # Consider ahead/behind as dirty
            end

            # Format: dirty_flag|timestamp|project_path_with_indicators
            echo "$is_dirty|$modified_time|$relative_path $status_indicator$direction_indicator"
        end
    )

    set sorted_projects (
        printf "%s\n" $formatted_projects |
        sort -t'|' -k1,1r -k2,2nr | # Sort first by dirty flag (reverse), then by timestamp (reverse)
        cut -d'|' -f3- # Remove the sorting fields from output
    )

    set selected_project (printf "%s\n" $sorted_projects | gum filter --height 8 --placeholder "" --prompt "→ " --prompt.foreground 2 --indicator '▌' --indicator.foreground 4 --match.foreground 4 --no-strip-ansi)

    if test -n "$selected_project"
        set clean_project (echo $selected_project | sed -E 's/\x1B\[[0-9;]*[mK]//g' | sed 's/[*↑↓]//g' | string trim)
        set full_path ~/Developer/$clean_project
        if test -d $full_path
            cd $full_path
        else
            echo "Directory not found: $full_path"
        end
    else
        echo -en "\033[7A"
        commandline -f repaint
    end

    commandline -f repaint
end
