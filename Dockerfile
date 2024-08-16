# Stage 1: Build environment to install emerge and perform updates
FROM alpine:latest as builder

# Update the environment and install necessary tools
RUN apk update && apk upgrade

# Build dependencies
RUN apk add \
  make \
  cmake \
  g++ \
  gcc \
  gfortran \
  zlib-dev \
  libffi-dev \
  linux-headers \
  readline-dev \
  openssl-dev \
  sqlite-dev \
  bzip2-dev \
  xz-dev

# Archive tools
RUN apk add --no-cache unzip tar gzip patch

# Network tools
RUN apk add --no-cache curl wget rsync

# System apps
RUN apk add --no-cache sed gawk

# Languages
RUN apk add --no-cache go rust lua lua-dev luarocks

# Editors
RUN apk add --no-cache neovim

# Miscellaneous tools
RUN apk add --no-cache jq neofetch tmux

# Shells and Zsh plugins
RUN apk add --no-cache zsh zsh-autosuggestions zsh-syntax-highlighting zsh-completions

# Git and graphviz
RUN apk add --no-cache git graphviz

# Clean up unnecessary files and dependencies
RUN rm -rf /var/cache/apk/*

# Dont use apk below this line
# =============================================================

# We don't actually need to create a new user
# Just set a reasonable home directory
WORKDIR /home/root
ENV HOME=/home/root

# Install pyenv
RUN curl https://pyenv.run | bash
ENV PYENV_ROOT=$HOME/.pyenv
ENV PATH=$PYENV_ROOT/shims:$PYENV_ROOT/bin:$PATH

# Create some pyenv environments
RUN pyenv install 3.11 && \
    pyenv global 3.11 && \
    pyenv rehash && \
    pip install --upgrade pip && \
    rm -rf $PYENV_ROOT/sources

# TODO: Move thiese up
RUN apk add --no-cache openblas-dev lapack-dev

# Python package installs
RUN pip install --no-cache-dir setuptools
RUN pip install --no-cache-dir numpy scipy pandas
RUN pip install --no-cache-dir pynvim
RUN pip install --no-cache-dir pipx
RUN pip install --no-cache-dir userpath
RUN rm -rf ~/.cache/pip

# Pipx installs
ENV PATH="$HOME/.local/bin:$PATH"
RUN pipx install aider-chat
RUN pipx install pre-commit
RUN pipx install poetry
RUN pipx install ruff
RUN pipx install ipython
RUN pipx install ipdb
RUN pipx install awscli
RUN pipx install pyright
RUN pipx install ruff-lsp
RUN pipx install just
RUN pipx install thefuck
RUN pipx install aws-parallelcluster
RUN rm -rf /root/.local/pipx/shared ~/.cache/pipx

# Clean up
RUN find / -type f -name '*.py[co]' -delete
RUN find $PYENV_ROOT -name 'tests' -type d -exec rm -rf {} +
RUN find $PYENV_ROOT -name '__pycache__' -type d -exec rm -rf {} +

# luarocks installs
ENV PATH="/usr/local/lib/luarocks/bin/:$HOME/.luarocks/bin/:$PATH"
RUN luarocks-5.1 config local_by_default true
RUN luarocks-5.1 install --server=https://luarocks.org/dev luaformatter

# Install nvm in the current home directory
ENV NVM_DIR="$HOME/.nvm"
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | bash

# Install node
RUN . "$NVM_DIR/nvm.sh" \
  && nvm install node

# npm installs
RUN . "$NVM_DIR/nvm.sh" \
  npm install -g \
    prettier \
    pyright \
    twilio-cli

# Install tfenv
RUN git clone --depth=1 https://github.com/tfutils/tfenv.git $HOME/.tfenv
RUN .tfenv/bin/tfenv install latest

# Cargo installs
RUN cargo install git-delta
RUN cargo install ripgrep
RUN cargo install zoxide
RUN cargo install bat
RUN cargo install fd
RUN cargo install eza
RUN cargo clean

# Go installs
ENV PATH="$HOME/go/bin:$PATH"
RUN go install github.com/terraform-docs/terraform-docs@v0.18.0 && terraform-docs --version
RUN go install github.com/mikefarah/yq/v4@latest && yq --version
RUN go install github.com/ankitpokhrel/jira-cli/cmd/jira@latest && jira --help
RUN go install github.com/helmfile/helmfile@latest && helmfile --version
RUN go install github.com/jesseduffield/lazygit@latest && lazygit --help
RUN go install github.com/direnv/direnv@latest && direnv --version
RUN go install github.com/derailed/k9s@latest && k9s --version
RUN go install github.com/kubernetes/kubectl@latest && kubectl version --client
RUN go install github.com/cli/cli@latest && gh --version
RUN go install github.com/junegunn/fzf@latest && fzf --version
RUN go install github.com/helm/helm@latest && helm version
RUN go clean -cache -modcache -i -r

# Slurm
WORKDIR /tmp
RUN wget https://download.schedmd.com/slurm/slurm-<version>.tar.bz2 && \
    tar -xaf slurm-24.05.2.tar.bz2 && \
    cd slurm-24.05.2.tar.bz2 && \
    ./configure --prefix=/usr --sysconfdir=/etc/slurm --with-munge && \
    make && \
    make install && \
    ldconfig -n /usr/lib && \
    ldconfig -n /usr/lib64 && \
    rm -rf /var/cache/apk/* /tmp/slurm-*
WORKDIR /home/root

# Install Oh My Zsh
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
ENV ZSH_CUSTOM=/home/user/.oh-my-zsh/custom
RUN git clone https://github.com/zsh-users/zsh-autosuggestions $ZSH_CUSTOM/plugins/zsh-autosuggestions
RUN git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting
RUN git clone --depth=1 https://github.com/romkatv/powerlevel10k.git $ZSH_CUSTOM/themes/powerlevel10k

# Copies
COPY bin bin
COPY home/ .
RUN git config --global core.excludesFile '$HOME/.gitignore_global'
RUN git config --global pull.rebase true
RUN git config --global --add --bool push.autoSetupRemote true
RUN find $PYENV_ROOT -name '*.md' -delete
RUN find /usr/lib/python3.*/ -name 'locale' -exec rm -rf {} +

# Chmod so that these files are runnable
RUN find bin -type f -exec chmod +x {} \;

# Get neovim to download all its stuff
RUN nvim --headless "+Lazy! sync" +qa

# Second stage
# ==============================================================

# Stage 2: minimal image
FROM alpine:latest

# Copy the updated system from the builder stage
COPY --from=builder / /

# terminal colors with xterm
ENV TERM=xterm-256color

# We are still using root, but from a different home directory
# Then you are going to mount your home this home's mnt directory
ENV HOME=/home/root
WORKDIR /home/root/mnt

CMD ["/bin/zsh"]
