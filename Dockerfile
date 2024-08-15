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
# # ======= END: Sorted ========

# ======= To Sort =========
# Add emerge commands here to sort them on cronjob
# ======= END: To Sort =========

# just
# pipx
# pyenv
# tfenv
# nvm
# file
# gh
# terraform-docs
# yq
# jira-cli
# helmfile

# Clean up unnecessary files and dependencies
RUN emerge --depclean && \
    eclean-dist --deep && \
    eclean-pkg --deep

# Stage 2: Final minimal image
FROM gentoo/stage3:latest

# Copy the updated system from the builder stage
COPY --from=builder / /

# Set up environment variables and entry point
ENV PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

CMD ["/bin/zsh"]
