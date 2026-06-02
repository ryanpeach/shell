#!/usr/bin/env bash
#
# install.sh - Bootstrap this shell config on macOS or Ubuntu via Homebrew.
#
# Homebrew is the primary package manager so the same script works on both
# macOS and Linux. A thin per-OS layer handles the few things brew can't do
# cross-platform (GUI app + fonts).
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

usage() {
  sed -n '3,13p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

for arg in "$@"; do
  case "$arg" in
    --no-stow) DO_STOW=0 ;;
    -h | --help)
      usage
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

OS="$(uname -s)" # Darwin (macOS) or Linux

# ---------------------------------------------------------------------------
# Prerequisites
# ---------------------------------------------------------------------------

if [ "$OS" = "Darwin" ]; then
  # Homebrew needs the Xcode Command Line Tools (git, compilers).
  if ! xcode-select -p >/dev/null 2>&1; then
    log "Installing Xcode Command Line Tools (a GUI prompt may appear)"
    xcode-select --install || warn "Could not trigger Xcode CLT install; do it manually if brew fails."
  fi
elif [ "$OS" = "Linux" ]; then
  # On Debian/Ubuntu, install the handful of packages Homebrew (and the Nerd
  # Font + alacritty steps) need before brew can take over.
  if have apt-get; then
    export DEBIAN_FRONTEND=noninteractive
    log "Installing Linux prerequisites via apt"
    as_root apt-get update -y
    as_root apt-get install -y --no-install-recommends \
      build-essential procps curl file git unzip fontconfig \
      || warn "Some apt prerequisites failed to install."
  else
    warn "apt-get not found; assuming build prerequisites for Homebrew are already present."
  fi
else
  err "Unsupported OS '$OS'. This installer supports macOS and Linux."
  exit 1
fi

# ---------------------------------------------------------------------------
# Homebrew
# ---------------------------------------------------------------------------

if ! have brew; then
  if [ -x /opt/homebrew/bin/brew ] || [ -x /usr/local/bin/brew ] \
    || [ -x /home/linuxbrew/.linuxbrew/bin/brew ] || [ -x "$HOME/.linuxbrew/bin/brew" ]; then
    : # brew is installed but not yet on PATH; the shellenv step below fixes it.
  else
    log "Installing Homebrew"
    NONINTERACTIVE=1 bash -c \
      "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
fi

# Put brew on PATH for the rest of this run (a fresh install isn't yet).
for cand in /opt/homebrew/bin/brew /usr/local/bin/brew \
  /home/linuxbrew/.linuxbrew/bin/brew "$HOME/.linuxbrew/bin/brew"; do
  if [ -x "$cand" ]; then
    eval "$("$cand" shellenv)"
    break
  fi
done

if ! have brew; then
  err "Homebrew installation failed or brew is not on PATH. Cannot continue."
  exit 1
fi

# Persist Homebrew on PATH for future shells. Everything below installs into
# the Homebrew prefix, so a shell that can't find brew won't find zsh, stow,
# just, etc. The stowed .zshrc already adds the Homebrew prefix, so zsh is
# covered (and we must NOT append to it -- it's a symlink into this repo).
# bash, however, needs help: add brew's shellenv to the user's bash startup.
brew_shellenv_line="eval \"\$($(brew --prefix)/bin/brew shellenv)\""
for rc in "$HOME/.bashrc" "$HOME/.profile"; do
  # Always seed ~/.bashrc; only touch ~/.profile if it already exists.
  [ -f "$rc" ] || [ "$rc" = "$HOME/.bashrc" ] || continue
  if ! grep -qsF 'brew shellenv' "$rc"; then
    printf '\n# Homebrew (added by shell/install.sh)\n%s\n' "$brew_shellenv_line" >> "$rc"
    log "Added Homebrew to $rc"
  fi
done

# ---------------------------------------------------------------------------
# Homebrew formulae (cross-platform)
# ---------------------------------------------------------------------------

BREW_FORMULAE=(
  # Core / VCS
  git
  make
  stow
  gawk
  graphviz
  # Search / navigation / files
  zoxide
  ripgrep
  fzf
  direnv
  fd
  bat
  bat-extras
  eza
  yq
  git-delta
  jq
  # Editor / multiplexer
  tmux
  vim
  # Security / remote
  gnupg
  pass
  openssh
  rsync
  wget
  curl
  # Languages / runtimes (rust + node-via-nvm handled separately below)
  go
  python
  deno
  uv
  just
  # Shell
  zsh
  shfmt
  # Dev tooling
  gh
  lazygit
  # Kubernetes
  kubectl
  k9s
  helm
  helmfile
)

log "Installing Homebrew formulae"
# Install one at a time so a single unavailable/relocated formula doesn't
# abort the whole run.
for formula in "${BREW_FORMULAE[@]}"; do
  if brew list --formula "$formula" >/dev/null 2>&1; then
    continue
  fi
  if ! brew install "$formula"; then
    warn "Could not install '$formula' via brew; skipping."
  fi
done

# ---------------------------------------------------------------------------
# Terminal emulator + Nerd Font (per-OS: cask on macOS, native on Linux)
# ---------------------------------------------------------------------------

if [ "$OS" = "Darwin" ]; then
  # Casks are macOS-only.
  for cask in alacritty font-jetbrains-mono-nerd-font; do
    if brew list --cask "$cask" >/dev/null 2>&1; then
      log "$cask already installed"
    else
      log "Installing $cask"
      brew install --cask "$cask" || warn "Could not install cask '$cask'."
    fi
  done
else
  # Linux: alacritty from apt, JetBrainsMono Nerd Font from the release.
  if have apt-get && ! have alacritty; then
    log "Installing alacritty via apt"
    as_root apt-get install -y --no-install-recommends alacritty \
      || warn "Could not install alacritty from apt (not packaged on this release?)."
  fi

  FONT_DIR="$HOME/.local/share/fonts"
  if ls "$FONT_DIR"/JetBrainsMono*NerdFont*.ttf >/dev/null 2>&1; then
    log "JetBrainsMono Nerd Font already installed"
  else
    log "Installing JetBrainsMono Nerd Font"
    mkdir -p "$FONT_DIR"
    font_tmp="$(mktemp -d)"
    if curl -fsSL -o "$font_tmp/JetBrainsMono.zip" \
        https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip; then
      unzip -oq "$font_tmp/JetBrainsMono.zip" -d "$FONT_DIR" -x "*.md" "LICENSE*"
      if have fc-cache; then
        fc-cache -f "$FONT_DIR" >/dev/null 2>&1 || true
      fi
      log "JetBrainsMono Nerd Font installed to $FONT_DIR"
    else
      warn "Could not download JetBrainsMono Nerd Font; skipping."
    fi
    rm -rf "$font_tmp"
  fi
fi

# ---------------------------------------------------------------------------
# Rust (via rustup) - keeps cargo in ~/.cargo/bin as the .zshrc expects
# ---------------------------------------------------------------------------

if have cargo || [ -x "$HOME/.cargo/bin/cargo" ]; then
  log "Rust already installed"
else
  log "Installing Rust via rustup"
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \
    | sh -s -- -y --no-modify-path
fi

if [ -x "$HOME/.cargo/bin/cargo" ]; then
  export PATH="$HOME/.cargo/bin:$PATH"
fi
if have rustup && ! have rust-analyzer; then
  log "Adding rust-analyzer component"
  rustup component add rust-analyzer || warn "Could not add rust-analyzer component"
fi

# ---------------------------------------------------------------------------
# nvm (Node Version Manager) - the .zshrc already sources it from ~/.nvm
# ---------------------------------------------------------------------------

NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
export NVM_DIR
if [ -s "$NVM_DIR/nvm.sh" ]; then
  log "nvm already installed"
else
  log "Installing nvm"
  # PROFILE=/dev/null stops the installer from editing shell rc files; the
  # stowed .zshrc already sources $NVM_DIR/nvm.sh itself.
  PROFILE=/dev/null bash -c \
    "curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash"
fi

# Install a Node runtime through nvm (node is no longer installed via brew).
if [ -s "$NVM_DIR/nvm.sh" ]; then
  # shellcheck disable=SC1090,SC1091
  . "$NVM_DIR/nvm.sh"
  if ! nvm which default >/dev/null 2>&1; then
    log "Installing latest LTS Node via nvm"
    nvm install --lts && nvm alias default 'lts/*' \
      || warn "Could not install Node via nvm; run 'nvm install --lts' later."
  else
    log "Node already installed via nvm ($(nvm version default))"
  fi
fi

# ---------------------------------------------------------------------------
# Claude Code (Anthropic CLI) - native installer to ~/.local/bin
# ---------------------------------------------------------------------------

if have claude; then
  log "Claude Code already installed"
else
  log "Installing Claude Code"
  curl -fsSL https://claude.ai/install.sh | bash || warn "Could not install Claude Code."
fi

# ---------------------------------------------------------------------------
# Oh My Zsh + plugins + powerlevel10k theme
# ---------------------------------------------------------------------------

# Check for the actual entrypoint file, not just the directory -- a failed
# install can leave an empty/partial ~/.oh-my-zsh behind.
if [ -f "$HOME/.oh-my-zsh/oh-my-zsh.sh" ]; then
  log "Oh My Zsh already installed"
else
  log "Installing Oh My Zsh (unattended)"
  # Download to a file first so a failed curl can't silently no-op (the old
  # `sh -c "$(curl ...)"` form runs an empty script and exits 0 on failure).
  omz_installer="$(mktemp)"
  if curl -fsSL -o "$omz_installer" \
      https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh; then
    # RUNZSH/CHSH off so the installer doesn't launch a shell or prompt.
    RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh "$omz_installer" --unattended \
      || warn "The Oh My Zsh installer exited with an error."
  else
    warn "Could not download the Oh My Zsh installer (network/proxy?)."
  fi
  rm -f "$omz_installer"

  # The .zshrc sources oh-my-zsh.sh unconditionally, so make a missing install
  # loud rather than letting every future zsh startup error out.
  if [ ! -f "$HOME/.oh-my-zsh/oh-my-zsh.sh" ]; then
    err "Oh My Zsh did not install: $HOME/.oh-my-zsh/oh-my-zsh.sh is missing."
    err "zsh will error on startup until this is fixed. Re-run install.sh once"
    err "you have network access to raw.githubusercontent.com and github.com."
  fi
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
cat <<EOF

The tools were installed via Homebrew (prefix: $(brew --prefix)). To use them
they must be on your PATH:

  - This shell, right now:   eval "\$($(brew --prefix)/bin/brew shellenv)"
  - New bash shells:         already set up in ~/.bashrc
  - zsh:                     handled by this repo's .zshrc (run: exec zsh)

Next steps:
  - Make zsh your default shell:  chsh -s "\$(command -v zsh)"
  - On Linux, set your terminal font to "JetBrainsMono Nerd Font".
    On macOS it's installed via Homebrew cask and available immediately.
EOF
