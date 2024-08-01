FROM ubuntu:latest

# Copies
COPY ./bin $HOME/bin
COPY .zshrc $HOME/.zshrc

# Installs
RUN apt update && \
  apt install -y \
  curl \
  git-core \
  gnupg \
  fd-find \
  fzf \
  ripgrep \
  locales \
  nodejs \
  zsh \
  wget \
  nano \
  npm \
  python3 \
  python3-pip \
  fonts-powerline

# Install neovim
RUN curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux64.tar.gz && \
    rm -rf /opt/nvim && \
    tar -C /opt -xzf nvim-linux64.tar.gz

# Install Oh My Zsh
RUN wget https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh -O - | zsh || true

# Create the user
USER rgpeach10

# set up locale
RUN locale-gen en_US.UTF-8

# terminal colors with xterm
ENV TERM xterm

# start zsh
CMD [ "zsh" ]
