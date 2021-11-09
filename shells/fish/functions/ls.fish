function ls -d 'List files and directories'
  command tree -C --dirsfirst -L 1 -I '.DS_Store|node_modules|package-lock.json|Creative\ Cloud\ Files' $argv
end
