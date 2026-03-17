function fish_prompt
    set -l last_status $status
    set -l cwd_basename (set_color yellow)(basename (string replace -r "^$HOME" "~" (pwd)))(set_color normal)

    printf "%s%s " (test -n "$DIRENV_DIR" && printf "%s" (set_color yellow)"*") $cwd_basename

    # Cache jj repository status.
    if not set -q __jj_repo_cache_pwd
        set -g __jj_repo_cache_pwd ""
        set -g __jj_repo_cache_result 0
    end

    set -l current_pwd (pwd)
    if test "$current_pwd" != "$__jj_repo_cache_pwd"
        set -g __jj_repo_cache_pwd $current_pwd
        if command -sq jj; and jj root --quiet >/dev/null 2>&1
            set -g __jj_repo_cache_result 1
        else
            set -g __jj_repo_cache_result 0
        end
    end

    if test $__jj_repo_cache_result -eq 1
        jj log --quiet --no-graph --color always -r @ -T "separate(
            ' ',
            if(conflict, label('conflict', '×'),
               if(remote_bookmarks.filter(|b| b.name().contains('main')),
                  if(remote_bookmarks.filter(|b| b.remote().contains('origin')),
                     label('empty', '✓'),
                     label('working_copy change_id', '!')
                  )
               )
            ),
            description.first_line(),
            if(empty, label('empty', 'empty'), commit_timestamp(self).ago())
        )"
    else
        if git rev-parse --is-inside-work-tree >/dev/null 2>&1
            __fish_prompt_git_status
        end
    end

    printf "\n%s " (test $last_status -eq 0 && printf "%s" (set_color green)"→"(set_color normal) || printf "%s" (set_color red)"×"(set_color normal))
end

function __fish_prompt_git_status
    set -l git_status_output ""
    set -l is_synced 1
    set -l has_upstream 0
    set -l branch_name ""
    set -l ahead 0
    set -l behind 0
    set -l has_conflicts 0
    set -l has_dirty 0
    set -l has_staged 0

    set -l status_lines (git status --porcelain=v2 --branch 2>/dev/null)
    or return

    for line in $status_lines
        switch $line
            case '# branch.head *'
                set branch_name (string replace '# branch.head ' '' -- $line)
            case '# branch.oid *'
                if test "$branch_name" = "(detached)"
                    set branch_name "@"(string sub -s 1 -l 7 -- (string replace '# branch.oid ' '' -- $line))
                end
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
                set -l fields (string split ' ' -- $line)
                set -l xy $fields[2]
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

    if test -n "$branch_name"; and test "$branch_name" != "(initial)"
        set git_status_output (set_color magenta)"$branch_name "(set_color normal)"$git_status_output"
    end

    if test "$behind" -gt 0
        set git_status_output "$git_status_output"(set_color red)"↓ "(set_color normal)
    end

    if test "$ahead" -gt 0
        set git_status_output "$git_status_output"(set_color green)"↑ "(set_color normal)
    end

    set -l git_dir (git rev-parse --git-dir 2>/dev/null)
    if test -n "$git_dir"
        if test -d "$git_dir/rebase-merge"
            set git_status_output "$git_status_output"(set_color cyan)"rebasing "(set_color normal)
            set is_synced 0
        else if test -d "$git_dir/rebase-apply"
            set git_status_output "$git_status_output"(set_color cyan)"rebasing "(set_color normal)
            set is_synced 0
        else if test -f "$git_dir/MERGE_HEAD"
            set git_status_output "$git_status_output"(set_color yellow)"merging "(set_color normal)
            set is_synced 0
        else if test -f "$git_dir/CHERRY_PICK_HEAD"
            set git_status_output "$git_status_output"(set_color red)"cherry picking "(set_color normal)
            set is_synced 0
        else if test -f "$git_dir/BISECT_LOG"
            set git_status_output "$git_status_output"(set_color red)"bisecting "(set_color normal)
            set is_synced 0
        end
    end

    if test $has_conflicts -eq 1
        set git_status_output "$git_status_output"(set_color red)"! "(set_color normal)
    end

    if test $has_dirty -eq 1
        set git_status_output "$git_status_output"(set_color yellow)"* "(set_color normal)
    end

    if test $has_staged -eq 1
        set git_status_output "$git_status_output"(set_color blue)"* "(set_color normal)
    end

    if test $is_synced -eq 1; and test $has_upstream -eq 1
        set git_status_output "$git_status_output"(set_color green)"✓ "(set_color normal)
    end

    set -l tag (git describe --exact-match --tags 2>/dev/null)
    if test -n "$tag"
        set git_status_output "$git_status_output"(set_color green)"$tag "(set_color normal)
    end

    if test -n "$git_status_output"
        printf "%s" $git_status_output
    end
end

function getCursorRow --description 'Print cursor row (1-based), empty on timeout'
    if set -q __fish_prompt_cursor_query_supported; and test $__fish_prompt_cursor_query_supported -eq 0
        return
    end

    set -l old (stty -g </dev/tty 2>/dev/null)
    or begin
        set -g __fish_prompt_cursor_query_supported 0
        return
    end

    stty -icanon -echo min 0 time 1 </dev/tty 2>/dev/null
    or begin
        stty $old </dev/tty 2>/dev/null
        set -g __fish_prompt_cursor_query_supported 0
        return
    end

    printf '\e[6n' >/dev/tty

    set -l buf ''
    while true
        set -l ch (dd bs=1 count=1 status=none < /dev/tty 2>/dev/null)
        test -z "$ch"; and break
        set buf "$buf$ch"
        test "$ch" = R; and break
    end

    stty $old </dev/tty 2>/dev/null

    if test -z "$buf"
        set -g __fish_prompt_cursor_query_supported 0
        return
    end

    set -g __fish_prompt_cursor_query_supported 1

    set -l cleaned (string replace -ra '[^0-9;]+' '' -- $buf)
    set -l parts (string split ';' -- $cleaned)
    test (count $parts) -ge 1; and echo $parts[1]
end

function clean --on-event fish_preexec
    set -l cmd $argv[1]
    set -l offset (math (string length -- $cmd) + 3)

    set -l cwd (string replace -r "^$HOME" "~" (pwd))
    set -l cwd_basename (basename $cwd)

    set -l row (getCursorRow)

    if test "$row" = 2
        printf "\033[2A\r\033[%dC%s\033[1B\r" \
            $offset (set_color brblack)$cwd_basename(set_color normal)
    else
        printf "\033[2A\r\033[K\033[1B\r\033[%dC%s\033[1B\r" \
            $offset (set_color brblack)$cwd_basename(set_color normal)
    end
end

function __fish_prompt_accept_line
    if test -z (string trim -- (commandline))
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
    printf "\n\n"
end

function __clear_jj_cache --on-variable PWD
    set -e __jj_repo_cache_pwd
    set -e __jj_repo_cache_result
end
