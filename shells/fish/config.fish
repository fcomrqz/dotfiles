starship init fish | source

set -Ux BAT_THEME ansi

set -U fish_prompt_pwd_dir_length 0
set -U fish_greeting

# Colors
set -U fish_color_command normal
set -U fish_color_param bryellow -b
set -U fish_color_quote brgreen -b
set -U fish_color_error brred -b
set -U fish_color_cancel red -b
set -U fish_color_autosuggestion brblack
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
set -U fish_pager_color_selected_background --background=brwhite
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

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/fran/google-cloud-sdk/path.fish.inc' ]; . '/Users/fran/google-cloud-sdk/path.fish.inc'; end

# Select Terminal Appearance from hour
if test (date '+%H') -lt 5; or test (date '+%H') -ge 18
osascript -e 'tell application "Terminal"
           set current settings of tabs of windows to settings set "dark" # Theme name
         end tell'
end

# tabtab source for packages
# uninstall by removing these lines
[ -f ~/.config/tabtab/fish/__tabtab.fish ]; and . ~/.config/tabtab/fish/__tabtab.fish; or true
