FROM ubuntu:latest

# Create the user
USER rgpeach10

# set up locale
RUN locale-gen en_US.UTF-8

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
  linuxbrew-wrapper \
  locales \
  nodejs \
  zsh \
  wget \
  nano \
  npm \
  fonts-powerline

# terminal colors with xterm
ENV TERM xterm

# Install Oh My Zsh
RUN wget https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh -O - | zsh || true

# Install neovim
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux64.tar.gz
sudo rm -rf /opt/nvim
sudo tar -C /opt -xzf nvim-linux64.tar.gz

# start zsh
CMD [ "zsh" ]
