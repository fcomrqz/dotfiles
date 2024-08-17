function fish_title
    if not set -q INSIDE_EMACS; or string match -vq '*,term:*' -- $INSIDE_EMACS
        echo (set -q argv[1] && echo $argv[1] || status current-command)
        echo '  ·  '
        echo (basename $PWD)
    end
end
