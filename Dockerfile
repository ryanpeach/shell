# Stage 1: Build environment to install emerge and perform updates
FROM alpine:3.21 AS builder

ARG TARGETPLATFORM

# We don't actually need to create a new user
# Just set a reasonable home directory
ARG UID=1000
ARG GID=1000
ENV USERNAME=rgpeach10
RUN addgroup -g ${GID} ${USERNAME} 2>/dev/null || addgroup ${USERNAME}; \
    adduser -D -H -u ${UID} -G ${USERNAME} ${USERNAME} 2>/dev/null || \
    (echo "${USERNAME}:x:${UID}:${GID}::/home/${USERNAME}:/bin/sh" >> /etc/passwd && \
     mkdir -p /home/${USERNAME} && chown ${UID}:${GID} /home/${USERNAME})

# Stable repos first, edge as fallback for packages not yet in stable
# Stable repos first
RUN ALPINE_VERSION=$(cut -d '.' -f1,2 /etc/alpine-release) && \
    printf '%s\n' \
      "http://dl-cdn.alpinelinux.org/alpine/v${ALPINE_VERSION}/main" \
      "http://dl-cdn.alpinelinux.org/alpine/v${ALPINE_VERSION}/community" \
      > /etc/apk/repositories && \
    printf '%s\n' \
      "http://dl-cdn.alpinelinux.org/alpine/edge/main" \
      "http://dl-cdn.alpinelinux.org/alpine/edge/community" \
      "http://dl-cdn.alpinelinux.org/alpine/edge/testing" \
      > /etc/apk/repositories.edge

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
    tmux \
    vim \
  # Shells and Zsh plugins \
    zsh \
    zsh-autosuggestions \
    zsh-syntax-highlighting \
    zsh-completions \
  # K8s tools \
    kubectl \
    k9s \
    helm \
  # Docker (for Docker-in-Docker via socket mount) \
    docker-cli \
    docker-cli-compose \
    docker-cli-buildx \
  && rm -rf /var/cache/apk/*

# Install only the edge-only packages with edge repo file explicitly
RUN apk add --no-cache --repositories-file /etc/apk/repositories.edge \
    fastfetch \
    helmfile \
  && rm -rf /var/cache/apk/*

# Build dependencies needed for uv tool compilation (requires root)
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
      gcc-doc

# Drop root — all remaining commands run as the non-root user
USER ${USERNAME}
WORKDIR /home/${USERNAME}
ENV HOME=/home/${USERNAME}

# uv installs (as user)
ENV PATH="$HOME/.local/bin:$PATH"
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
RUN uv tool install --verbose pre-commit && \
      # uv tool install aider-chat && \ TODO: Fix this, something to do with scipy
      uv tool install --verbose ruff && \
      uv tool install --verbose ipython && \
      uv tool install --verbose ipdb && \
      uv tool install --verbose awscli && \
      uv tool install --verbose pyright && \
      uv tool install --verbose ruff-lsp && \
      uv tool install --verbose just && \
      uv tool install --verbose thefuck && \
      uv tool install --verbose ansible

# npm installs (user-local prefix to avoid root)
RUN mkdir -p "$HOME/.npm-global" && \
    npm config set prefix "$HOME/.npm-global" && \
    npm install -g \
    prettier \
    pyright
ENV PATH="$HOME/.npm-global/bin:$PATH"

# Install tfenv
RUN git clone --depth=1 https://github.com/tfutils/tfenv.git $HOME/.tfenv
RUN .tfenv/bin/tfenv install latest

# Rust installs
ENV PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"

# Go installs
ENV PATH="$HOME/go/bin:$PATH"

# Install gh
ENV PATH=$HOME/.local/bin:$PATH
RUN curl -sS https://webi.sh/gh | sh

# Install Oh My Zsh
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
ENV ZSH_CUSTOM=/home/${USERNAME}/.oh-my-zsh/custom
RUN git clone https://github.com/zsh-users/zsh-autosuggestions $ZSH_CUSTOM/plugins/zsh-autosuggestions
RUN git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting
RUN git clone --depth=1 https://github.com/romkatv/powerlevel10k.git $ZSH_CUSTOM/themes/powerlevel10k

# Install bat-extras
# TODO: Remove --no-verify
# REF: https://github.com/eth-p/bat-extras/issues/126
RUN git clone https://github.com/eth-p/bat-extras.git \
  && cd bat-extras \
  && ./build.sh --install --prefix="$HOME/.local" --no-verify

# Copies
ENV SHELL_DIR=$HOME/shell
COPY --chown=${USERNAME}:${USERNAME} . $SHELL_DIR
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

# Entrypoint must run as root to modify the user
USER root
WORKDIR /home/${USERNAME}/mnt
ENV MNT=/home/${USERNAME}/mnt
CMD ["/bin/zsh"]
