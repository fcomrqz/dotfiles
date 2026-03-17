function fish_title
    if not set -q INSIDE_EMACS; or string match -vq '*,term:*' -- $INSIDE_EMACS
        set -l cwd (string replace -r '^'"$HOME"'($|/)' '~$1' "$PWD")
        set -l title_text ""

        if string match -q '~' "$cwd"
            set title_text '~'
        else if string match -q '~*' "$cwd"
            set title_text (basename $cwd)
        else
            set title_text $cwd
        end

        # Add git branch if in a git repository AND .git is a directory (not a file) AND no .jj folder
        if test -d .git; and not test -f .git; and not test -d .jj
            set -l branch_name (git symbolic-ref --short HEAD 2>/dev/null; or git describe --contains --all HEAD 2>/dev/null)
            if test -n "$branch_name"
                set title_text "$title_text  ·  $branch_name"
            end
        end

        echo $title_text
        echo '  ·  '
        echo (set -q argv[1] && echo $argv[1] || status current-command)
    end
end
