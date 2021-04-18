starship init fish | source

set -Ux BAT_THEME ansi

set -U fish_greeting
set -U fish_color_command normal
set -U fish_color_param bryellow -b
set -U fish_color_quote brgreen -b
set -U fish_color_error brred -b
set -U fish_color_cancel brred -b
set -U fish_color_autosuggestion white
set -U fish_color_redirection cyan -b
set -U fish_color_end brmagenta -b
set -U fish_color_operator brmagenta -b
set -U fish_color_escape cyan
set -U fish_color_valid_path normal
# matching parenthesis
set -U fish_color_match white
set -U fish_color_selection green
set -U fish_color_search_match green


# Pager: selected element
set -U fish_pager_color_selected_background --background=brblack
set -U fish_pager_color_selected_prefix normal
set -U fish_pager_color_selected_completion normal
set -U fish_pager_color_selected_description normal

# Pager: background
set -U fish_pager_color_background --background=normal

# Pager: prefix string, i.e. the string that is to be completed
set -U fish_pager_color_prefix white
set -U fish_pager_color_secondary_prefix white

# Pager: completion itself, i.e. the proposed rest of the string
set -U fish_pager_color_completion white
set -U fish_pager_color_secondary_completion white

# Pager: description
set -U fish_pager_color_description white
set -U fish_pager_color_secondary_description white

# Pager:  progress bar at the bottom left corner
set -U fish_pager_color_progress brwhite -b --background=normal
