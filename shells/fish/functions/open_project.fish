# TODO: Check all branches to represent repository status and print if is synced

function open_project
    set projects (command find ~/Developer -type d -maxdepth 2 -mindepth 2 -exec test -d '{}/.git' ';' -print)

    set formatted_projects (
        for project in $projects
            set relative_path (string replace -r '/Users/fran/Developer/' '' $project)

            # Get git status once
            set git_status (git -C $project status --porcelain 2>/dev/null)

            # Get last modified timestamp
            set modified_time (
                if test -n "$git_status"
                    # For dirty repos: get modification times from changed files
                    echo "$git_status" |
                    cut -c4- |  # Remove status codes
                    head -10 |  # Limit to first 10 files for performance
                    while read -l file
                        test -f "$project/$file" && stat -f %m "$project/$file" 2>/dev/null
                    end |
                    sort -nr |
                    head -1
                else
                    # For clean repos: use last commit timestamp
                    git -C $project log -1 --format=%ct 2>/dev/null
                end
            )

            # Default timestamp if none found
            test -z "$modified_time" && set modified_time (stat -f %m $project 2>/dev/null || echo 0)

            set status_indicator ""
            set is_dirty "0" # Default to clean
            if test -n "$git_status"
                set status_indicator (set_color yellow)"*"(set_color normal)" "
                set is_dirty "1" # Mark as dirty
            end

            # Format: dirty_flag|timestamp|project_path_with_indicators
            echo "$is_dirty|$modified_time|$relative_path $status_indicator"
        end
    )

    set sorted_projects (
        printf "%s\n" $formatted_projects |
        sort -t'|' -k1,1r -k2,2nr | # Sort first by dirty flag (reverse), then by timestamp (reverse)
        cut -d'|' -f3- # Remove the sorting fields from output
    )

    set selected_project (printf "%s\n" $sorted_projects | gum filter --height 6 --placeholder "" --prompt "→ " --prompt.foreground 2 --indicator '▌' --indicator.foreground 4 --match.foreground 4 --no-strip-ansi)

    if test -n "$selected_project"
        # Use the original sed approach for cleaning
        set clean_project (echo $selected_project | sed -E 's/\x1B\[[0-9;]*[mK]//g' | sed 's/[*]//g' | string trim)
        set full_path ~/Developer/$clean_project
        if test -d $full_path
            cd $full_path
        end
    else
        echo -en "\033[7A\033[J"
    end

    commandline -f repaint
end
