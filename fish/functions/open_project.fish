function __open_project_root
    switch (uname)
        case Darwin
            printf '%s\n' "$HOME/Developer"
        case Linux
            printf '%s\n' "$HOME"
        case '*'
            return 1
    end
end

function __open_project_primary_repositories --argument-names project_root operating_system
    set project_root (path resolve "$project_root")
    set -l maximum_depth 2
    if test "$operating_system" = Darwin
        # macOS clones may be direct children or grouped by GitHub owner.
        set maximum_depth 3
    end

    command find "$project_root" \
        -mindepth 2 \
        -maxdepth $maximum_depth \
        -type d \
        -name .git \
        -print 2>/dev/null |
        while read -l git_directory
            set -l repository (path dirname "$git_directory")
            set -l relative_path (
                string replace "$project_root/" '' -- "$repository"
            )
            set -l path_parts (string split / -- "$relative_path")

            # Worktrees are obtained from Git below; never treat their nested
            # .git entries as independent repositories.
            contains -- worktrees $path_parts; and continue

            # If a direct macOS clone exists, ignore nested repositories inside
            # it. Otherwise owner/repository layouts remain supported.
            if test "$operating_system" = Darwin
                if test (count $path_parts) -eq 2
                    test -d "$project_root/$path_parts[1]/.git"; and continue
                end
            end

            printf '%s\n' "$repository"
        end |
        command sort -u
end

function __open_project_collect_checkouts --argument-names project_root operating_system
    set project_root (path resolve "$project_root")
    set -g __open_project_checkout_paths
    set -g __open_project_repository_names

    set -l primary_repositories (
        __open_project_primary_repositories "$project_root" "$operating_system"
    )

    for primary_repository in $primary_repositories
        set -l repository_name (path basename "$primary_repository")
        set -l worktree_lines (
            command git -C "$primary_repository" worktree list --porcelain 2>/dev/null
        )

        for line in $worktree_lines
            string match --quiet 'worktree *' -- "$line"; or continue
            set -l checkout (string replace -r '^worktree ' '' -- "$line")
            test -d "$checkout"; or continue
            set checkout (path resolve "$checkout")
            contains -- "$checkout" $__open_project_checkout_paths; and continue

            set -a __open_project_checkout_paths "$checkout"
            set -a __open_project_repository_names "$repository_name"
        end

        # A damaged worktree registry should not hide the primary checkout.
        if not contains -- "$primary_repository" $__open_project_checkout_paths
            set -a __open_project_checkout_paths "$primary_repository"
            set -a __open_project_repository_names "$repository_name"
        end
    end
end

function __open_project_mtime --argument-names operating_system target
    test -e "$target"; or test -L "$target"; or return 1

    switch "$operating_system"
        case Darwin
            command stat -f %m "$target" 2>/dev/null
        case Linux
            command stat -c %Y "$target" 2>/dev/null
    end
end

function __open_project_changed_path --argument-names status_line
    set -l fields
    switch "$status_line"
        case '1 *'
            set fields (string split -m 8 ' ' -- "$status_line")
            test (count $fields) -ge 9; and printf '%s\n' "$fields[9]"
        case '2 *'
            set fields (string split -m 9 ' ' -- "$status_line")
            if test (count $fields) -ge 10
                string split \t -- "$fields[10]" | head -n 1
            end
        case 'u *'
            set fields (string split -m 10 ' ' -- "$status_line")
            test (count $fields) -ge 11; and printf '%s\n' "$fields[11]"
        case '? *'
            string sub -s 3 -- "$status_line"
    end
end

function __open_project_format_description \
    --argument-names repository branch repository_status
    set -l plain_description "$repository"
    set -l styled_description "$repository"

    if test "$repository_status" != clean
        set plain_description "$plain_description *"
        set -l marker (
            string join '' -- (set_color yellow) '*' (set_color normal)
        )
        set styled_description "$styled_description $marker"
    end

    set -g __open_project_plain_description "$plain_description $branch"
    set -g __open_project_description "$styled_description $branch"
    return 0
end

function __open_project_describe \
    --argument-names checkout repository operating_system
    set -g __open_project_description
    set -g __open_project_plain_description
    set -g __open_project_repository
    set -g __open_project_branch
    set -g __open_project_status
    set -g __open_project_activity 0

    set -l status_lines (
        command git -C "$checkout" \
            status --porcelain=v2 --branch --untracked-files=normal 2>/dev/null
    )
    or return 1

    set -l branch -
    set -l commit -
    set -l repository_status clean

    for line in $status_lines
        switch "$line"
            case '# branch.head *'
                set branch (string replace '# branch.head ' '' -- "$line")
                test "$branch" = '(detached)'; and set branch detached
            case '# branch.oid *'
                set -l oid (string replace '# branch.oid ' '' -- "$line")
                if string match --quiet -r '^[0-9a-fA-F]{7,}$' -- "$oid"
                    set commit (string sub -s 1 -l 7 -- "$oid")
                end
            case 'u *'
                set repository_status conflict
            case '1 *' '2 *' '? *'
                test "$repository_status" = conflict
                or set repository_status dirty
        end
    end

    if test "$branch" = detached
        set branch "@$commit"
        set commit
    end

    set -l commit_time (
        command git -C "$checkout" show -s --format=%ct HEAD 2>/dev/null
    )
    if string match --quiet -r '^[0-9]+$' -- "$commit_time"
        set -g __open_project_activity "$commit_time"
    end

    # Dirty file mtimes make current edits outrank merely recent commits.
    for line in $status_lines
        set -l changed_path (__open_project_changed_path "$line")
        test -n "$changed_path"; or continue

        set -l full_path "$checkout/$changed_path"
        if not test -e "$full_path"; and not test -L "$full_path"
            set full_path (path dirname "$full_path")
        end
        set -l modified (
            __open_project_mtime "$operating_system" "$full_path"
        )
        if string match --quiet -r '^[0-9]+$' -- "$modified"
            if test "$modified" -gt "$__open_project_activity"
                set -g __open_project_activity "$modified"
            end
        end
    end

    set -l safe_repository (
        string replace -ra '[[:cntrl:]]' '' -- "$repository"
    )
    set -l safe_branch (
        string replace -ra '[[:cntrl:]]' '' -- "$branch"
    )
    set -g __open_project_repository "$safe_repository"
    set -g __open_project_branch "$safe_branch"
    set -g __open_project_status "$repository_status"

    __open_project_format_description \
        "$__open_project_repository" \
        "$__open_project_branch" \
        "$__open_project_status"
    return 0
end

function open_project
    set -l operating_system (uname)
    set -l project_root (__open_project_root)
    test -d "$project_root"; or return 1

    __open_project_collect_checkouts "$project_root" "$operating_system"
    test (count $__open_project_checkout_paths) -gt 0; or return 1

    set -l checkout_paths
    set -l repositories
    set -l branches
    set -l statuses
    set -l sortable

    for checkout_index in (seq (count $__open_project_checkout_paths))
        __open_project_describe \
            "$__open_project_checkout_paths[$checkout_index]" \
            "$__open_project_repository_names[$checkout_index]" \
            "$operating_system"
        or continue

        set -a checkout_paths "$__open_project_checkout_paths[$checkout_index]"
        set -a repositories "$__open_project_repository"
        set -a branches "$__open_project_branch"
        set -a statuses "$__open_project_status"
        set -a sortable \
            "$__open_project_activity\t"(count $checkout_paths)
    end

    set -l sorted_paths
    set -l sorted_descriptions
    set -l sorted_plain_descriptions
    for record in (
        printf '%b\n' $sortable |
            command sort -t \t -k1,1nr -k2,2n
    )
        set -l fields (string split \t -- "$record")
        set -l checkout_index $fields[2]
        __open_project_format_description \
            "$repositories[$checkout_index]" \
            "$branches[$checkout_index]" \
            "$statuses[$checkout_index]"
        set -a sorted_paths "$checkout_paths[$checkout_index]"
        set -a sorted_descriptions "$__open_project_description"
        set -a sorted_plain_descriptions "$__open_project_plain_description"
    end

    set -l selected_project (__gum_filter --height 12 -- $sorted_descriptions)
    set -l filter_status $status
    if test $filter_status -eq 0; and test -n "$selected_project"
        set -l selected_index (
            contains --index -- "$selected_project" $sorted_plain_descriptions
        )
        if test -n "$selected_index"; and test -d "$sorted_paths[$selected_index]"
            cd "$sorted_paths[$selected_index]"
        end
    end

    set -e \
        __open_project_activity \
        __open_project_branch \
        __open_project_checkout_paths \
        __open_project_description \
        __open_project_plain_description \
        __open_project_repository \
        __open_project_repository_names \
        __open_project_status
    commandline -f repaint
end
