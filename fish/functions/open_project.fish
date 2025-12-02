# TODO: Check all branches to represent repository status and print if is synced

function open_project
    # Find git repos efficiently by locating .git directories/files and getting their parent
    set projects (command find ~/Developer -maxdepth 3 -mindepth 3 -name .git \( -type d -o -type f \) -print0 2>/dev/null | xargs -0 -n1 dirname | sort -u)

    set formatted_projects (
        for project in $projects
            set relative_path (string replace -r '^/Users/fran/Developer/' '' $project)

            # Get git status once
            set git_status (git -C $project status --porcelain 2>/dev/null)

            # Get last modified timestamp
            if test -n "$git_status"
                # For dirty repos: use the newest mtime from git status files (single stat call)
                set modified_time (
                    echo "$git_status" |
                    cut -c4- |
                    head -10 |
                    sed "s|^|$project/|" |
                    xargs stat -f %m 2>/dev/null |
                    sort -nr |
                    head -1
                )
                # Fallback to repo mtime if stat fails
                test -z "$modified_time" && set modified_time (stat -f %m $project 2>/dev/null || echo 0)
                set status_indicator (set_color yellow)"*"(set_color normal)" "
                set is_dirty "1"
            else
                # For clean repos: use last commit timestamp
                set modified_time (git -C $project log -1 --format=%ct 2>/dev/null)
                test -z "$modified_time" && set modified_time (stat -f %m $project 2>/dev/null || echo 0)
                set status_indicator ""
                set is_dirty "0"
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

    set selected_project (printf "%s\n" $sorted_projects | ~/.gum/gum filter --placeholder "" --prompt "→ " --prompt.foreground 2 --indicator '▌' --indicator.foreground 4 --match.foreground 4 --height 12)

    if test -n "$selected_project"
        # Clean project name efficiently using fish string functions
        set clean_project (string replace -ra '\x1B\[[0-9;]*[mK]|\*' '' -- $selected_project | string trim)
        set full_path ~/Developer/$clean_project
        if test -d $full_path
            cd $full_path
        end
    end

    commandline -f repaint
end
