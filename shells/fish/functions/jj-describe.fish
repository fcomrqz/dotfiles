function jj-describe
    if not jj root --quiet >/dev/null 2>&1
        promptError "Not jujutsu directory"
        return 1
    end

    set type (gum filter "fix" "feat" "test" "refactor" "perf" "build" "ci" "dx" "style" "workflow" "chore" "types" "release" "docs" "wip" --placeholder="" --prompt="→ " --height 6 --prompt.foreground 2 --indicator.foreground 4 --match.foreground 4)

    if test -z "$type"
        commandline -f repaint
        return 1
    end

    set prompt (set_color green)" → "(set_color reset)

    # Read the scope with native fish read
    read -P "$type$prompt" scope

    if test -n "$scope"
        set scope "($scope)"
    end

    read -P "$type$scope$prompt" summary

    if test -z "$summary"
        commandline -f repaint
        return 1
    end

    jj describe -m "$type$scope: $summary"

    commandline -f repaint
end
