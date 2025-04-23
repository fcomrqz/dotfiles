function jj-describe
    if not jj root --quiet >/dev/null 2>&1
        promptError "Not jujutsu directory"
        return 1
    end

    set types feat fix test clean perf build ci release types docs style
    set type (gum filter $types --placeholder="" --prompt="→ " --height 6 --placeholder "" --prompt "→ " --prompt.foreground 2 --indicator '▌' --indicator.foreground 4 --match.foreground 4 --no-strip-ansi)

    if test -z "$type"
        echo -en "\033[5A\033[J"
        promptError "describe aborted"
        return 1
    end

    set prompt (set_color green)" → "(set_color reset)

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
        promptError "description missing"
    end

    commandline -f repaint
end
