# Minimalist apt base. All tooling is installed by install.sh (via Homebrew),
# so this Dockerfile only has to bootstrap enough to run that script.
FROM debian:bookworm-slim

ARG UID=1000
ARG GID=1000
ARG USERNAME=rgpeach10
ENV USERNAME=${USERNAME}

# Bootstrap: the minimum install.sh needs before it can take over.
#   - sudo:            install.sh's `as_root` uses it for apt + Homebrew
#   - curl/ca-certs:   downloading Homebrew and the various installers
#   - git:             Homebrew and the Oh My Zsh plugin clones need it
#   - locales:         a UTF-8 locale for a sane terminal
#   - zsh:             the container's login shell (CMD below)
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
       sudo ca-certificates curl git locales zsh \
  && sed -i 's/# en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen \
  && locale-gen \
  && rm -rf /var/lib/apt/lists/*

ENV LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8

# Create the non-root user. Homebrew refuses to run as root, so install.sh
# runs as this user with passwordless sudo for the steps that need it.
RUN groupadd -g ${GID} ${USERNAME} 2>/dev/null || true \
  && useradd -m -u ${UID} -g ${GID} -s /bin/zsh ${USERNAME} 2>/dev/null || true \
  && echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USERNAME} \
  && chmod 0440 /etc/sudoers.d/${USERNAME}

USER ${USERNAME}
ENV HOME=/home/${USERNAME}
ENV SHELL_DIR=${HOME}/shell
WORKDIR ${SHELL_DIR}

# Copy the repo in and let install.sh do everything: install Homebrew + all
# tooling, Oh My Zsh + powerlevel10k, and stow the dotfiles. --headless skips
# the GUI-only bits (alacritty + Nerd Font) that belong on the host.
COPY --chown=${UID}:${GID} . ${SHELL_DIR}
RUN bash install.sh --headless

# Make the personal scripts runnable (stow symlinks them onto PATH via ~/bin).
RUN find ${SHELL_DIR}/home/bin -type f -exec chmod +x {} \;

# Replace the stowed .gitconfig symlink with a real copy so that
# `git config --global ...` (e.g. from .zshrc.private) writes to a standalone
# file instead of dirtying this repo and tripping the on_exit guard in .zshrc.
RUN if [ -L "${HOME}/.gitconfig" ]; then \
      cp --remove-destination "$(readlink -f "${HOME}/.gitconfig")" "${HOME}/.gitconfig"; \
    fi

# Homebrew + user-local bins on PATH for the entrypoint shell. The .zshrc also
# sets these, but this keeps non-interactive invocations working too.
ENV PATH="/home/linuxbrew/.linuxbrew/bin:${HOME}/.local/bin:${HOME}/.cargo/bin:${HOME}/bin:${PATH}"
ENV TERM=xterm-256color

# Mount point for the host home directory (see the Justfile run targets).
ENV MNT=${HOME}/mnt
WORKDIR ${MNT}
CMD ["zsh"]
