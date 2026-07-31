function open_file
    set -l repository_root (command git rev-parse --show-toplevel 2>/dev/null)
    if test -z "$repository_root"
        open_project
        return
    end

    set -l files (
        command git -C "$repository_root" ls-files \
            --cached --others --exclude-standard
    )
    test (count $files) -gt 0; or return

    set -l selected_file (__gum_filter --height 12 --query (string join ' ' $argv) -- $files)
    if test -n "$selected_file"
        set -l full_path "$repository_root/$selected_file"
        switch (uname)
            case Darwin
                command zed "$full_path"
            case Linux
                command micro "$full_path"
        end
    end
    commandline -f repaint
end
