function fish_prompt
    set -l last_status $status

    set -l cwd (string replace -r "^$HOME" "~" (pwd))
    set -l cwd_basename (set_color yellow)(basename $cwd)(set_color normal)

    set -l direnv_prompt ""
    if set -q DIRENV_DIR
        set direnv_prompt (set_color yellow)"*"
    end

    printf "%s%s %s" $direnv_prompt $cwd_basename

    if jj root --quiet >/dev/null 2>&1
        jj log --quiet --no-graph --color always -r @ -T "separate(
            ' ',
            if(bookmarks, label('bookmarks', bookmarks)),
            if(conflict, label('conflict', '×')),
            if(description, label('timestamp', description.first_line()), label('description_missing', 'missing description')),
            if(empty, label('working_copy empty', 'empty'), label('working_copy change_id', commit_timestamp(self).ago()))
          )"
    end

    set -l status_indicator ""
    if test $last_status -eq 0
        set status_indicator (set_color green)"→"(set_color normal)
    else
        set status_indicator (set_color red)"×"(set_color normal)
    end

    printf "%s " \n$status_indicator
end

function __clean_prompt_first_line --on-event fish_preexec
    set -l cmd $argv[1]
    echo -en "\033[2A\r\033[K"
    printf "\n%s %s\n" (set_color green)"→"(set_color normal) $cmd
end

function __add_space_after_command --on-event fish_postexec
    echo ""
    echo ""
end

function __edited --on-event fish_prompt
    set -l cmd $argv[1]
    if test -z "$cmd"
        echo -en "\033[2A\r\033[K"
        echo ""
    end
end
