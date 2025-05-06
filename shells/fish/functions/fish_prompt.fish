function fish_prompt
    set -l last_status $status
    set -l cwd_basename (set_color yellow)(basename (string replace -r "^$HOME" "~" (pwd)))(set_color normal)

    printf "%s%s " (test -n "$DIRENV_DIR" && printf "%s" (set_color yellow)"*") $cwd_basename

    if command -sq jj && jj root --quiet >/dev/null 2>&1
        jj log --quiet --no-graph --color always -r @ -T "separate(
            ' ',
            if(bookmarks, label('bookmarks', bookmarks)),
            if(conflict, label('conflict', '×')),
            if(description, label('timestamp', description.first_line()), label('description_missing', 'description missing')),
            if(empty, label('working_copy empty', 'empty'), label('working_copy change_id', commit_timestamp(self).ago()))
          )"
    end

    printf "\n%s " (test $last_status -eq 0 && printf "%s" (set_color green)"→"(set_color normal) || printf "%s" (set_color red)"×"(set_color normal))
end

function clean --on-event fish_preexec
    set -l cmd $argv[1]
    echo -en "\033[2A\r\033[K"

    set -l cwd_basename (basename (string replace -r "^$HOME" "~" (pwd)))
    printf "\n%s %s%s%s\n" (set_color green)"→"(set_color normal) $cmd (set_color brblack)" $cwd_basename"(set_color normal)
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
