function open_htop
    commandline -f cancel-commandline
    read -l process_name -p "set_color green; echo -n 'htop → '; set_color normal;"
    if test -n "$process_name"
        echo -ne "\033]0;htop · $(echo $process_name) · $(echo (basename $PWD))\a"
        htop -F $process_name
    else
        echo -ne "\033]0;htop · $(echo (basename $PWD))\a"
        htop
    end
    commandline -f clear-screen
    commandline -f repaint
end
