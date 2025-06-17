function fish_prompt
    set -l last_status $status
    set -l cwd_basename (set_color yellow)(basename (string replace -r "^$HOME" "~" (pwd)))(set_color normal)

    printf "%s%s " (test -n "$DIRENV_DIR" && printf "%s" (set_color yellow)"*") $cwd_basename

    if command -sq jj && jj root --quiet >/dev/null 2>&1
        jj log --quiet --no-graph --color always -r @ -T "separate(
            ' ',
            if(
              conflict,
              label('conflict', '×'),
              coalesce(
                remote_bookmarks.filter(|bookmark| bookmark.name().contains('main')).filter(|bookmark| bookmark.remote().contains('origin')).map(|bookmark| label('empty', '✓')),
                remote_bookmarks.filter(|bookmark| bookmark.name().contains('main')).filter(|bookmark| bookmark.remote().contains('git')).map(|bookmark| label('working_copy change_id', '!'))
              )
            ),
            if(description, description.first_line()),
            if(empty, label('empty', 'empty'), commit_timestamp(self).ago())
          )"
    end

    printf "\n%s " (test $last_status -eq 0 && printf "%s" (set_color green)"→"(set_color normal) || printf "%s" (set_color red)"×"(set_color normal))
end

function clean --on-event fish_preexec
    set -l cmd $argv[1]
    set -l cwd (string replace -r "^$HOME" "~" (pwd))
    set -l cwd_basename (basename $cwd)

    set -l offset (math (string length -- $cmd) + 3)

    printf "\033[2A\r\033[K\033[1B\r\033[%dC%s\033[1B\r" \
        $offset (set_color brblack)$cwd_basename(set_color normal)
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
