#!/usr/bin/env bash
# Remap Caps Lock -> Left Control, persistently.
#
# `hidutil` applies the mapping immediately but forgets it on reboot/relogin, so we
# install a per-user LaunchAgent that re-applies it at every login. (This is the
# scriptable equivalent of System Settings > Keyboard > Keyboard Shortcuts >
# Modifier Keys > Caps Lock -> Control.)
#
# HID usage codes:  Caps Lock = 0x700000039   Left Control = 0x7000000E0
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; source "$SCRIPT_DIR/lib.sh"
require_macos

LABEL="com.local.capslock-to-control"
PLIST="$HOME/Library/LaunchAgents/${LABEL}.plist"
MAPPING='{"UserKeyMapping":[{"HIDKeyboardModifierMappingSrc":0x700000039,"HIDKeyboardModifierMappingDst":0x7000000E0}]}'

log "Applying Caps Lock -> Control now"
/usr/bin/hidutil property --set "$MAPPING" >/dev/null
ok "active for this session"

log "Installing login LaunchAgent so it survives reboots: $PLIST"
mkdir -p "$HOME/Library/LaunchAgents"
cat > "$PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>${LABEL}</string>
  <key>ProgramArguments</key>
  <array>
    <string>/usr/bin/hidutil</string>
    <string>property</string>
    <string>--set</string>
    <string>${MAPPING}</string>
  </array>
  <key>RunAtLoad</key><true/>
</dict>
</plist>
PLIST

# (Re)load the agent. bootstrap is the modern API; fall back to load for older macOS.
launchctl bootout "gui/$(id -u)/${LABEL}" 2>/dev/null || true
if ! launchctl bootstrap "gui/$(id -u)" "$PLIST" 2>/dev/null; then
  launchctl load -w "$PLIST" 2>/dev/null || true
fi
ok "LaunchAgent installed and loaded"
