function open_file
    if test -d .git
        set path (command rg --files --hidden --glob "!.git" | fzf --query "$argv")
        if test -n "$path"
            if set -q SSH_CONNECTION
                command micro $path
            else
                command zed $path
            end
        end
        commandline -f repaint
    else
        open_project
    end
end
