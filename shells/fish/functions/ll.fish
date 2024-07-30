function ll -d 'List files and directories with size and permisions'
    command tree -C -a --dirsfirst -L 1 -p -h -I '.git|.DS_Store' $argv
end
