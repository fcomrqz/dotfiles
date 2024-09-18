function git-amend-no-edit
    if not git rev-parse --git-dir >/dev/null 2>&1
        commandline -f repaint
        return 1
    end

    set -l staged_changes (git diff --cached --name-only)
    if test -z "$staged_changes"
        commandline -f repaint
        return 1
    end

    command git commit --amend --no-edit
    commandline -f repaint
end
