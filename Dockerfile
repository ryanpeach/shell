# Using "noble" ubuntu as a base image at the time of writing
# TODO: Brew does not work on ARM yet, so we have to compile a lot of things from source
#       When it does work, we can use homebrew/brew as a base image and replace
#       a lot of the below with brew installs
#       REF: https://github.com/orgs/Homebrew/discussions/3612
ARG BASE_TAG=main
FROM rgpeach10/brew-arm:${BASE_TAG}

USER root

# Installs
RUN apt-get update && \
  apt-get install -y software-properties-common && \
  add-apt-repository ppa:neovim-ppa/unstable && \
  apt-get update && \
  apt-get install -y \
  linux-tools-generic \
  build-essential \
  curl \
  git \
  gnupg \
  fd-find \
  fzf \
  ripgrep \
  locales \
  nodejs \
  rustup \
  zsh \
  wget \
  nano \
  tmux \
  vim \
  neovim \
  python3-neovim \
  npm \
  just \
  python3 \
  python3-pip \
  golang-go \
  fonts-powerline \
  tree \
  sed \
  jq \
  gawk \
  libsqlite3-dev \
  unzip \
  apt-transport-https \
  ca-certificates \
  cmake \
  graphviz \
  libreadline-dev && \
  apt-get clean

# set up locale
RUN locale-gen en_US.UTF-8

USER user
WORKDIR /home/user
ENV HOME=/home/user

RUN brew install \
  lua \
  luarocks \
  kubectl \
  helm \
  gh \
  tfenv \
  pyenv \
  jira \
  terraform-docs \
  nvm

# Install Oh My Zsh
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Install tfenv
RUN git clone --depth=1 https://github.com/tfutils/tfenv.git $HOME/.tfenv
RUN .tfenv/bin/tfenv install latest

# Go installs
ENV PATH="/home/user/go/bin:$PATH"

# Create some pyenv environments
RUN pyenv install 3.11 && \
    pyenv global 3.11 && \
    pyenv rehash

# Now default python installs in the root virtualenv
RUN pip install \
  thefuck \
  aider-chat \
  pre-commit \
  poetry \
  setuptools \
  ruff \
  numpy \
  ipython \
  ipdb \
  awscli \
  pynvim \
  ruff-lsp \
  pyright

# Get Rust
RUN rustup default stable && \
    rustup toolchain install stable && \
    rustup component add rust-src rustfmt clippy rust-analyzer
RUN cargo --version && \
    cargo clippy --version && \
    cargo fmt --version && \
    rust-analyzer --version

# Install zsh plugins
ENV ZSH_CUSTOM=/home/user/.oh-my-zsh/custom
RUN git clone https://github.com/zsh-users/zsh-autosuggestions $ZSH_CUSTOM/plugins/zsh-autosuggestions
RUN git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting
RUN git clone --depth=1 https://github.com/romkatv/powerlevel10k.git $ZSH_CUSTOM/themes/powerlevel10k

# luarocks installs
ENV PATH="/usr/local/lib/luarocks/bin/:$HOME/.luarocks/bin/:$PATH"
RUN luarocks config local_by_default true
RUN luarocks install --server=https://luarocks.org/dev luaformatter

# Gotta go back to root to install node
USER root

# Install node
RUN \. "$NVM_DIR/nvm.sh" && nvm install node

# Install stuff with npm
RUN npm install -g prettier

# Switch back to user
USER user

# Verify installations
RUN node --version && \
    npm --version && \
    prettier --version

# Copies
COPY --chown=user bin bin
COPY --chown=user home/ .
RUN git config --global core.excludesFile '~/.gitignore_global'
RUN git config --global pull.rebase true
RUN git config --global --add --bool push.autoSetupRemote true

# Get neovim to download all its stuff
RUN nvim --headless "+Lazy! sync" +qa

# Chmod so that these files are runnable
RUN find bin -type f -exec chmod +x {} \;

# terminal colors with xterm
ENV TERM=xterm-256color

# Now we are going to assume you are going to mount a directory to /home/user/mnt
WORKDIR /home/user/mnt

# start zsh
CMD [ "zsh" ]
