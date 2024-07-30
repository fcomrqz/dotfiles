function open_project
    set project (command find ~/habive ~/fcomrqz ~/mondraco ~/bookip -type d -maxdepth 1 -mindepth 1 | string replace -r '/Users/fran/' '' | fzf --query "$argv")
    if test -n "$project"
        cd ~/$project
    end
    commandline -f repaint
end
