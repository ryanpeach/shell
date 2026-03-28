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
  # Uncategorized dependencies \
    iputils \
    bind-tools \
    sshpass \
    openssh-client \
    openssh-server \
    gnupg \
    pass \
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
    stow \
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
    python3 \
    python3-dev \
    nodejs \
    npm \
  # Miscellaneous tools \
    jq \
    neofetch \
    tmux \
    vim \
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
      uv tool install --verbose ruff && \
      uv tool install --verbose ipython && \
      uv tool install --verbose ipdb && \
      uv tool install --verbose awscli && \
      uv tool install --verbose pyright && \
      uv tool install --verbose ruff-lsp && \
      uv tool install --verbose just && \
      uv tool install --verbose ansible

# npm installs
RUN npm install -g \
    prettier \
    pyright

# Install tfenv
RUN git clone --depth=1 https://github.com/tfutils/tfenv.git $HOME/.tfenv
RUN .tfenv/bin/tfenv install latest

# Go installs
ENV PATH="$HOME/go/bin:$PATH"

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

# terminal colors with xterm
ENV TERM=xterm-256color

CMD ["/bin/zsh"]
