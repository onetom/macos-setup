#!/bin/zsh
# Install everything listed in ./Brewfile via `brew bundle`.
# Edit the Brewfile to change what gets installed; this script just applies it.
# brew bundle is idempotent (skips what's present) and does NOT remove anything
# absent from the Brewfile — run `brew bundle cleanup` by hand if you want that.
set -euo pipefail
SCRIPT_DIR="${0:A:h}"; source "$SCRIPT_DIR/lib.sh"
require_macos
load_brew || { err "Homebrew not found. Run 10-homebrew.sh first."; exit 1; }

BREWFILE="$SCRIPT_DIR/Brewfile"
[[ -f "$BREWFILE" ]] || { err "No Brewfile at $BREWFILE"; exit 1; }

log "Updating Homebrew"
brew update

log "Installing from $BREWFILE"
brew bundle install --file="$BREWFILE"
ok "Brewfile applied"

warn "ZeroTier installs a system network extension; macOS will ask you to Allow it"
warn "in System Settings > Privacy & Security the first time. Network join is next step."
