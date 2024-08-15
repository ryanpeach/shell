# Stage 1: Build environment to install emerge and perform updates
FROM gentoo/stage3:latest as builder

# Update the environment and install necessary tools
RUN emerge --sync && \
    emerge --update --deep --newuse @world && \
    emerge sys-apps/portage

# Eselect
RUN emerge app-eselect/eselect-repository
RUN emerge dev-vcs/git
RUN eselect repository enable guru
RUN emerge --sync guru
RUN emerge app-portage/gentoolkit

# archive tools
RUN emerge app-arch/unzip
RUN emerge app-arch/tar
RUN emerge app-arch/gxz
RUN emerge app-arch/gzip

# Network tools
RUN emerge net-misc/curl
RUN emerge net-misc/wget
RUN emerge net-misc/rsync

# sys apps
RUN emerge sys-apps/sed
RUN emerge sys-apps/gawk
RUN emerge sys-apps/bat
RUN emerge sys-apps/eza
RUN emerge sys-apps/fd
RUN emerge sys-apps/ripgrep

# build tools
RUN emerge dev-build/cmake
RUN emerge dev-build/make

# languages
# don't install python, node, or terraform here
# We will be using pyenv, nvm, and tfenv to install these
RUN emerge dev-lang/go
RUN emerge dev-lang/rust
RUN emerge dev-lang/lua
RUN emerge dev-lua/luarocks

# editors
RUN emerge app-editors/neovim

# misc
RUN emerge app-misc/jq
RUN emerge app-misc/neofetch
RUN emerge app-misc/tmux
RUN emerge app-misc/yq

# shells
RUN emerge app-shells/direnv
RUN emerge app-shells/fzf
RUN emerge app-shells/thefuck
RUN emerge app-shells/zoxide
RUN emerge app-shells/zsh
RUN emerge app-shells/zsh-autocomplete
RUN emerge app-shells/zsh-autosuggestions
RUN emerge app-shells/zsh-completions
RUN emerge app-shells/zsh-history-substring-search
RUN emerge app-shells/zsh-syntax-highlighting

# git
RUN emerge dev-util/github-cli
RUN emerge dev-utils/git-delta
RUN emerge dev-vcs/lazygit

# graphviz
RUN emerge media-gfx/graphviz

# clusters
RUN emerge sys-cluster/k9scli
RUN emerge sys-cluster/kubectl
RUN emerge sys-cluster/slurm

# ======= To Sort =========
# Put things here to later sort into the above lists
# ======= END: To Sort =========

# Clean up unnecessary files and dependencies
RUN emerge --depclean && \
    eclean-dist --deep && \
    eclean-pkg --deep

# We don't actually need to create a new user
# Just set a reasonable home directory
WORKDIR /home/user
ENV HOME=/home/user

# RUN emerge app-admin/helm does not support arm
# Install Helm
RUN curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 && \
  chmod 700 get_helm.sh && \
  ./get_helm.sh

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
  && npm install -g \
    prettier \
    pyright \
    twilio-cli

# Install tfenv
RUN git clone --depth=1 https://github.com/tfutils/tfenv.git $HOME/.tfenv
RUN .tfenv/bin/tfenv install latest

# Go installs
ENV PATH="/home/user/go/bin:$PATH"
RUN go install github.com/terraform-docs/terraform-docs@v0.18.0 && \
    go install github.com/mikefarah/yq/v4@latest && \
    go install github.com/ankitpokhrel/jira-cli/cmd/jira@latest && \
    go install github.com/helmfile/helmfile@latest && \
    go install github.com/jesseduffield/lazygit@latest && \
    terraform-docs --version && \
    yq --version && \
    jira --help && \
    helmfile --version && \
    lazygit --help

# Install pyenv
RUN git clone https://github.com/pyenv/pyenv.git .pyenv
RUN cd .pyenv && src/configure && make -C src || true
ENV PYENV_ROOT=$HOME/.pyenv
ENV PATH=$PYENV_ROOT/shims:$PYENV_ROOT/bin:$PATH

# Create some pyenv environments
RUN pyenv install 3.11 && \
    pyenv global 3.11 && \
    pyenv rehash

RUN pip install \
  setuptools \
  numpy \
  pynvim \
  pipx \
  ensurepath

# Now default python installs in the root virtualenv
RUN pipx install \
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
  aws-parallelcluster

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

# Stage 2: Final minimal image
FROM gentoo/stage3:latest

# Copy the updated system from the builder stage
COPY --from=builder / /

# Set up environment variables and entry point
ENV PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# terminal colors with xterm
ENV TERM=xterm-256color

WORKDIR /home/user/mnt

CMD ["/bin/zsh"]
