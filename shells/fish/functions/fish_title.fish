function fish_title
    if not set -q INSIDE_EMACS; or string match -vq '*,term:*' -- $INSIDE_EMACS
        set -l cwd (string replace -r '^'"$HOME"'($|/)' '~$1' "$PWD")
        if string match -q '~' "$cwd"
            echo '~'
        else if string match -q '~*' "$cwd"
            echo (basename $cwd)
        else
            echo $cwd
        end
        echo '  ·  '
        echo (set -q argv[1] && echo $argv[1] || status current-command)
    end
end
