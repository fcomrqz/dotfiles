function open_gitui
    if test -d .git
        echo -ne "\033]0;gitui · $(echo (basename $PWD))\a"
        command gitui
        commandline -f clear-screen
        commandline -f repaint
    end
end
