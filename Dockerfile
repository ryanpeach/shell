# Start with a smaller base image
FROM ubuntu:latest

# Set environment variables for non-interactive apt-get
ENV DEBIAN_FRONTEND=noninteractive

# Installs and cleanup in a single RUN statement to minimize layers
RUN apt-get update && \
  apt-get install -y --no-install-recommends \
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
  cmake \
  graphviz \
  libreadline-dev && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

# set up locale
RUN locale-gen en_US.UTF-8

# Install Lua and remove the tarball to save space
RUN curl -R -O -L http://www.lua.org/ftp/lua-5.3.5.tar.gz && \
  tar -zxf lua-5.3.5.tar.gz && \
  cd lua-5.3.5 && \
  make linux test && \
  make install && \
  cd .. && \
  rm -rf lua-5.3.5 lua-5.3.5.tar.gz && \
  lua -v

# Install Luarocks and remove the tarball to save space
RUN wget https://luarocks.github.io/luarocks/releases/luarocks-3.11.1.tar.gz && \
  tar -zxf luarocks-3.11.1.tar.gz && \
  cd luarocks-3.11.1 && \
  ./configure --with-lua-include=/usr/local/include && \
  make && \
  make install && \
  cd .. && \
  rm -rf luarocks-3.11.1 luarocks-3.11.1.tar.gz && \
  luarocks --version

# Get kubectl
RUN curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg && \
    chmod 644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg && \
    echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list && \
    chmod 644 /etc/apt/sources.list.d/kubernetes.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends kubectl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    kubectl version --client

# Install Helm
RUN curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 && \
  chmod 700 get_helm.sh && \
  ./get_helm.sh && \
  rm get_helm.sh && \
  helm --version

# Add the GitHub CLI repository and install the GitHub CLI
RUN mkdir -p -m 755 /etc/apt/keyrings \
    && wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
    && chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt-get update \
    && apt-get install -y --no-install-recommends gh && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* & \
    gh --version

# Create a non-root user
RUN useradd -ms /bin/zsh rgpeach10
USER rgpeach10
WORKDIR /home/rgpeach10
ENV HOME=/home/rgpeach10

# Install Oh My Zsh
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Install tfenv
RUN git clone --depth=1 https://github.com/tfutils/tfenv.git $HOME/.tfenv && \
    .tfenv/bin/tfenv install latest

# Go installs
ENV PATH="/home/rgpeach10/go/bin:$PATH"
RUN go install github.com/terraform-docs/terraform-docs@v0.18.0 && \
    terraform-docs --version && \
    go install github.com/ankitpokhrel/jira-cli/cmd/jira@latest && \
    jira --help

# Install pyenv
RUN git clone https://github.com/pyenv/pyenv.git .pyenv && \
    cd .pyenv && src/configure && make -C src || true
ENV PYENV_ROOT=$HOME/.pyenv
ENV PATH=$PYENV_ROOT/shims:$PYENV_ROOT/bin:$PATH

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
    rustup component add rust-src rustfmt clippy rust-analyzer && \
    cargo --version && \
    cargo clippy --version && \
    cargo fmt --version && \
    rust-analyzer --version

# Install zsh plugins
ENV ZSH_CUSTOM=/home/rgpeach10/.oh-my-zsh/custom
RUN git clone https://github.com/zsh-users/zsh-autosuggestions $ZSH_CUSTOM/plugins/zsh-autosuggestions && \
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting && \
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git $ZSH_CUSTOM/themes/powerlevel10k

# luarocks installs
ENV PATH="/usr/local/lib/luarocks/bin/:$HOME/.luarocks/bin/:$PATH"
RUN luarocks config local_by_default true && \
    luarocks install --server=https://luarocks.org/dev luaformatter

# Install nvm in the current home directory
ENV NVM_DIR="$HOME/.nvm"
RUN git clone https://github.com/nvm-sh/nvm.git "$NVM_DIR" && \
  cd "$NVM_DIR" && \
  git checkout `git describe --abbrev=0 --tags --match "v[0-9]*" $(git rev-list --tags --max-count=1)`

# Gotta go back to root to install node
USER root

# Install node
RUN \. "$NVM_DIR/nvm.sh" && nvm install node

# Install stuff with npm
RUN npm install -g prettier

# Switch back to user
USER rgpeach10

# Verify installations
RUN node --version && \
    npm --version && \
    prettier --version

# Copies
COPY --chown=rgpeach10 bin bin
COPY --chown=rgpeach10 home/ .
RUN git config --global core.excludesFile '~/.gitignore_global' && \
    git config --global pull.rebase true && \
    git config --global --add --bool push.autoSetupRemote true

# Get neovim to download all its stuff
RUN nvim --headless "+Lazy! sync" +qa

# Chmod so that these files are runnable
RUN find bin -type f -exec chmod +x {} \;

# terminal colors with xterm
ENV TERM=xterm-256color

# Now we are going to assume you are going to mount a directory to /home/rgpeach10/mnt
WORKDIR /home/rgpeach10/mnt

# start zsh
CMD [ "zsh" ]
