function open_project
    set -l developer_root "$HOME/Developer"
    test -d "$developer_root"; or return 1

    set -l projects (
        command find "$developer_root" \
            \( -name node_modules -o -name .build -o -name .cache \) -prune -o \
            -name .git -print -prune 2>/dev/null |
        while read -l git_entry
            path dirname "$git_entry"
        end |
        command sort -u
    )
    test (count $projects) -gt 0; or return 1

    set -l sortable
    for project in $projects
        set -l relative_path (string replace "$developer_root/" '' -- "$project")
        set -l dirty 0
        set -l marker ''
        if test -n "$(command git -C "$project" status --porcelain 2>/dev/null)"
            set dirty 1
            set marker ' '(set_color yellow)'*'(set_color normal)
        end
        set -l modified (command git -C "$project" log -1 --format=%ct 2>/dev/null)
        test -n "$modified"; or set modified 0
        set -a sortable "$dirty|$modified|$relative_path$marker"
    end

    set -l sorted_projects (
        printf '%s\n' $sortable |
        command sort -t '|' -k1,1r -k2,2nr |
        command cut -d '|' -f 3-
    )
    set -l selected_project (__gum_filter --height 12 -- $sorted_projects)

    if test -n "$selected_project"
        set -l clean_project (string replace -r ' \*$' '' -- "$selected_project")
        set -l full_path "$developer_root/$clean_project"
        if test -d "$full_path"
            cd "$full_path"
        end
    end
    commandline -f repaint
end
