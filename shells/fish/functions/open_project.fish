function open_project
    set project (command find ~/Developer/habive ~/Developer/fcomrqz ~/Developer/mondraco ~/Developer/bookip -type d -maxdepth 1 -mindepth 1 | string replace -r '/Users/fran/Developer/' '' | fzf --query "$argv")
    if test -n "$project"
        cd ~/Developer/$project
    end
    commandline -f repaint
end
