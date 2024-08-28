setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

bindkey -e
bindkey '^[[5;5~' history-search-backward
bindkey '^[[6;5~' history-search-backward

# brew install zsh-fast-syntax-highlighting
source /usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/local/opt/zsh-fast-syntax-highlighting/share/zsh-fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh

export PATH=/opt/homebrew/bin:$PATH
export PATH=/opt/homebrew/sbin:$PATH

eval "$(direnv hook zsh)"

eval "$(starship init zsh)"

export BAT_THEME="ansi"

function preexec() {
  echo -ne "\033]0;$(basename "$(dirname "$(pwd)")")/$(basename "$(pwd)")  ·  $1\007"
}

function precmd() {
  echo -ne "\033]0;$(basename "$(dirname "$(pwd)")")/$(basename "$(pwd)")  ·  zsh\007"
}

# git log | gum filter | awk '{print $1}' | pbcopy
function openProject() {
  local project_dir
  project_dir=$(find ~/Developer -type d -maxdepth 2 -mindepth 2 | sed "s|^/Users/fran/Developer/||" | gum filter --placeholder="Open project..." --height 10)

  if [[ -n "$project_dir" ]]; then
    cd ~/Developer/"$project_dir"
    echo -ne "\033]0;$(basename "$(dirname "$(pwd)")")/$(basename "$(pwd)")  ·  zsh\007"
  fi
  zle reset-prompt
}

autoload -Uz openProject
zle -N openProject

bindkey '^O' openProject

# function killProcess() {
#   ps -eo pid,user,command | grep "$(whoami)" | awk '{split($3, path, "/"); print $1, path[length(path)], $4, $5, $6, $7, $8, $9}' | gum filter --placeholder="Kill process..." --height 10
# }

# function editLastCommitMessage() {
#   local type
#   local scope
#   local message
#   type=$(gum choose 'fix' 'feat' 'refactor')
#   # git commit --ammend -m $(gum input)
# }

# autoload -Uz editLastCommitMessage
# zle -N editLastCommitMessage

# bindkey 'µ' editLastCommitMessage

# bun completions
[ -s "/Users/fran/.bun/_bun" ] && source "/Users/fran/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
. "/Users/fran/.deno/env"