#!/usr/bin/env bash
# Enable "zoom the screen while holding a modifier and scrolling".
# Equivalent to: System Settings > Accessibility > Zoom >
#   "Use scroll gesture with modifier keys to zoom" = Control.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; source "$SCRIPT_DIR/lib.sh"
require_macos

log "Enable Control + scroll to zoom the screen"
defaults write com.apple.universalaccess closeViewScrollWheelToggle -bool true
# Modifier flag masks: Shift=131072 Control=262144 Option=524288 Command=1048576
defaults write com.apple.universalaccess closeViewScrollWheelModifiersInt -int 262144  # Control
# Smooth images while zoomed (optional, nicer at high zoom).
defaults write com.apple.universalaccess closeViewSmoothImages -bool true
ok "Control + scroll zoom enabled"

warn "com.apple.universalaccess is TCC-protected. If this doesn't take effect:"
warn "  - log out / back in, and"
warn "  - grant your terminal app 'Full Disk Access' (System Settings > Privacy & Security),"
warn "    or just flip the toggle once in System Settings > Accessibility > Zoom."
