# This where you typically mount your home directory
# but it can be overwritten in your .zprofile
if [ -z "$MNT" ]; then
    export MNT=$HOME
fi

if [ -z "$SHELL_MNT_DIR" ]; then
    SHELL_MNT_DIR="$MNT/shell"
fi

# If $MNT is not $HOME, then we are running in docker
if [[ "$MNT" != "$HOME" ]]; then
    export IS_DOCKER=true
fi

# If you come from bash you might have to change your $PATH.
export PATH=$HOME/bin:/usr/local/bin:$HOME/.local/bin:$PATH:/opt/homebrew/bin:/home/linuxbrew/.linuxbrew/bin:$HOME/.cargo/bin

# Load private info location
if [ -z "$ZSHRC_PRIVATE_LOC" ]; then
    ZSHRC_PRIVATE_LOC=$MNT
fi

# Load private info location
if [ -f "$ZSHRC_PRIVATE_LOC/.zshrc.private.local" ]; then
    source $ZSHRC_PRIVATE_LOC/.zshrc.private.local
elif [ -f "$ZSHRC_PRIVATE_LOC/.zshrc.private" ]; then
    source $ZSHRC_PRIVATE_LOC/.zshrc.private
else
    echo "No .zshrc.private or .zshrc.private.local found at '$ZSHRC_PRIVATE_LOC'"
    echo "You should create this to add secret information to your session"
    echo "Usually you put it in your home directory or in the directory"
    echo "mounted to this containers $MNT. However, wherever you put it, you can"
    echo "always override the location by overriding the ZSHRC_PRIVATE_LOC env variable"
fi

# This is our github copilot hosts file
# make a symbolic link to $MNT
if [[ $IS_DOCKER ]]; then
    mkdir -p ~/.config/github-copilot
    if ! [ -f "$MNT/.config/github-copilot/hosts.json" ]; then
        echo "No hosts.json found in $MNT/.config/github-copilot/hosts.json"
    else
        ln -s $MNT/.config/github-copilot/hosts.json ~/.config/github-copilot/hosts.json
    fi
fi

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
plugins=(git wd aws direnv branch github golang helm kubectl python virtualenv vi-mode zsh-autosuggestions zsh-syntax-highlighting)

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

# uv aliases
alias pip='uv pip'
alias pipx='uv tool'
alias poetry='uv'
alias pyenv='uv python'
alias virtualenv='uv venv'
alias venv='uv venv'
alias flake8='ruff check'
alias black='ruff format'

# Linux replacements
alias cat='bat'

# NeoVim
export PATH="$PATH:/opt/nvim-linux64/bin"
export GIT_EDITOR=nvim
alias oldvim="vim"
alias v="nvim"
alias vi="nvim"
alias vim="nvim"

# Venv
alias venv="uv venv"
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
alias ripgrep='rg'
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

# I am going to set up neofetch to run on clear, because I often have a local terminal and this terminal open at the same time
# and I want to clearly see which is which
alias trueclear="clear"
alias clear="trueclear && neofetch"

## =============== Exit =========================
## Because the shell has ~/shell inside its own filesystem
## we want to protect any work we are doing in this filesystem
## This will prevent you from exiting the shell if you have uncommitted changes in ~/shell
## ==============================================

function on_exit() {
    # Check if ~/shell is a git repository
    if [ -d ~/shell/.git ]; then
        cd ~/shell
        # Check if working directory is clean (porcelain state)
        if [ -z "$(git status --porcelain)" ]; then
            # Working directory is clean, allow exit
            echo "Exiting, ~/shell is clean."
            return 0  # Proceed with exit
        else
            # Working directory has uncommitted changes
            echo "~/shell has uncommitted changes. Exit canceled."
            return 1  # Prevent exit
        fi
    else
        # ~/shell is not a git repository, allow exit
        echo "~/shell is not a git repository."
        return 0  # Proceed with exit
    fi
}

if [[ $IS_DOCKER ]]; then
    trap on_exit SIGHUP EXIT
fi

# I have a problem with not installing pre-commit on all my repos
# So this will force me to
check_pre_commit() {
    # Check for the presence of .pre-commit-config.yaml or .pre-commit-config.yml
    if [[ -f ".pre-commit-config.yaml" || -f ".pre-commit-config.yml" ]]; then
        # Check if .pre-commit-installed exists
        if [[ ! -f ".pre-commit-installed" ]]; then
            echo "Found pre-commit config file. Running pre-commit install..."
            pre-commit install  # Run the pre-commit install command

            if [[ $? -eq 0 ]]; then  # Check if the pre-commit install was successful
                touch ".pre-commit-installed"  # Create .pre-commit-installed file
                echo "Pre-commit installed and marked as installed in this directory."
            else
                echo "Pre-commit installation failed."
            fi
        else
            echo "Pre-commit already installed in this directory."
        fi
    fi
}

# Add the function to run every time you change directories using chpwd hook
add-zsh-hook chpwd check_pre_commit

# Neofetch
neofetch

# deno
source "$HOME/.deno/env"
