# clear at the beginning
if [ -z "$DEBUG" ]; then
    clear
fi

if [ -z "$MNT" ]; then
    MNT=$HOME
fi

# If you come from bash you might have to change your $PATH.
export PATH=$HOME/bin:/usr/local/bin:$HOME/.local/bin:$PATH:/opt/homebrew/bin

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
plugins=(git wd aws direnv branch github golang helm kubectl python virtualenv poetry-env vi-mode zsh-autosuggestions zsh-syntax-highlighting)

# Gotta source the oh-my-zsh script
export ZSH="$HOME/.oh-my-zsh"
source $ZSH/oh-my-zsh.sh

# ========================
# Non ZSH-Related Configs
# ========================

# Aliases
alias tf='terraform'
alias k='kubectl'
alias g='git'
alias gs='git status'
alias gA='git add -A'
alias ga='git add'
alias commit='git commit -m'
alias co='git commit -m'
alias checkout='git checkout'
alias ch='git checkout'
alias push='git push'
alias pull='git pull'
alias gf='git fetch --all'
alias gas='git add -A && git status'
alias gd='git diff'
alias gds='git diff --staged'
alias grc='git rebase --continue'
alias pr='gh pr create'

# Linux replacements
alias cat='bat'

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

# Luarocks
alias luarocks="luarocks-5.1"

# Venv
alias venv="python3 -m venv .venv"
alias activate="source .venv/bin/activate"

# nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# TFEnv
export PATH="$HOME/.tfenv/bin:$PATH"

# Go
export PATH="$(go env GOPATH)/bin:$PATH"

# Powerlevel 10k
source ~/.p10k.zsh

# fzf
# source /usr/share/bash-completion/completions/fzf
# source /usr/share/fzf/key-bindings.bash
source <(fzf --zsh)
alias fzfp='fzf --preview "bat --color=always --style=numbers --line-range=:500 {}"'

# zoxide
eval "$(zoxide init --cmd cd zsh)"

# eza
alias ls='eza -A'
alias tree='ls --tree'

# ripgrep
alias rg='batgrep'

# Keep history in a file
HISTFILE=$MNT/.zsh_history
HISTSIZE=1000000
SAVEHIST=1000000
setopt appendhistory

# This is a function you can run in your terminal to add build dependencies to your environment
build-deps () {
  apk add \
      gcc \
      g++ \
      gfortran \
      openblas-dev \
      lapack-dev \
      pkgconfig \
      linux-headers \
      musl-dev \
      cmake \
      zlib-dev \
      libffi-dev \
      readline-dev \
      openssl-dev \
      sqlite-dev \
      bzip2-dev \
      xz-dev \
      sshpass \
      patch \
      build-base \
      gcc-doc
}

# We need to make sure we don't loose our changes to our dotfiles when we close our docker container
# We also need to support running more than one docker container at a time
stow-shell() {
    if [ -z "$SHELL_MNT_DIR" ]; then
        SHELL_MNT_DIR="$HOME/mnt/shell"
    fi
    if [ -d "$SHELL_MNT_DIR" ]; then
        cd $SHELL_MNT_DIR
        if [ -z "$(git status --porcelain)" ]; then
            stow --adopt home
            git reset head --hard

            # home/.gitconfig is the one thing we dont want reflecting changes as git changes it a lot
            cp $SHELL_MNT_DIR/home/.gitconfig $HOME/.gitconfig
        else
            echo "Please git commit $SHELL_MNT_DIR then run stow-shell to make safely editing your shell files possible."
        fi
    else
        echo "WARNING: $SHELL_MNT_DIR not found. Editing shell files is not safe."
    fi
}


# I am going to set up neofetch to run on clear, because I often have a local terminal and this terminal open at the same time
# and I want to clearly see which is which
alias trueclear="clear"
alias clear="trueclear && neofetch"

## =============== NOTES ========================
## Keep all your edits above this line, these
## should be executed last
## ==============================================

# Uncomment this line to get this zshrc file to work on a local machine!
# First obviously you need to make a $HOME/.zshrc.private.local to source
# export ZSH_PRIVATE_LOC=$HOME/.zshrc.private.local

# Load private info location
if [ -z "$ZSH_PRIVATE_LOC" ]; then
    ZSH_PRIVATE_LOC=$MNT/.zshrc.private
fi

# If it does not exist, inform them
if [ ! -f "$ZSH_PRIVATE_LOC" ]; then
    echo "No .zshrc.private found at '$ZSH_PRIVATE_LOC'"
    echo "You should create this to add secret information to your session"
    echo "Usually you put it in your home directory or in the directory"
    echo "mounted to this containers $MNT. However, wherever you put it, you can"
    echo "always override the location by overriding the ZSH_PRIVATE_LOC env variable"
else
    source $ZSH_PRIVATE_LOC
fi

# Neofetch
clear
