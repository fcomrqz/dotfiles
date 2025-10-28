if status --is-interactive
    # ------
    # direnv
    # ------
    set -x DIRENV_LOG_FORMAT ""
    direnv hook fish | source

    # --------
    # homebrew
    # --------
    fish_add_path /opt/homebrew/bin

    # ---
    # bun
    # ---
    set --export BUN_INSTALL "$HOME/.bun"
    set --export PATH $BUN_INSTALL/bin $PATH

    # --------
    # Orbstack
    # --------
    source ~/.orbstack/shell/init2.fish 2>/dev/null || :

    # --------
    # env vars
    # --------
    set -Ux GH_TOKEN (gh auth token)
    set -Ux EDITOR micro
    set -Ux BAT_THEME ansi
    set -Ux GEMINI_SANDBOX true

    set -U fish_greeting

    # ------
    # Colors
    # ------
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

    # --------------------------
    # Dark mode (Apple Terminal)
    # --------------------------
    if test "$TERM_PROGRAM" = Apple_Terminal
        set is_dark_mode (osascript -e 'tell application "System Events" to tell appearance preferences to return dark mode' 2> /dev/null)

        if test $status -eq 0
            if $is_dark_mode
                osascript -e 'tell application "Terminal"
                  set current settings of tabs of windows to settings set "dark"
                end tell'
            end
        end
    end

    # -----------
    # Keybindings
    # -----------

    bind \cO open_project
    bind \cR open_history_search
    bind \e\( kill-word
end
