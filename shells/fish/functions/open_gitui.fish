function open_gitui
    if test -d .git
        command gitui
        commandline -f clear-screen
        commandline -f repaint
    end
end
