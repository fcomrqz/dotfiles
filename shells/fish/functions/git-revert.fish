function git-revert
    if not git rev-parse --is-inside-work-tree >/dev/null 2>&1
        promptError "Not git directory"
        return 1
    end

    set selected_commit (git log -n 200 --pretty=format:"%h %s · %cr" | grep -vi '^[a-f0-9]\{7\} revert:' | sed -E 's/^([a-f0-9]{7}) (.*) · (.*)$/\x1b[35m\1\x1b[0m \2 \x1b[90m\3\x1b[0m/' | gum filter --placeholder="" --prompt="→ " --no-sort --height 10 --prompt.foreground 2 --indicator '▌' --indicator.foreground 4 --match.foreground 4)

    if test -n "$selected_commit"
        set commit_hash (echo $selected_commit | sed -E 's/^.*([a-f0-9]{7}).*$/\1/')
        git revert $commit_hash --no-edit
    end

    commandline -f repaint
end
