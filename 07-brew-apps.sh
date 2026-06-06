#!/bin/zsh
# Install the requested applications via Homebrew casks.
#   zerotier-one   1password   1password-cli   firefox
# None of these come from the Mac App Store, so no App Store sign-in is required.
set -euo pipefail
SCRIPT_DIR="${0:A:h}"; source "$SCRIPT_DIR/lib.sh"
require_macos
load_brew || { err "Homebrew not found. Run 06-homebrew.sh first."; exit 1; }

CASKS=(zerotier-one 1password 1password-cli firefox)

log "Updating Homebrew"
brew update

for c in "${CASKS[@]}"; do
  if brew list --cask "$c" >/dev/null 2>&1; then
    ok "$c already installed"
  else
    log "Installing $c"
    brew install --cask "$c"
    ok "$c installed"
  fi
done

warn "ZeroTier installs a system network extension; macOS will ask you to Allow it"
warn "in System Settings > Privacy & Security the first time. Network join is next step."
