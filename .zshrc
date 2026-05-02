# ~/.zshrc — Portable zsh configuration
# Designed for easy replication across macOS and Linux machines.

# =============================================================================
# History
# =============================================================================
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=100000
setopt INC_APPEND_HISTORY       # Append after each command
setopt SHARE_HISTORY            # Share history across sessions
setopt HIST_IGNORE_ALL_DUPS     # Remove older duplicates
setopt HIST_FIND_NO_DUPS        # Don't show duplicates in search
setopt HIST_EXPIRE_DUPS_FIRST   # Expire duplicates first when trimming

# =============================================================================
# General options
# =============================================================================
setopt AUTO_CD                  # cd by typing directory name
setopt AUTO_PUSHD               # cd pushes to directory stack
setopt PUSHD_IGNORE_DUPS        # Don't store duplicates in stack
setopt NO_BEEP                  # No bell
setopt EXTENDED_GLOB            # Extended globbing

# =============================================================================
# Plugins
# =============================================================================
ZSH_PLUGINS_DIR="$HOME/.local/share/zsh"

# zsh-autosuggestions
if [[ -f "$ZSH_PLUGINS_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
  source "$ZSH_PLUGINS_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh"
  ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'
fi

# fzf-tab (must be loaded before syntax-highlighting but after compinit)
if [[ -f "$ZSH_PLUGINS_DIR/fzf-tab/fzf-tab.zsh" ]]; then
  source "$ZSH_PLUGINS_DIR/fzf-tab/fzf-tab.zsh"
fi

# zsh-syntax-highlighting — MUST be last
if [[ -f "$ZSH_PLUGINS_DIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
  source "$ZSH_PLUGINS_DIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi

# =============================================================================
# fzf keybindings
# =============================================================================
# Only load if fzf is installed (via package manager or otherwise)
if (( $+commands[fzf] )); then
  # Use fzf's official shell integration if available
  if [[ -f "/opt/homebrew/opt/fzf/shell/key-bindings.zsh" ]]; then
    source "/opt/homebrew/opt/fzf/shell/key-bindings.zsh"
  elif [[ -f "/usr/share/fzf/key-bindings.zsh" ]]; then
    source "/usr/share/fzf/key-bindings.zsh"
  else
    # Minimal fallback: just bind Ctrl+R
    zle -N fzf-history-widget 2>/dev/null || bindkey '^R' fzf-history-widget 2>/dev/null
  fi
fi

# fzf-tab configuration
zstyle ':fzf-tab:*' use-fzf-preview-widget yes
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

# =============================================================================
# zoxide (directory jumping)
# =============================================================================
if (( $+commands[zoxide] )); then
  eval "$(zoxide init zsh)"
  alias j='z'
fi

# =============================================================================
# Starship prompt
# =============================================================================
if (( $+commands[starship] )); then
  eval "$(starship init zsh)"
fi

# =============================================================================
# Colored man pages
# =============================================================================
export LESS_TERMCAP_mb=$'\E[1;32m'    # begin bold
export LESS_TERMCAP_md=$'\E[1;32m'    # begin bold
export LESS_TERMCAP_me=$'\E[0m'       # end mode
export LESS_TERMCAP_se=$'\E[0m'       # end standout-mode
export LESS_TERMCAP_so=$'\E[1;33m'    # begin standout-mode (info box)
export LESS_TERMCAP_ue=$'\E[0m'       # end underline
export LESS_TERMCAP_us=$'\E[1;4;36m'  # begin underline

# =============================================================================
# Aliases
# =============================================================================
# General
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'

# Ruby / Bundler
alias be='bundle exec'
alias bes='bundle exec rails s'

# Git
alias g='git'
alias gst='git status'
alias gc='git commit -v'
alias gcm='git commit -m'
alias gca='git commit -v -a'
alias gcma='git commit -v -a -m'
alias gp='git push'
alias gpf='git push --force-with-lease'
alias gl='git pull'
alias gb='git branch -vv'
alias gba='git branch -avv'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gd='git diff'
alias gds='git diff --staged'
alias ga='git add'
alias gaa='git add -A'
alias gsu='git submodule update --init --recursive'
alias glog='git log --oneline --graph --decorate'
alias gloga='git log --oneline --graph --decorate --all'
alias grh='git reset HEAD'
alias grhh='git reset HEAD --hard'
alias gcl='git clone'

# Misc — use nicer tools if available
if (( $+commands[bat] )); then
  alias cat='bat'
fi
if (( $+commands[fd] )); then
  alias find='fd'
fi
alias ls='ls -G' 2>/dev/null || alias ls='ls --color=auto'
alias grep='grep --color=auto'

# =============================================================================
# PATH additions
# =============================================================================
export PATH="$HOME/bin:$PATH"

# Homebrew-specific paths (macOS with Apple Silicon)
if [[ "$(uname)" == "Darwin" ]] && [[ -d "/opt/homebrew" ]]; then
  export PATH="/opt/homebrew/opt/grep/libexec/gnubin:$PATH"
  export PATH="/opt/homebrew/opt/libpq/bin:$PATH"
  export PATH="/opt/homebrew/opt/mysql-client@8.4/bin:$PATH"
fi

# =============================================================================
# Version managers (only if installed)
# =============================================================================
# rbenv
if (( $+commands[rbenv] )); then
  eval "$(rbenv init - zsh)"
fi

# pyenv
if (( $+commands[pyenv] )); then
  export PYENV_ROOT="$HOME/.pyenv"
  export PATH="$PYENV_ROOT/bin:$PATH"
  eval "$(pyenv init -)"
fi

# nvm
if [[ -s "/opt/homebrew/opt/nvm/nvm.sh" ]]; then
  export NVM_DIR="$HOME/.nvm"
  source "/opt/homebrew/opt/nvm/nvm.sh"
  source "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"
elif [[ -s "$HOME/.nvm/nvm.sh" ]]; then
  export NVM_DIR="$HOME/.nvm"
  source "$NVM_DIR/nvm.sh"
fi

# =============================================================================
# Shell completion
# =============================================================================
autoload -Uz compinit
compinit
