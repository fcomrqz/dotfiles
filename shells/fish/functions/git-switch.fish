function git-switch
    if not git rev-parse --is-inside-work-tree >/dev/null 2>&1
        promptError "Not git directory"
        return 1
    end

    if not git diff --quiet
        promptError "Dirty working directory"
        return 1
    end

    set current_branch (git rev-parse --abbrev-ref HEAD)

    # Get the current branch name
    set current_branch (git rev-parse --abbrev-ref HEAD)

    # Function to get branch status
    function get_branch_status
        set -l branch $argv[1]
        if not git rev-parse --verify $branch@{u} >/dev/null 2>&1
            return
        end

        set -l ahead (git rev-list --count $branch@{u}..$branch 2>/dev/null)
        set -l behind (git rev-list --count $branch..$branch@{u} 2>/dev/null)

        set -l green (printf "\033[32m")
        set -l red (printf "\033[31m")
        set -l blue (printf "\033[34m")
        set -l reset (printf "\033[0m")

        if test "$ahead" -gt 0 -a "$behind" -gt 0
            printf "%s↑%s %s↓%s" $blue $reset $red $reset
        else if test "$ahead" -gt 0
            printf "%s↑%s" $blue $reset
        else if test "$behind" -gt 0
            printf "%s↓%s" $red $reset
        else
            printf "%s✓%s" $green $reset
        end
    end

    # Get the list of branches excluding the current one
    set branch_list (git for-each-ref --format='%(refname:short)' refs/heads/ | grep -v "^$current_branch\$")

    # Check if there's only one branch (excluding the current one)
    if test (count $branch_list) -eq 0
        promptError "No other branches to switch"
        return 1
    end

    # List branches with status, excluding the current one
    set branch (printf '%s\n' $branch_list | while read -l branch
               set -l branch_status (get_branch_status $branch)
               printf "%s %s\n" $branch $branch_status
           end | gum filter --placeholder="" --prompt="→ " --height 10 --prompt.foreground 2 --indicator '▌' --indicator.foreground 4 --match.foreground 4)


    if test -z "$branch"
        commandline -f repaint
        return 0
    end


    # Extract just the branch name (remove status info)
    set branch (string split ' ' $branch)[1]

    git switch $branch --quiet
    commandline -f repaint
    return 1
end
