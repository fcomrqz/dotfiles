function git-commit
    if not git rev-parse --is-inside-work-tree >/dev/null 2>&1
        promptError "Not git directory"
        return 1
    end

    set -l staged_changes (git diff --cached --name-only)
    if test -z "$staged_changes"
        commandline -f repaint
        return 1
    end

    set type (gum filter "fix" "feat" "test" "refactor" "perf" "build" "ci" "dx" "style" "workflow" "chore" "types" "release" "docs" "wip" --placeholder="" --prompt="→ " --height 6 --prompt.foreground 2 --indicator.foreground 4 --match.foreground 4)

    if test -z "$type"
        commandline -f repaint
        return 1
    end

    set scope (gum input --placeholder "scope" --prompt "→ " --prompt.foreground 2 --no-show-help --cursor.background 0 --cursor.foreground 15)

    if test -n "$scope"
        set scope "($scope)"
    end

    set summary (gum input --value "$type$scope: " --prompt "→ " --prompt.foreground 2 --no-show-help --cursor.background 0 --cursor.foreground 15)

    if test -z "$summary"
        commandline -f repaint
        return 1
    end

    # set description (gum write --placeholder "details" --no-show-help --show-line-numbers --cursor.foreground 15)
    # gum confirm "$summary" --no-show-help --affirmative="commit" --negative="cancel" --prompt "" --prompt.foreground null --selected.background 6 --unselected.background 7 --unselected.foreground 0 && git commit -m "$summary" -m "$description"

    gum confirm "$summary" --no-show-help --affirmative="commit" --negative="cancel" --prompt.foreground null --selected.background 6 --unselected.background 7 --unselected.foreground 0 && git commit -m "$summary"

    commandline -f repaint
end
