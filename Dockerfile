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

# ======= Sorted ========
RUN emerge app-shells/direnv
RUN emerge app-shells/zsh
RUN emerge app-shells/fzf
RUN emerge app-shells/thefuck
RUN emerge app-shells/zoxide
RUN emerge app-shells/zsh-autocomplete
RUN emerge app-shells/zsh-autosuggestions
RUN emerge app-shells/zsh-completions
RUN emerge app-shells/zsh-history-substring-search
RUN emerge app-shells/zsh-syntax-highlighting
RUN emerge app-shells/pyenv
RUN emerge app-editors/neovim
RUN emerge app-lang/rust
RUN emerge app-lang/go
RUN emerge app-lang/lua
RUN emerge dev-lua/luarocks
RUN emerge dev-build/make
RUN emerge dev-build/cmake
RUN emerge dev-build/ninja
RUN emerge dev-build/meson
RUN emerge dev-build/autoconf
RUN emerge sys-apps/ripgrep
RUN emerge sys-apps/bat
RUN emerge sys-apps/fd
RUN emerge sys-apps/eza
RUN emerge sys-apps/sed
RUN emerge sys-apps/gawk
RUN emerge app-misc/neofetch
RUN emerge app-misc/tmux
RUN emerge app-misc/jq
RUN emerge net-misc/curl
RUN emerge net-misc/wget
RUN emerge net-misc/rsync
RUN emerge app-arch/unzip
RUN emerge sys-cluster/kubectl
RUN emerge sys-cluster/slurm
RUN emerge app-admin/helm
RUN emerge media-gfx/graphviz
RUN emerge dev-vcs/lazygit
RUN emerge sys-cluster/k9scli
RUN emerge dev-utils/git-delta
RUN emerge app-misc/yq
RUN emerge dev-util/github-cli
# ======= END: Sorted ========

# ======= To Sort =========

# ======= END: To Sort =========

# Clean up unnecessary files and dependencies
RUN emerge --depclean && \
    eclean-dist --deep && \
    eclean-pkg --deep

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

# Stage 2: Final minimal image
FROM gentoo/stage3:latest

# Copy the updated system from the builder stage
COPY --from=builder / /

# Set up environment variables and entry point
ENV PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

CMD ["/bin/zsh"]
