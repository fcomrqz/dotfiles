function open_gitui
    if not git rev-parse --is-inside-work-tree >/dev/null 2>&1
        promptError "Not git directory"
        return 1
    end

    command gitui
    commandline -f repaint
    return 0
end
