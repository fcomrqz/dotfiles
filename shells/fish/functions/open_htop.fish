function open_htop
    commandline -f cancel-commandline
    read -l process_name -p "set_color green; echo -n 'htop → '; set_color normal;"
    if test -n "$process_name"
        htop -F $process_name
    else
        htop
    end
    commandline -f clear-screen
    commandline -f repaint
end
