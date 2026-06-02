# CLAUDE.md

Guidance for Claude when working in this repo.

## Overview

This repo is a personal shell/dotfiles setup. The same configuration is meant
to run in two places, installed by two separate scripts that use **different
package managers**:

| Environment        | File         | Package manager | Role                                    |
| ------------------ | ------------ | --------------- | --------------------------------------- |
| Docker container   | `Dockerfile` | Alpine `apk`    | The small, primary distributed image    |
| Local machine      | `install.sh` | Homebrew        | Bootstraps a Mac or Ubuntu workstation  |

Both ultimately install the same kinds of tools and then `stow` the dotfiles in
`home/` into `$HOME`. The dotfiles in `home/` (especially `home/.zshrc`) are the
shared contract: they assume a certain set of tools exist on `PATH`.

## Keep the two environments pseudo-in-sync

The `Dockerfile` and `install.sh` are maintained **in parallel**, not generated
from each other. When you add, remove, or change a tool in one, mirror the
change in the other so they don't drift:

- Add a CLI to the `Dockerfile`'s `apk add` list **and** to `install.sh`'s
  `BREW_FORMULAE` list (or its dedicated installer section).
- Likewise when removing a tool.
- If a new dotfile in `home/` relies on a tool, make sure **both** environments
  install it — otherwise `.zshrc` will error on startup in one of them.

"Pseudo" is deliberate: the two are **not** identical and shouldn't be forced to
match one-for-one. Expected, intentional differences include:

- **Package names differ** between `apk` and `brew` (e.g. `bind-tools` vs
  `bind`, and Debian-style names if apt is ever involved).
- **The Docker image stays small.** It is Alpine-based on purpose. Do not
  replace it with a Homebrew-based image or a heavier base just to match
  `install.sh`. (This was tried and reverted — see git history.)
- **GUI / host-only bits** (alacritty, Nerd Fonts) belong on the local machine
  via `install.sh`, not in the container.
- Some tools are installed via their own upstream installers rather than the
  package manager (Oh My Zsh, powerlevel10k, `nvm`, `rustup`, `uv`). Keep those
  steps present in both.

When in doubt, the source of truth for "what must exist" is `home/.zshrc` — if
it references a command, both environments should provide it.

## Conventions

- Shell scripts: keep them POSIX-ish/bash, `set -euo pipefail`, and idempotent
  (safe to re-run). Match the existing style in `install.sh`.
- Don't push to `main`; work on a feature branch.
- `pre-commit` is configured (`.pre-commit-config.yaml`); keep changes passing
  its hooks (trailing whitespace, end-of-file, gitleaks, etc.).
