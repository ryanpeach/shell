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
    lazygit \
    make \
  # Uncategorized dependencies \
    iputils \
    bind-tools \
    sshpass \
    openssh-client \
    openssh-server \
    stow \
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
    zoxide \
    ripgrep \
    eza \
    bat \
    fzf \
    direnv \
    yq \
    fd \
    thefuck \
    delta \
  # Languages \
    go \
    rust \
    cargo \
    python3 \
    python3-dev \
    py3-setuptools \
    py3-pip \
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
    k9s \
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
      cmake \
      zlib-dev \
      libffi-dev \
      readline-dev \
      openssl-dev \
      sqlite-dev \
      bzip2-dev \
      xz-dev \
      sshpass \
      patch \
      build-base \
      gcc-doc \
    && pipx install --verbose \
      # aider-chat \ TODO: Fix this, something to do with scipy
      pre-commit \
      cookiecutter \
      poetry \
      ruff \
      ipython \
      ipdb \
      awscli \
      pyright \
      ruff-lsp \
      just \
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

# Go installs
ENV PATH="$HOME/go/bin:$PATH"
RUN go install github.com/terraform-docs/terraform-docs@v0.18.0 \
  && terraform-docs --version \
  && go install github.com/ankitpokhrel/jira-cli/cmd/jira@latest \
  && jira --help

# Install gh
ENV PATH=$HOME/.local/bin:$PATH
RUN curl -sS https://webi.sh/gh | sh

# Install Oh My Zsh
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
ENV ZSH_CUSTOM=/home/root/.oh-my-zsh/custom
RUN git clone https://github.com/zsh-users/zsh-autosuggestions $ZSH_CUSTOM/plugins/zsh-autosuggestions
RUN git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting
RUN git clone --depth=1 https://github.com/romkatv/powerlevel10k.git $ZSH_CUSTOM/themes/powerlevel10k

# Install bat-extras
RUN git clone https://github.com/eth-p/bat-extras.git \
  && cd bat-extras \
  && ./build.sh \
  && cp -r ./bin/* /usr/local/bin/

# Install ngrok cli
ARG TARGETPLATFORM
RUN ARCH=$(echo "$TARGETPLATFORM" | sed 's/linux\///') \
  && wget https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-${ARCH}.tgz \
  && tar -xvf ngrok-v3-stable-linux-${ARCH}.tgz -C /usr/local/bin

# Slurm
# WORKDIR /tmp
# RUN wget https://download.schedmd.com/slurm/slurm-<version>.tar.bz2 && \
#    tar -xaf slurm-24.05.2.tar.bz2 && \
#    cd slurm-24.05.2.tar.bz2 && \
#    ./configure --prefix=/usr --sysconfdir=/etc/slurm --with-munge && \
#    make && \
#    make install && \
#    ldconfig -n /usr/lib && \
#    ldconfig -n /usr/lib64 && \
#    rm -rf /var/cache/apk/* /tmp/slurm-*
# WORKDIR /home/root

# Copies
ENV SHELL_DIR="$HOME/shell"
COPY . $SHELL_DIR
RUN git config --global core.excludesFile '$HOME/.gitignore_global'
RUN git config --global pull.rebase true
RUN git config --global --add --bool push.autoSetupRemote true
RUN stow $SHELL_DIR/home
RUN cd $SHELL_DIR && wd add shell

# Chmod so that these files are runnable
RUN find bin -type f -exec chmod +x {} \;

# Get neovim to download all its stuff
RUN nvim --headless "+Lazy! sync" +qa

# terminal colors with xterm
ENV TERM=xterm-256color

CMD ["/bin/zsh"]
