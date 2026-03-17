function fish_user_key_bindings
    bind \r __fish_prompt_accept_line
    bind \n __fish_prompt_accept_line
    bind -M insert \r __fish_prompt_accept_line
    bind -M insert \n __fish_prompt_accept_line
end
