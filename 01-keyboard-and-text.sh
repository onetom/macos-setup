#!/usr/bin/env bash
# Keyboard repeat speed + text-input behaviour (auto-correction, smart quotes).
# All settings are per-user and live in the global preferences domain (-g / NSGlobalDomain).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; source "$SCRIPT_DIR/lib.sh"
require_macos

log "Keyboard repeat: delay-until-repeat + repeat rate (fastest)"
# Lower = faster. 15 / 2 are the fastest values the System Settings slider exposes.
defaults write -g InitialKeyRepeat -int 15   # delay before a held key starts repeating
defaults write -g KeyRepeat        -int 2    # interval between repeats
# Disable press-and-hold accent popover so keys actually repeat in every app.
defaults write -g ApplePressAndHoldEnabled -bool false
ok "InitialKeyRepeat=15  KeyRepeat=2  (press-and-hold disabled)"

log "Turn OFF automatic spelling correction"
defaults write -g NSAutomaticSpellingCorrectionEnabled -bool false
ok "auto-correction disabled"

log "Turn OFF smart quotes"
defaults write -g NSAutomaticQuoteSubstitutionEnabled -bool false
# Smart dashes are a separate setting; you only asked for quotes, so it's left alone.
# To also disable smart dashes, uncomment:
# defaults write -g NSAutomaticDashSubstitutionEnabled -bool false
ok "smart quotes disabled"

warn "Key-repeat changes take full effect after you log out and back in."
