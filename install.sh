#!/usr/bin/env bash
#
# install.sh - Bootstrap this shell config on a blank apt-based terminal.
#
# This is the apt/Debian/Ubuntu counterpart to the Alpine-based Dockerfile.
# It installs the tools this shell expects, then stows the dotfiles in ./home.
#
# Usage:
#   ./install.sh            # install everything, then stow
#   ./install.sh --no-stow  # install tools but skip stowing dotfiles
#
# Safe to re-run: every step checks for what it needs before doing work.

set -euo pipefail

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DO_STOW=1

for arg in "$@"; do
  case "$arg" in
    --no-stow) DO_STOW=0 ;;
    -h | --help)
      sed -n '2,18p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "Unknown argument: $arg" >&2
      exit 1
      ;;
  esac
done

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mwarning:\033[0m %s\n' "$*" >&2; }
err() { printf '\033[1;31merror:\033[0m %s\n' "$*" >&2; }

have() { command -v "$1" >/dev/null 2>&1; }

# Run a command as root if we aren't already root.
as_root() {
  if [ "$(id -u)" -eq 0 ]; then
    "$@"
  elif have sudo; then
    sudo "$@"
  else
    err "This step needs root and neither root nor sudo is available: $*"
    exit 1
  fi
}

# ---------------------------------------------------------------------------
# Preconditions
# ---------------------------------------------------------------------------

if ! have apt-get; then
  err "apt-get not found. This installer only supports apt-based systems"
  err "(Debian, Ubuntu, and derivatives). See the Dockerfile for Alpine."
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive

# ---------------------------------------------------------------------------
# apt packages
# ---------------------------------------------------------------------------

# Packages available directly from the default apt repos. Names differ from
# Alpine in a few cases (noted inline).
APT_PACKAGES=(
  # Core / VCS
  git
  make
  # Networking & remote
  iputils-ping
  dnsutils       # bind-tools on Alpine
  sshpass
  openssh-client
  openssh-server
  gnupg
  pass
  # Archive tools
  unzip
  tar
  gzip
  patch
  # Download tools
  curl
  wget
  rsync
  # System utilities
  sed
  stow
  gawk
  graphviz
  zoxide
  ripgrep
  fzf
  direnv
  fd-find        # binary is fdfind; we symlink to fd below
  bat            # binary is batcat; we symlink to bat below
  # Languages / runtimes
  golang-go
  python3
  python3-dev
  python3-venv
  python3-pip
  nodejs
  npm
  # Misc
  jq
  tmux
  vim
  # Shell
  zsh
  zsh-autosuggestions
  zsh-syntax-highlighting
)

log "Updating apt package lists"
as_root apt-get update -y

log "Installing apt packages"
# Install one at a time so a single unavailable package on an older release
# doesn't abort the whole run.
for pkg in "${APT_PACKAGES[@]}"; do
  if dpkg -s "$pkg" >/dev/null 2>&1; then
    continue
  fi
  if ! as_root apt-get install -y --no-install-recommends "$pkg"; then
    warn "Could not install '$pkg' from apt; skipping. Install it manually if you need it."
  fi
done

# Debian/Ubuntu ship these under different binary names. Provide the
# conventional names in ~/.local/bin so the dotfiles' aliases work.
mkdir -p "$HOME/.local/bin"
if have fdfind && ! have fd; then
  ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
  log "Linked fdfind -> ~/.local/bin/fd"
fi
if have batcat && ! have bat; then
  ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"
  log "Linked batcat -> ~/.local/bin/bat"
fi

# ---------------------------------------------------------------------------
# just (command runner) - not reliably packaged in apt, use official installer
# ---------------------------------------------------------------------------

if have just; then
  log "just already installed ($(just --version))"
else
  log "Installing just to ~/.local/bin"
  curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh \
    | bash -s -- --to "$HOME/.local/bin"
fi

# ---------------------------------------------------------------------------
# uv (Python tool/runtime manager)
# ---------------------------------------------------------------------------

if have uv; then
  log "uv already installed ($(uv --version))"
else
  log "Installing uv"
  curl -LsSf https://astral.sh/uv/install.sh | sh
fi

# ---------------------------------------------------------------------------
# Oh My Zsh + plugins + powerlevel10k theme
# ---------------------------------------------------------------------------

if [ -d "$HOME/.oh-my-zsh" ]; then
  log "Oh My Zsh already installed"
else
  log "Installing Oh My Zsh (unattended)"
  # RUNZSH/CHSH off so the installer doesn't launch a shell or prompt.
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

clone_if_missing() {
  local repo="$1" dest="$2"
  if [ -d "$dest" ]; then
    log "$(basename "$dest") already present"
  else
    log "Cloning $(basename "$dest")"
    git clone --depth=1 "$repo" "$dest"
  fi
}

clone_if_missing https://github.com/zsh-users/zsh-autosuggestions \
  "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
clone_if_missing https://github.com/zsh-users/zsh-syntax-highlighting.git \
  "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
clone_if_missing https://github.com/romkatv/powerlevel10k.git \
  "$ZSH_CUSTOM/themes/powerlevel10k"

# ---------------------------------------------------------------------------
# Stow the dotfiles from ./home into $HOME
# ---------------------------------------------------------------------------

if [ "$DO_STOW" -eq 1 ]; then
  if have stow; then
    log "Stowing dotfiles from $SCRIPT_DIR/home into $HOME"
    ( cd "$SCRIPT_DIR" && stow -t "$HOME" home )
  else
    warn "stow is not installed; skipping dotfile stow. Run 'just stow' later."
  fi
else
  log "Skipping stow (--no-stow). Run 'just stow' when ready."
fi

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------

log "Done."
cat <<'EOF'

Next steps:
  - Restart your terminal, or run:  exec zsh
  - Make zsh your default shell:    chsh -s "$(command -v zsh)"
  - Ensure ~/.local/bin is on your PATH (the dotfiles handle this in zsh).

Some tools from the Docker image are not in the default apt repos and were
skipped (e.g. eza, git-delta, yq, k9s, helm, kubectl, shfmt). Install those
from their upstream releases if you need them.
EOF
