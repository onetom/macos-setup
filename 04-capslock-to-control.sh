#!/bin/zsh
# Remap Caps Lock -> Left Control on the built-in MacBook keyboard.
#
# Two layers, applied together:
#
#   Method 1 (hidutil): applies the mapping *immediately* for this login session
#     so you don't have to log out to feel the change. hidutil mappings are
#     forgotten on reboot/relogin, so on their own they are not persistent -- we
#     use them only for the instant-gratification "active now" effect.
#
#   Method 2 (defaults -currentHost): writes the exact per-keyboard preference
#     that System Settings > Keyboard > Keyboard Shortcuts > Modifier Keys writes.
#     This is what makes the remap *persist* across reboots, and it shows up
#     correctly in the System Settings GUI. It is keyed per keyboard by
#     vendor+product ID, so here we restrict it to the built-in keyboard only;
#     external keyboards keep their stock Caps Lock. It takes effect on next
#     login (this is why we also do Method 1, for right-now).
#
# HID usage codes:  Caps Lock = 0x700000039   Left Control = 0x7000000E0
#                   (decimal:  30064771129                  30064771296)
set -euo pipefail
SCRIPT_DIR="${0:A:h}"; source "$SCRIPT_DIR/lib.sh"
require_macos

SRC_HEX=0x700000039        # Caps Lock
DST_HEX=0x7000000E0        # Left Control
SRC_DEC=30064771129        # = SRC_HEX, for the defaults plist
DST_DEC=30064771296        # = DST_HEX, for the defaults plist

# ---- Clean up the old LaunchAgent, if a previous version of this script -----
# installed one. We no longer use a login agent; persistence is via Method 2.
OLD_LABEL="com.local.capslock-to-control"
OLD_PLIST="$HOME/Library/LaunchAgents/${OLD_LABEL}.plist"
if [[ -e "$OLD_PLIST" ]]; then
  log "Removing obsolete LaunchAgent: $OLD_PLIST"
  launchctl bootout "gui/$(id -u)/${OLD_LABEL}" 2>/dev/null \
    || launchctl unload -w "$OLD_PLIST" 2>/dev/null || true
  rm -f "$OLD_PLIST"
  ok "old LaunchAgent removed"
fi

# ---- Method 1: temporary, this session only -------------------------------
MAPPING="{\"UserKeyMapping\":[{\"HIDKeyboardModifierMappingSrc\":${SRC_HEX},\"HIDKeyboardModifierMappingDst\":${DST_HEX}}]}"
log "Applying Caps Lock -> Control now (hidutil, this session only)"
/usr/bin/hidutil property --set "$MAPPING" >/dev/null
ok "active for this session"

# ---- Method 2: persistent, built-in keyboard only -------------------------
# Find the built-in keyboard's vendor/product ID. The internal keyboard reports
# UsagePage 1 (Generic Desktop) / Usage 6 (Keyboard) and a "Apple Internal
# Keyboard" product string. hidutil prints the IDs in hex; convert to decimal,
# which is the form the modifiermapping preference key uses.
ids="$(hidutil list \
  | grep "Apple Internal Keyboard" \
  | awk '$4==1 && $5==6 {print $1, $2; exit}')"

if [[ -z "$ids" ]]; then
  warn "Could not find a built-in keyboard via hidutil; skipping persistent mapping."
  warn "The session mapping above is still active until next reboot/relogin."
  exit 0
fi

# Split "0x5ac 0x343" into words (${=...}, since zsh doesn't word-split by
# default), then convert each hex ID to decimal via zsh arithmetic ($(( 0x... ))).
# Note: zsh's `printf %d` does NOT parse a 0x prefix, hence the arithmetic.
set -- ${=ids}
VENDOR=$(( $1 ))
PRODUCT=$(( $2 ))
KEY="com.apple.keyboard.modifiermapping.${VENDOR}-${PRODUCT}-0"

log "Built-in keyboard: vendor=${VENDOR} product=${PRODUCT}"
log "Writing persistent mapping: ${KEY}"
defaults -currentHost write -g "$KEY" -array \
  "<dict><key>HIDKeyboardModifierMappingDst</key><integer>${DST_DEC}</integer><key>HIDKeyboardModifierMappingSrc</key><integer>${SRC_DEC}</integer></dict>"
ok "persistent mapping written (built-in keyboard only)"
warn "Persistent mapping takes effect on next login; it's already live this session via hidutil."
