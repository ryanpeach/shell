# Using "noble" ubuntu as a base image at the time of writing
# TODO: Brew does not work on ARM yet, so we have to compile a lot of things from source
#       When it does work, we can use homebrew/brew as a base image and replace
#       a lot of the below with brew installs
#       REF: https://github.com/orgs/Homebrew/discussions/3612
FROM debian:latest

# New user
WORKDIR /home/root
ENV HOME=/home/root

# kubectl stuff
RUN curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | sudo tee /etc/apt/trusted.gpg.d/kubernetes.gpg > /dev/null
RUN echo "deb https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list

# Installs
RUN apt-get update && \
  apt-get install -y \
  linux-tools-generic \
  software-properties-common \
  build-essential \
  curl \
  libssl-dev \
  libbz2-dev \
  git \
  lua5.1 \
  gnupg \
  fd-find \
  fzf \
  ripgrep \
  locales \
  rustup \
  zsh \
  wget \
  nano \
  tmux \
  vim \
  just \
  python3 \
  python3-pip \
  pipx \
  golang-go \
  fonts-powerline \
  tree \
  sed \
  gawk \
  jq \
  libsqlite3-dev \
  unzip \
  file \
  apt-transport-https \
  ca-certificates \
  cmake \
  graphviz \
  ninja-build \
  gettext \
  libffi-dev \
  luarocks \
  fakeroot \
  devscripts \
  rsync \
  equivs \
  kubectl \
  munge \
  slurm-wlm \
  libreadline-dev && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

# set up locale
RUN locale-gen en_US.UTF-8

# Install neovim
# This is to get latest
RUN git clone https://github.com/neovim/neovim && \
  cd neovim && \
  make CMAKE_BUILD_TYPE=RelWithDebInfo && \
  cd build && \
  cpack -G DEB && \
  dpkg -i nvim-linux64.deb && \
  nvim --version

# Install Helm
RUN curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 && \
  chmod 700 get_helm.sh && \
  ./get_helm.sh && \
  helm version

# Install GitHub CLI
RUN curl -sS https://webi.sh/gh | sh && gh --version


# Install tfenv
RUN git clone --depth=1 https://github.com/tfutils/tfenv.git $HOME/.tfenv
RUN .tfenv/bin/tfenv install latest

# Go installs
ENV PATH="$HOME/go/bin:$PATH"
RUN go install github.com/terraform-docs/terraform-docs@v0.18.0 \
  && terraform-docs --version \
  && go install github.com/mikefarah/yq/v4@latest \
	&& yq --version \
  && go install github.com/ankitpokhrel/jira-cli/cmd/jira@latest \
	&& jira --help \
  && go install github.com/jesseduffield/lazygit@latest \
	&& lazygit --help \
  && go install github.com/direnv/direnv@latest \
	&& direnv --version \
	&& go install github.com/derailed/k9s@latest \
	&& k9s --version \

# Install pyenv
RUN curl https://pyenv.run | bash
ENV PYENV_ROOT=$HOME/.pyenv
ENV PATH=$PYENV_ROOT/shims:$PYENV_ROOT/bin:$PATH

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
  pyright \
  ruff-lsp \
  ansible \
  aws-parallelcluster

RUN pip install \
  setuptools \
  numpy \
  scipy

# Get Rust
RUN rustup default stable && \
    rustup toolchain install stable && \
    rustup component add rust-src rustfmt clippy rust-analyzer
RUN cargo --version && \
    cargo clippy --version && \
    cargo fmt --version && \
    rust-analyzer --version

# Install rust things
ENV PATH="/home/root/.cargo/bin:$PATH"
RUN cargo install \
    git-delta \
    zoxide \
    bat \
    eza

# Install Oh My Zsh
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
ENV ZSH_CUSTOM=/home/user/.oh-my-zsh/custom
RUN git clone https://github.com/zsh-users/zsh-autosuggestions $ZSH_CUSTOM/plugins/zsh-autosuggestions
RUN git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting
RUN git clone --depth=1 https://github.com/romkatv/powerlevel10k.git $ZSH_CUSTOM/themes/powerlevel10k

# luarocks installs
ENV PATH="/usr/local/lib/luarocks/bin/:$HOME/.luarocks/bin/:$PATH"
RUN luarocks config local_by_default true
RUN luarocks install --server=https://luarocks.org/dev luaformatter

# Install nvm in the current home directory
ENV NVM_DIR="$HOME/.nvm"
RUN git clone https://github.com/nvm-sh/nvm.git "$NVM_DIR" && \
  cd "$NVM_DIR" && \
  git checkout `git describe --abbrev=0 --tags --match "v[0-9]*" $(git rev-list --tags --max-count=1)`

# Install node
RUN \. "$NVM_DIR/nvm.sh" \
  && nvm install node

# Install stuff with npm
RUN \. "$NVM_DIR/nvm.sh" \
  && npm install -g prettier pyright twilio-cli 

# Verify installations
RUN \. "$NVM_DIR/nvm.sh" \
    && node --version \
    && npm --version \
    && prettier --version

# Copies
COPY bin bin
COPY home/ .
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
