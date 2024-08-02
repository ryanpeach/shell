# Using "noble" ubuntu as a base image at the time of writing
FROM ubuntu:latest

# Installs
RUN apt-get update && \
  apt-get install -y --no-install-recommends \
  sudo \
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
  zsh \
  wget \
  nano \
  tmux \
  vim \
  neovim \
  npm \
  just \
  python3 \
  python3-pip \
  golang-go \
  fonts-powerline \
  tree \
  sed \
  gawk \
  libsqlite3-dev \
  unzip \
  apt-transport-https \
  ca-certificates \
  procps \
  file \
  && rm -rf /var/lib/apt/lists/*

# set up locale
RUN locale-gen en_US.UTF-8

# New user
RUN useradd -ms /bin/zsh rgpeach10

# Make it so brew can be installed by this user
RUN usermod -aG sudo linuxbrew &&  \
  mkdir -p /home/linuxbrew/.linuxbrew && \
  chown -R linuxbrew: /home/linuxbrew/.linuxbrew

# Switch to the user
USER rgpeach10
WORKDIR /home/rgpeach10
ENV HOME=/home/rgpeach10
RUN useradd -m -s /bin/zsh linuxbrew

# Install brew
RUN /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
USER root
RUN chown -R $CONTAINER_USER: /home/linuxbrew/.linuxbrew
ENV PATH="/home/linuxbrew/.linuxbrew/bin:${PATH}"
RUN git config --global --add safe.directory /home/linuxbrew/.linuxbrew/Homebrew
USER rgpeach10
RUN brew update
RUN brew doctor

# Install brew packages
RUN brew install \
    gh \
    helm \
    kubectl \
    tfenv \
    pyenv

# Install Oh My Zsh
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Install tfenv environments
RUN tfenv install latest

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
  black \
  ruff \
  numpy \
  ipython \
  ipdb \
  awscli

# Get Rust
RUN curl https://sh.rustup.rs -sSf | bash -s -- -y

# Install zsh plugins
ENV ZSH_CUSTOM=/home/rgpeach10/.oh-my-zsh/custom
RUN git clone https://github.com/zsh-users/zsh-autosuggestions $ZSH_CUSTOM/plugins/zsh-autosuggestions
RUN git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting
RUN git clone --depth=1 https://github.com/romkatv/powerlevel10k.git $ZSH_CUSTOM/themes/powerlevel10k

# Copies
COPY --chown=rgpeach10 bin bin
COPY --chown=rgpeach10 home/ .
RUN git config --global core.excludesFile '~/.gitignore_global'
RUN git config --global pull.rebase true
RUN git config --global --add --bool push.autoSetupRemote true

# Chmod so that these files are runnable
RUN find bin -type f -exec chmod +x {} \;

# terminal colors with xterm
ENV TERM=xterm-256color

# Now we are going to assume you are going to mount a directory to /home/rgpeach10/mnt
WORKDIR /home/rgpeach10/mnt

# start zsh
CMD [ "zsh" ]
