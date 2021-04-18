function la -d 'List excluded files and directories'
  command tree -C -a --dirsfirst -L 1 -I '.DS_Store' $argv
end
