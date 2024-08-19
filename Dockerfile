# Stage 1: Build environment to install emerge and perform updates
FROM alpine:edge AS builder

# We don't actually need to create a new user
# Just set a reasonable home directory
WORKDIR /home/root
ENV HOME=/home/root

# Get the full version (e.g., 3.15.0) and major version (e.g., 3.15)
RUN ALPINE_VERSION=$(cut -d '.' -f1,2 /etc/alpine-release) && \
    echo "http://dl-cdn.alpinelinux.org/alpine/edge/main" > /etc/apk/repositories && \
    echo "http://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories && \
    echo "http://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories

# Update package list
RUN apk update && apk upgrade

# Build dependencies
RUN apk add --no-cache \
  git \
  make \
  # Uncategorized dependencies \
    iputils \
    bind-tools \
    sshpass \
    openssh-client \
    openssh-server \
  # Archive tools \
    unzip \
    tar \
    gzip \
    patch \
  # Network tools \
    curl \
    wget \
    rsync \
  # System apps \
    sed \
    gawk \
    graphviz \
  # Languages \
    go \
    rust \
    cargo \
    python3 \
    python3-dev \
    py3-pip \
    py3-numpy \
    py3-scipy \
    py3-pandas \
    pipx \
    lua \
    lua-dev \
    luarocks \
    nodejs \
    npm \
  # Miscellaneous tools \
    neovim \
    jq \
    neofetch \
    tmux \
  # Shells and Zsh plugins \
    zsh \
    zsh-autosuggestions \
    zsh-syntax-highlighting \
    zsh-completions \
  # K8s tools \
    kubectl \
    helm \
    helmfile \
  && rm -rf /var/cache/apk/*

# K8s
RUN helm plugin install https://github.com/databus23/helm-diff

# Pipx installs
ENV PATH="$HOME/.local/bin:$PATH"
RUN apk --no-cache --virtual .build-deps add \
      gcc \
      g++ \
      gfortran \
      openblas-dev \
      lapack-dev \
      pkgconfig \
      linux-headers \
      musl-dev \
    && pipx install \
      aider-chat \
      pre-commit \
      poetry \
      ruff \
      ipython \
      ipdb \
      awscli \
      pyright \
      ruff-lsp \
      just \
      thefuck \
      aws-parallelcluster \
      ansible \
    && rm -rf /root/.local/pipx/shared ~/.cache/pipx \
    && apk del .build-deps

# luarocks installs
ENV PATH="/usr/local/lib/luarocks/bin/:$HOME/.luarocks/bin/:$PATH"
RUN luarocks-5.1 config local_by_default true
RUN apk --no-cache --virtual .build-deps add \
      g++ \
      cmake \
    && luarocks-5.1 install --server=https://luarocks.org/dev luaformatter \
    && apk del .build-deps

# npm installs
RUN npm install -g \
    prettier \
    pyright \
    twilio-cli

# Install tfenv
RUN git clone --depth=1 https://github.com/tfutils/tfenv.git $HOME/.tfenv
RUN .tfenv/bin/tfenv install latest

# Cargo installs
ENV PATH="/home/root/.cargo/bin:$PATH"
RUN cargo install \
    git-delta \
    ripgrep \
    zoxide \
    bat \
    fd-find \
    eza

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
	&& go install github.com/junegunn/fzf@latest \
	&& fzf --version

# Install gh
ENV PATH=$HOME/.local/bin:$PATH
RUN curl -sS https://webi.sh/gh | sh

# Install Oh My Zsh
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
ENV ZSH_CUSTOM=/home/user/.oh-my-zsh/custom
RUN git clone https://github.com/zsh-users/zsh-autosuggestions $ZSH_CUSTOM/plugins/zsh-autosuggestions
RUN git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting
RUN git clone --depth=1 https://github.com/romkatv/powerlevel10k.git $ZSH_CUSTOM/themes/powerlevel10k

# Slurm
WORKDIR /tmp
# RUN wget https://download.schedmd.com/slurm/slurm-<version>.tar.bz2 && \
#    tar -xaf slurm-24.05.2.tar.bz2 && \
#    cd slurm-24.05.2.tar.bz2 && \
#    ./configure --prefix=/usr --sysconfdir=/etc/slurm --with-munge && \
#    make && \
#    make install && \
#    ldconfig -n /usr/lib && \
#    ldconfig -n /usr/lib64 && \
#    rm -rf /var/cache/apk/* /tmp/slurm-*
WORKDIR /home/root

# Copies
COPY bin bin
COPY home/ .
RUN git config --global core.excludesFile '$HOME/.gitignore_global'
RUN git config --global pull.rebase true
RUN git config --global --add --bool push.autoSetupRemote true
RUN find $PYENV_ROOT -name '*.md' -delete

# Chmod so that these files are runnable
RUN find bin -type f -exec chmod +x {} \;

# Get neovim to download all its stuff
RUN nvim --headless "+Lazy! sync" +qa

# terminal colors with xterm
ENV TERM=xterm-256color

CMD ["/bin/zsh"]
