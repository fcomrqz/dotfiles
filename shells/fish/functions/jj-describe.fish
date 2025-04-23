function jj-describe
    if not jj root --quiet >/dev/null 2>&1
        promptError "Not jujutsu directory"
        return 1
    end

    set type (gum filter "fix" "feat" "test" "clean" "perf" "build" "ci" "dx" "style" "workflow" "chore" "types" "release" "docs" --placeholder="" --prompt="→ " --height 6 --prompt.foreground 2 --indicator.foreground 4 --match.foreground 4)

    if test -z "$type"
        echo -en "\033[5A\033[J"
        promptError "Describe aborted"
        return 1
    end

    set prompt (set_color green)" → "(set_color reset)

    # Read the scope with native fish read
    read -P "$type$prompt" scope

    if test -n "$scope"
        set scope "($scope)"
    end

    echo -en "\033[1A\r\033[K"
    read -P "$type$scope$prompt" summary

    if test -n "$summary"
        jj describe -m "$type$scope: $summary"
        echo -en "\033[5A\033[J"
    else
        echo -en "\033[1A\r\033[K"
        promptError "Describe aborted"
    end

    commandline -f repaint
end
