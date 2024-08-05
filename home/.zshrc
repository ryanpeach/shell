# clear at the beginning
if [ -z "$DEBUG" ]; then
    clear
fi

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="powerlevel10k/powerlevel10k"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git wd aws direnv branch github golang helm kubectl python pyenv virtualenv poetry-env vi-mode zsh-autosuggestions zsh-syntax-highlighting)

# Gotta source the oh-my-zsh script
export ZSH="$HOME/.oh-my-zsh"
source $ZSH/oh-my-zsh.sh

# ========================
# Non ZSH-Related Configs
# ========================

# Set up thefuck
eval $(thefuck --alias)

# Aliases
alias tf="terraform"
alias k="kubectl"
alias g="git"
alias gs="git status"
alias gA="git add -A"
alias ga="git add $@"
alias gc="git commit -m $@"
alias gas="git add -A && git status"
alias gd="git diff"
alias gds="git diff --staged"
alias gr='BRANCH=$(git rev-parse --abbrev-ref HEAD) && git checkout $1 && git pull && git checkout $BRANCH && git rebase $1'
alias grm='BRANCH=$(git rev-parse --abbrev-ref HEAD) && git checkout main && git pull && git checkout $BRANCH && git rebase main'

# Personal directories added to PATH
export PATH=$PATH:$HOME/bin

# NeoVim
export PATH="$PATH:/opt/nvim-linux64/bin"
export GIT_EDITOR=nvim
alias oldvim="vim"
alias v="nvim"
alias vi="nvim"
alias vim="nvim"

# Poetry
export POETRY_VIRTUALENVS_CREATE=true
export POETRY_VIRTUALENVS_IN_PROJECT=true
export POETRY_VIRTUALENVS_PREFER_ACTIVE_PYTHON=true

# Venv
alias venv="python3 -m venv .venv"
alias activate="source .venv/bin/activate"

# TFEnv
export PATH="$HOME/.tfenv/bin:$PATH"

# Rust
source $HOME/.cargo/env

# Go
export PATH="$(go env GOPATH)/bin:$PATH"

# Powerlevel 10k
source ~/.p10k.zsh

# nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Load private info location
if [ -z "$ZSH_PRIVATE_LOC" ]; then
    ZSH_PRIVATE_LOC=~/mnt/.zshrc.private
fi

# If it does not exist, inform them
if [ ! -f "$ZSH_PRIVATE_LOC" ]; then
    echo "No .zshrc.private found at '$ZSH_PRIVATE_LOC'"
    echo "You should create this to add secret information to your session"
    echo "Usually you put it in your home directory or in the directory"
    echo "mounted to this containers ~/mnt. However, wherever you put it, you can"
    echo "always override the location by overriding the ZSH_PRIVATE_LOC env variable"
else
    source $ZSH_PRIVATE_LOC
fi
