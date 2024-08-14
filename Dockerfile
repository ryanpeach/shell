# syntax=docker/dockerfile:1

FROM alpine:latest AS base

# arm64-specific stage
FROM base AS build-arm64

# Set the architecture and download Arch Linux ARM tarball
ADD http://os.archlinuxarm.org/os/ArchLinuxARM-aarch64-latest.tar.gz /arch-root

# amd64-specific stage
FROM base AS build-amd64

# Download the Arch Linux bootstrap tarball for x86_64
ADD https://archive.archlinux.org/iso/2024.08.01/archlinux-bootstrap-x86_64.tar.zst /arch-root.tar.zst

# Extract the tarball
RUN mkdir /arch-root && tar --use-compress-program=unzstd -xvf /arch-root.tar.zst -C /arch-root

# common steps
FROM build-${TARGETARCH} AS build

# Set the working directory to the new root
WORKDIR /arch-root

# Set up pacman keyring and install yay using chroot
RUN cd /arch-root && \
    chroot /arch-root /bin/bash -c "pacman-key --init && \
    pacman-key --populate archlinux && \
    pacman -Syu --noconfirm && \
    pacman -S --needed --noconfirm base-devel git && \
    git clone https://aur.archlinux.org/yay.git /opt/yay && \
    cd /opt/yay && \
    makepkg -si --noconfirm && \
    rm -rf /opt/yay"

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
  rustup \
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
    nvm use --lts && \
    && npm install -g \
      prettier \
      pyright \
      twilio-cli \
    && node --version \
    && npm --version \
    && prettier --version \
    && pyright --version \
    && twilio --version

# Tfenv
RUN tfenv install latest && \
    tfenv use latest

# Create some pyenv environments
RUN pyenv install 3.11 && \
    pyenv global 3.11 && \
    pyenv rehash

# Now default python installs in the root virtualenv
RUN pipx install \
  thefuck \
  aider-chat \
  pre-commit \
  poetry \
  ruff \
  ipython \
  ipdb \
  awscli \
  ruff-lsp \
  aws-parallelcluster

RUN pip install \
  setuptools \
  numpy \
  pynvim

# Get Rust
RUN rustup default stable && \
    rustup toolchain install stable && \
    rustup component add rust-src rustfmt clippy rust-analyzer
RUN cargo --version && \
    cargo clippy --version && \
    cargo fmt --version && \
    rust-analyzer --version

# Luarocks
RUN luarocks config local_by_default true
RUN luarocks install --server=https://luarocks.org/dev luaformatter

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
