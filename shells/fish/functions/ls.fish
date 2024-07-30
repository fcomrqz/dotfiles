function ls -d 'List files and directories'
    command tree -C -a --dirsfirst -L 1 -I '.git|.DS_Store|node_modules|package-lock.json|Creative\ Cloud\ Files' $argv
end
