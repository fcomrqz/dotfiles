function fish_user_key_bindings
    bind enter __fish_prompt_accept_line
    bind ctrl-j __fish_prompt_accept_line
    bind -M insert enter __fish_prompt_accept_line
    bind -M insert ctrl-j __fish_prompt_accept_line
end
