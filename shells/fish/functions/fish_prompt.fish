function fish_prompt
    set -l last_status $status
    set -l cwd_basename (set_color yellow)(basename (string replace -r "^$HOME" "~" (pwd)))(set_color normal)

    printf "%s%s " (test -n "$DIRENV_DIR" && printf "%s" (set_color yellow)"*") $cwd_basename

    # Cache jj repository status
    if not set -q __jj_repo_cache_pwd
        set -g __jj_repo_cache_pwd ""
        set -g __jj_repo_cache_result 0
    end

    set -l current_pwd (pwd)
    if test "$current_pwd" != "$__jj_repo_cache_pwd"
        set -g __jj_repo_cache_pwd $current_pwd
        if command -sq jj && jj root --quiet >/dev/null 2>&1
            set -g __jj_repo_cache_result 1
        else
            set -g __jj_repo_cache_result 0
        end
    end

    if test $__jj_repo_cache_result -eq 1
        # Simplified jj template for better performance
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
    end

    printf "\n%s " (test $last_status -eq 0 && printf "%s" (set_color green)"→"(set_color normal) || printf "%s" (set_color red)"×"(set_color normal))
end

function getCursorRow --description 'Print cursor row (1-based), empty on timeout'
    set -l old (stty -g </dev/tty)
    stty -icanon -echo min 0 time 5 </dev/tty # ~0.5s timeout
    printf '\e[6n' >/dev/tty # ask for position
    set -l buf ''
    while true
        set -l ch (dd bs=1 count=1 status=none < /dev/tty)
        test -z "$ch"; and break
        set buf "$buf$ch"
        test "$ch" = R; and break
    end
    stty $old </dev/tty

    set -l cleaned (string replace -ra '[^0-9;]+' '' -- $buf)
    set -l parts (string split ';' -- $cleaned)
    test (count $parts) -ge 1; and echo $parts[1] # row
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

function empty --on-event fish_prompt
    set -l cmd $argv[1]
    if test -z "$cmd"
        echo -en "\033[2A\r\033[K\n"
    end
end

function space --on-event fish_postexec
    printf "\n\n"
end

# Clear cache when changing directories
function __clear_jj_cache --on-variable PWD
    set -e __jj_repo_cache_pwd
    set -e __jj_repo_cache_result
end
