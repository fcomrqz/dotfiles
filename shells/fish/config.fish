if status --is-interactive
    set -x DIRENV_LOG_FORMAT ""
    direnv hook fish | source

    fish_add_path /opt/homebrew/bin

    function starship_transient_prompt_func
        echo ''
        starship module character
    end

    function starship_transient_rprompt_func
        echo ''
        starship module directory
        starship module git_branch
    end

    starship init fish | source
    enable_transience

    set -Ux BAT_THEME ansi

    set -U fish_prompt_pwd_dir_length 0
    set -U fish_greeting

    set -Ux GH_TOKEN (gh auth token)

    # Colors
    set -U fish_color_command normal
    set -U fish_color_param normal
    set -U fish_color_option yellow
    set -U fish_color_quote green
    set -U fish_color_error red
    set -U fish_color_cancel yellow
    set -U fish_color_autosuggestion brblack
    set -U fish_color_redirection cyan
    set -U fish_color_end magenta
    set -U fish_color_function magenta
    set -U fish_color_operator magenta
    set -U fish_color_escape cyan
    set -U fish_color_valid_path blue
    # matching parenthesis
    set -U fish_color_match white
    set -U fish_color_selection green
    set -U fish_color_search_match green

    # Pager: selected element
    set -U fish_pager_color_selected_background normal
    set -U fish_pager_color_selected_prefix normal
    set -U fish_pager_color_selected_completion normal
    set -U fish_pager_color_selected_description normal

    # Pager: background
    set -U fish_pager_color_background --background=normal

    # Pager: prefix string, i.e. the string that is to be completed
    set -U fish_pager_color_prefix brblack
    set -U fish_pager_color_secondary_prefix brblack

    # Pager: completion itself, i.e. the proposed rest of the string
    set -U fish_pager_color_completion brblack
    set -U fish_pager_color_secondary_completion brblack

    # Pager: description
    set -U fish_pager_color_description brblack
    set -U fish_pager_color_secondary_description brblack

    # Pager:  progress bar at the bottom left corner
    set -U fish_pager_color_progress white -b --background=normal

    # Toggle dark mode
    set is_dark_mode (osascript -e 'tell application "System Events" to tell appearance preferences to return dark mode' 2> /dev/null)

    if test $status -eq 0
        if $is_dark_mode
            osascript -e 'tell application "Terminal"
              set current settings of tabs of windows to settings set "dark"
            end tell'
        end
    end

    # bun
    set --export BUN_INSTALL "$HOME/.bun"
    set --export PATH $BUN_INSTALL/bin $PATH

    bind \cO open_project
    bind \cR open_history_search

    bind \ea git-add
    # bind \ec git-commit
    bind \es git-amend-no-edit
    bind \em git-amend
    # bind \et git-switch
    bind \er git-revert
    bind \eg open_gitui
    bind \e\( kill-word
end
