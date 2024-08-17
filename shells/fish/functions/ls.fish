function ls -d 'List files and directories'
    command tree -i -C -a --dirsfirst -L 1 -I '.git|.DS_Store|node_modules|Creative\ Cloud\ Files' $argv
end
