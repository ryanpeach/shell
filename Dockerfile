FROM ubuntu:latest

# Installs
RUN apt-get update && \
  apt-get install -y \
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

# Install Oh My Zsh
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Copies
COPY ./bin $HOME/bin
COPY .zshrc $HOME/.zshrc

# set up locale
RUN locale-gen en_US.UTF-8

# New user
RUN useradd -ms /bin/zsh rgpeach10
USER rgpeach10
WORKDIR /home/rgpeach10

# terminal colors with xterm
ENV TERM xterm

# start zsh
CMD [ "zsh" ]
