set -e __fish_prompt_os
set -e __fish_prompt_context_cache_pwd
set -e __fish_prompt_context_cache_value
set -e __fish_prompt_title_context_cache_value

function fish_prompt
    set -l last_status $status

    if contains -- --title-context $argv
        __fish_prompt_command_context --without-commit
        return
    end

    set -l header_color yellow
    set -l final_rendering 0
    if contains -- --final-rendering $argv
        set header_color brblack
        set final_rendering 1
    end

    set_color $header_color
    printf "%s " (__fish_prompt_command_context)
    set_color normal
    if test -n "$DIRENV_DIR"
        set_color $header_color
        printf "* "
        set_color normal
    end

    if test $final_rendering -eq 0
        __fish_prompt_git_status
    end

    printf "\n"
    if test $last_status -eq 0
        set_color green
        printf "%s" "→"
    else
        set_color red
        printf "%s" "×"
    end
    set_color normal
    printf " "
end

function __fish_prompt_git_status
    set -l is_synced 1
    set -l has_upstream 0
    set -l branch_name ""
    set -l ahead 0
    set -l behind 0
    set -l has_conflicts 0
    set -l has_dirty 0
    set -l has_staged 0
    set -l git_head ""
    set -l operation ""
    set -l operation_color ""

    set -l status_lines (git status --porcelain=v2 --branch 2>/dev/null)
    or return

    for line in $status_lines
        switch $line
            case '# branch.head *'
                set branch_name (string replace '# branch.head ' '' -- $line)
            case '# branch.oid *'
                set git_head (string replace '# branch.oid ' '' -- $line)
            case '# branch.ab *'
                set has_upstream 1
                set -l counts (string match -r '# branch.ab \+([0-9]+) -([0-9]+)' -- $line)
                if test (count $counts) -ge 3
                    set ahead $counts[2]
                    set behind $counts[3]
                end
            case 'u *'
                set has_conflicts 1
                set is_synced 0
            case '? *'
                set has_dirty 1
                set is_synced 0
            case '1 *' '2 *'
                set -l xy (string sub -s 3 -l 2 -- $line)
                set -l index_status (string sub -s 1 -l 1 -- $xy)
                set -l worktree_status (string sub -s 2 -l 1 -- $xy)

                if test "$worktree_status" != "."
                    set has_dirty 1
                    set is_synced 0
                end

                if test "$index_status" != "."
                    set has_staged 1
                    set is_synced 0
                end
        end
    end

    if test "$branch_name" = "(detached)"; and test -n "$git_head"
        set branch_name "@"(string sub -s 1 -l 7 -- $git_head)
    end

    if not set -q __git_dir_cache_pwd; or test "$PWD" != "$__git_dir_cache_pwd"; or not set -q __git_dir_cache_value
        set -g __git_dir_cache_pwd $PWD
        set -g __git_dir_cache_value (git rev-parse --git-dir 2>/dev/null)
    end

    set -l git_dir $__git_dir_cache_value
    if test -n "$git_dir"
        if test -d "$git_dir/rebase-merge"; or test -d "$git_dir/rebase-apply"
            set operation rebasing
            set operation_color cyan
            set is_synced 0
        else if test -f "$git_dir/MERGE_HEAD"
            set operation merging
            set operation_color yellow
            set is_synced 0
        else if test -f "$git_dir/CHERRY_PICK_HEAD"
            set operation "cherry picking"
            set operation_color red
            set is_synced 0
        else if test -f "$git_dir/BISECT_LOG"
            set operation bisecting
            set operation_color red
            set is_synced 0
        end
    end

    set -l tag
    if test "$git_head" != "(initial)"
        set tag (git describe --exact-match --tags 2>/dev/null)
    end

    if test "$behind" -gt 0
        set_color red
        printf "↓ "
        set_color normal
    end

    if test "$ahead" -gt 0
        set_color green
        printf "↑ "
        set_color normal
    end

    if test -n "$operation"
        set_color $operation_color
        printf "%s " "$operation"
        set_color normal
    end

    if test $has_conflicts -eq 1
        set_color red
        printf "! "
        set_color normal
    end

    if test $has_dirty -eq 1
        set_color yellow
        printf "* "
        set_color normal
    end

    if test $has_staged -eq 1
        set_color blue
        printf "* "
        set_color normal
    end

    if test $is_synced -eq 1; and test $has_upstream -eq 1
        set_color green
        printf "✓ "
        set_color normal
    end

    if test -n "$tag"
        set_color green
        printf "%s " "$tag"
        set_color normal
    end
end

function __fish_prompt_display_path
    set -l location (path normalize "$argv[1]")
    set -l home (path normalize "$HOME")

    if test "$location" = "$home"
        printf '~'
    else if string match --quiet "$home/*" "$location"
        printf '~%s' (string sub -s (math (string length "$home") + 1) -- "$location")
    else
        printf '%s' "$location"
    end
end

function __fish_prompt_command_context
    set -l without_commit 0
    contains -- --without-commit $argv; and set without_commit 1

    if set -q __fish_prompt_context_cache_pwd __fish_prompt_context_cache_value __fish_prompt_title_context_cache_value
        and test "$PWD" = "$__fish_prompt_context_cache_pwd"
        if test $without_commit -eq 1
            printf "%s" "$__fish_prompt_title_context_cache_value"
        else
            printf "%s" "$__fish_prompt_context_cache_value"
        end
        return
    end

    if not set -q __fish_prompt_os
        set -g __fish_prompt_os
        switch (uname)
            case Linux
                set -g __fish_prompt_os "⌁"
        end
    end

    set -l repository (__fish_prompt_display_path "$PWD")
    set -l worktree
    set -l branch
    set -l commit
    set -l git_info (command git rev-parse --show-toplevel --git-common-dir --git-dir --short HEAD 2>/dev/null)

    if test (count $git_info) -ge 3
        set -l worktree_root $git_info[1]
        set -l common_dir $git_info[2]
        set -l git_dir $git_info[3]
        if test (count $git_info) -ge 4
            set commit $git_info[4]
        end

        if not string match --quiet --regex '^/' "$common_dir"
            set common_dir (path resolve "$common_dir")
        end
        if not string match --quiet --regex '^/' "$git_dir"
            set git_dir (path resolve "$git_dir")
        end

        if test (path basename "$common_dir") = .git
            set repository (path basename (path dirname "$common_dir"))
        else
            set repository (path basename "$common_dir")
        end

        # Prefer GitHub's canonical repository name when origin points there,
        # supporting HTTPS, SSH URLs, and SCP-style SSH remotes.
        set -l origin_url (command git config --get remote.origin.url 2>/dev/null)
        if string match --quiet --ignore-case --regex 'github\.com[/:]' "$origin_url"
            set -l github_path (string replace -r '^.*github\.com[/:]' '' -- "$origin_url")
            set github_path (string replace -r '[?#].*$' '' -- "$github_path")
            set github_path (string replace -r '\.git/?$' '' -- "$github_path")
            set github_path (string trim -c / -- "$github_path")
            set -l github_parts (string split / -- "$github_path")
            if test (count $github_parts) -ge 2
                set repository $github_parts[-1]
            end
        end

        if test "$git_dir" != "$common_dir"
            set -l codex_worktree (string match -r '/\.codex/worktrees/([^/]+)(?:/|$)' -- "$worktree_root")
            if test (count $codex_worktree) -ge 2
                set worktree $codex_worktree[2]
            else
                set worktree (path basename "$worktree_root")
                if test "$worktree" = "$repository"
                    set worktree (path basename (path dirname "$worktree_root"))
                end
            end
        end

        # Reading HEAD avoids another Git process on every cache refresh.
        if test -r "$git_dir/HEAD"
            set -l head (string trim -- (string collect <"$git_dir/HEAD"))
            set -l head_ref (string match -r '^ref: refs/heads/(.+)$' -- "$head")
            if test (count $head_ref) -ge 2
                set branch $head_ref[2]
            else if string match --quiet --regex '^[0-9a-fA-F]{7,}$' "$head"
                if test -n "$commit"
                    set branch "@$commit"
                else
                    set branch "@"(string sub -s 1 -l 7 -- "$head")
                end
                set commit
            end
        end
    end

    set -l fields $__fish_prompt_os $repository $worktree $branch $commit
    set -l safe_fields
    for field in $fields
        test -n "$field"; or continue
        set -a safe_fields (string replace -ra '[[:cntrl:]]' '' -- "$field")
    end

    set -g __fish_prompt_context_cache_pwd $PWD
    set -g __fish_prompt_context_cache_value (string join " " -- $safe_fields)

    set -l title_fields $__fish_prompt_os $repository $worktree
    set -l safe_title_fields
    for field in $title_fields
        test -n "$field"; or continue
        set -a safe_title_fields (string replace -ra '[[:cntrl:]]' '' -- "$field")
    end
    if test (count $safe_title_fields) -ge 2
        set -l title_details (string join "  " -- $safe_title_fields[2..-1])
        set -g __fish_prompt_title_context_cache_value "$safe_title_fields[1]  $title_details"
    else
        set -g __fish_prompt_title_context_cache_value (string join " " -- $safe_title_fields)
    end
    if test -n "$branch"
        set -l safe_branch (string replace -ra '[[:cntrl:]]' '' -- "$branch")
        set -g __fish_prompt_title_context_cache_value "$__fish_prompt_title_context_cache_value  $safe_branch"
    end

    if test $without_commit -eq 1
        printf "%s" "$__fish_prompt_title_context_cache_value"
    else
        printf "%s" "$__fish_prompt_context_cache_value"
    end
end

function __fish_prompt_commandline_is_blank
    if test (count $argv) -eq 0
        return 0
    end

    not string match --quiet --regex '\S' -- (string join \n -- $argv)
end

function __fish_prompt_accept_line
    if __fish_prompt_commandline_is_blank (commandline)
        set -g __fish_prompt_empty_submit 1
    else
        set -e __fish_prompt_empty_submit
    end

    commandline -f execute
end

function __fish_prompt_compact_empty --on-event fish_prompt
    if not set -q __fish_prompt_empty_submit
        return
    end

    set -e __fish_prompt_empty_submit
    printf "\033[2A\r\033[K\n"
end

function space --on-event fish_postexec
    set -e __fish_prompt_context_cache_pwd
    set -e __fish_prompt_context_cache_value
    set -e __fish_prompt_title_context_cache_value
    printf "\n\n"
end

function __clear_prompt_cache --on-variable PWD
    set -e __git_dir_cache_pwd
    set -e __git_dir_cache_value
    set -e __fish_prompt_context_cache_pwd
    set -e __fish_prompt_context_cache_value
    set -e __fish_prompt_title_context_cache_value
end
