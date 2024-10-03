function git-add
    # First, check if .git folder exists in the current or parent directories
    if not git rev-parse --git-dir >/dev/null 2>&1
        commandline -f repaint
        return 1
    end

    set -l git_status (git status -s)

    if test -z "$git_status"
        commandline -f repaint
        return 1
    end

    # Get the status, replace M with yellow *, A with green +, D with red -, and pass to gum choose
    set -l files (git status -s | grep '^.[M?RCDU]' | sed 's/^ M/\x1b[33m*\x1b[0m/;s/^MM/\x1b[33m*\x1b[0m/;s/^AM/\x1b[33m*\x1b[0m/;s/^UU/\x1b[33m*\x1b[0m/;s/^??/\x1b[32m+\x1b[0m/;s/^ D/\x1b[31m-\x1b[0m/' | gum choose --no-limit --cursor="→ " --unselected-prefix="  " --header="" --cursor.foreground 2 --no-show-help --selected.foreground 4 --height 9)

    # If no files were selected, exit
    if test -z "$files"
        commandline -f repaint
        return 1
    end

    # Process selected files and add them to git
    for file in $files
        # Remove color codes and leading symbols more thoroughly
        set -l clean_file (echo $file | sed -E 's/\x1B\[[0-9;]*[mK]//g' | sed -E 's/^[ *+-]+//')
        # Trim any leading or trailing whitespace
        set clean_file (string trim "$clean_file")
        if test -n "$clean_file"
            git add "$clean_file"
        end
    end

    commandline -f repaint
end
