# Stage 1: Build environment to install emerge and perform updates
FROM alpine:edge AS builder

ARG TARGETPLATFORM

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
    shfmt \
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
    rust-analyzer \
    cargo \
    lua \
    lua-dev \
    luarocks \
    python3 \
    python3-dev \
    perl \
    texlive \
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
    helm-ls \
    helmfile \
    k9s \
  && rm -rf /var/cache/apk/*

# K8s
RUN helm plugin install https://github.com/databus23/helm-diff

# Cargo installs
ENV PATH="/home/root/.cargo/bin:$PATH"

# uv installs
ENV PATH="$HOME/.local/bin:$PATH"
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
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
      python3-dev \
      py3-setuptools \
      py3-pip \
      xz-dev \
      sshpass \
      patch \
      build-base \
      gcc-doc && \
      # uv tool install aider-chat && \ TODO: Fix this, something to do with scipy
      uv tool install --verbose pre-commit && \
      uv tool install --verbose cookiecutter && \
      uv tool install --verbose ruff && \
      uv tool install --verbose ipython && \
      uv tool install --verbose ipdb && \
      uv tool install --verbose awscli && \
      uv tool install --verbose pyright && \
      uv tool install --verbose ruff-lsp && \
      uv tool install --verbose just && \
      uv tool install --verbose aws-parallelcluster && \
      uv tool install --verbose ansible

# luarocks installs
ENV PATH="/usr/local/lib/luarocks/bin/:$HOME/.luarocks/bin/:$PATH"
RUN luarocks-5.1 config local_by_default true
RUN apk --no-cache --virtual .build-deps add \
      g++ \
      cmake \
    && luarocks-5.1 install --server=https://luarocks.org/dev luaformatter \
    && apk del .build-deps

# deno installs
RUN curl -fsSL https://deno.land/install.sh | sh
RUN deno install --global \
    prettier \
    pyright \
    twilio-cli

# Install tfenv
RUN git clone --depth=1 https://github.com/tfutils/tfenv.git $HOME/.tfenv
RUN .tfenv/bin/tfenv install latest

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
# TODO: Remove --no-verify
# REF: https://github.com/eth-p/bat-extras/issues/126
RUN git clone https://github.com/eth-p/bat-extras.git \
  && cd bat-extras \
  && ./build.sh --install --no-verify

# Install ngrok cli
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

# Stow
RUN apk --no-cache --virtual .build-deps add \
    build-base \
    automake \
    autoconf \
    texinfo \
  && git clone https://github.com/aspiers/stow.git \
  && cd stow \
  && sed '131,143d' -i Makefile.am \
  && sed -i '/check_pmdir/d' Makefile.am \
  && set -x && autoreconf -iv \
  && ./configure \
  &&  make install \
  && apk del .build-deps

# Copies
ENV SHELL_DIR=$HOME/shell
COPY . $SHELL_DIR
RUN set -e \
  && cd $SHELL_DIR \
  && if [ -z "$(git status --porcelain)" ]; then echo "No changes"; else git status --porcelain; exit 1; fi

RUN cd $SHELL_DIR \
  && stow --adopt home \
  && git reset HEAD --hard \
  && stow home \
  && cp $SHELL_DIR/home/.gitconfig $HOME/.gitconfig

# Chmod so that these files are runnable
RUN find $SHELL_DIR/home/bin -type f -exec chmod +x {} \;

# Get neovim to download all its stuff
RUN nvim --headless '+Lazy install' +qall

# terminal colors with xterm
ENV TERM=xterm-256color

CMD ["/bin/zsh"]
