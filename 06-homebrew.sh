#!/bin/zsh
# Install Homebrew (no-op if already installed) and wire it into the login shell.
set -euo pipefail
SCRIPT_DIR="${0:A:h}"; source "$SCRIPT_DIR/lib.sh"
require_macos

if brew_prefix >/dev/null 2>&1; then
  ok "Homebrew already installed at $(brew_prefix)"
else
  log "Installing Homebrew (you may be prompted for your password)"
  NONINTERACTIVE=1 /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  ok "Homebrew installed"
fi

# Ensure `brew` is on PATH in future login shells, and in this one.
PREFIX="$(brew_prefix)"
ensure_line "eval \"\$(${PREFIX}/bin/brew shellenv)\"" "$HOME/.zprofile"
load_brew
ok "brew available: $(command -v brew)"
