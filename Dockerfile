FROM ubuntu:latest

# Installs
RUN apt-get update && \
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
  fonts-powerline \
  tree \
  sed \
  gawk \
  openssh-client \
  openssh-server

# set up locale
RUN locale-gen en_US.UTF-8

# New user
RUN useradd -ms /bin/zsh rgpeach10
USER rgpeach10
WORKDIR /home/rgpeach10
ENV HOME /home/rgpeach10

# Install Oh My Zsh
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Install pyenv
RUN git clone https://github.com/pyenv/pyenv.git .pyenv
RUN cd .pyenv && src/configure && make -C src || true
ENV PYENV_ROOT $HOME/.pyenv
ENV PATH $PYENV_ROOT/shims:$PYENV_ROOT/bin:$PATH
RUN git clone https://github.com/pyenv/pyenv-virtualenv.git $PYENV_ROOT/plugins/pyenv-virtualenv

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
  ipdb

# Get Rust
RUN curl https://sh.rustup.rs -sSf | bash -s -- -y

# Install zsh plugins
ENV ZSH_CUSTOM /home/rgpeach10/.oh-my-zsh/custom
RUN git clone https://github.com/zsh-users/zsh-autosuggestions $ZSH_CUSTOM/plugins/zsh-autosuggestions
RUN git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting
RUN git clone --depth=1 https://github.com/romkatv/powerlevel10k.git $ZSH_CUSTOM/themes/powerlevel10k

# Copies
COPY --chown=rgpeach10 bin bin
COPY --chown=rgpeach10 .zshrc .zshrc
COPY --chown=rgpeach10 .p10k.zsh .p10k.zsh

# Chmod so that these files are runnable
RUN find bin -type f -exec chmod +x {} \;

# terminal colors with xterm
ENV TERM xterm

# Now we are going to assume you are going to mount a directory to /home/rgpeach10/mnt
WORKDIR /home/rgpeach10/mnt

# start zsh
CMD [ "zsh" ]
