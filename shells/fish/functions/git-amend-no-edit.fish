function git-amend-no-edit
    if not git rev-parse --is-inside-work-tree >/dev/null 2>&1
        promptError "Not git directory"
        return 1
    end

    set -l staged_changes (git diff --cached --name-only)
    if test -z "$staged_changes"
        promptError "No files are staged for commit"
        return 1
    end

    if promptConfirmation "git commit --amend --no-edit"
        git commit --amend --no-edit
    end

    commandline -f repaint
end
