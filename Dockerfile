# syntax=docker/dockerfile:1.4

# Use conditional ARG to specify the base image based on the target architecture
ARG TARGETARCH
ARG BASE_IMAGE_AMD64=archlinux:latest
ARG BASE_IMAGE_ARM64=agners/archlinuxarm:latest

# Use build arguments to switch between architectures
FROM ${TARGETARCH} == "amd64" ? ${BASE_IMAGE_AMD64} : ${BASE_IMAGE_ARM64} AS base

# Install base dependencies and yay (AUR helper)
RUN pacman -Syu --noconfirm && \
  pacman -S --noconfirm \
  base-devel \
  git \
  curl && \
  git clone https://aur.archlinux.org/yay.git /opt/yay && \
  cd /opt/yay && \
  makepkg -si --noconfirm && \
  rm -rf /opt/yay && \
  pacman -Scc --noconfirm

# Use yay to install all necessary packages, including AUR packages
RUN yay -Syu --noconfirm && \
  yay -S --noconfirm \
  bat \
  exa \
  neofetch \
  fd \
  fzf \
  ripgrep \
  rustup \
  zsh \
  wget \
  nano \
  tmux \
  vim \
  just \
  python \
  python-pip \
  pipx \
  go \
  ttf-dejavu \
  tree \
  sed \
  gawk \
  jq \
  sqlite \
  unzip \
  file \
  cmake \
  graphviz \
  ninja \
  gettext \
  libffi \
  fakeroot \
  devtools \
  slurm \
  readline \
  lua \
  luarocks \
  kubectl \
  helm \
  gh \
  neovim \
  python-setuptools \
  python-numpy \
  rust \
  pyenv \
  nvm \
  tfenv \
  terraform-docs \
  yq \
  jira-cli \
  helmfile \
  lazygit \
  k9s \
  git-delta \
  thefuck \
  aider-chat \
  pre-commit \
  poetry \
  ruff \
  ipython \
  ipdb \
  awscli \
  pyright \
  ruff-lsp \
  aws-parallelcluster \
  prettier \
  twilio-cli \
  --needed && \
  yay -Yc --noconfirm && \
  pacman -Scc --noconfirm

# Set up locale
RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
  locale-gen && \
  echo "LANG=en_US.UTF-8" > /etc/locale.conf

# New user
RUN useradd -ms /bin/zsh user
USER user
WORKDIR /home/user
ENV HOME=/home/user

# Install Oh My Zsh
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Install zsh plugins
ENV ZSH_CUSTOM=/home/user/.oh-my-zsh/custom
RUN git clone https://github.com/zsh-users/zsh-autosuggestions $ZSH_CUSTOM/plugins/zsh-autosuggestions
RUN git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting
RUN git clone --depth=1 https://github.com/romkatv/powerlevel10k.git $ZSH_CUSTOM/themes/powerlevel10k

# Install Node.js with nvm
ENV NVM_DIR="$HOME/.nvm"
RUN source /usr/share/nvm/init-nvm.sh && \
    nvm install --lts && \
    nvm use --lts

# Verify installations
RUN source /usr/share/nvm/init-nvm.sh && \
    node --version && \
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
