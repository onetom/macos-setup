#!/bin/zsh
# Power management: don't let the Mac sleep while on the power adapter.
#
# Mirrors System Settings > Battery > Power Adapter > "Prevent automatic sleeping
# when the display is off" (the system-sleep half of it).
#
# Unlike the other steps, this is a *system-wide* setting, not a per-user `defaults`
# write: pmset stores it in /Library/Preferences/com.apple.PowerManagement.plist and
# it requires root. A single `pmset` call both applies the change live AND persists
# it across reboots, so there's nothing extra to do for persistence.
#
# Profiles:  -c = power adapter (charger)   -b = battery   -a = all
# We only touch -c so the machine still sleeps normally on battery.
set -euo pipefail
SCRIPT_DIR="${0:A:h}"; source "$SCRIPT_DIR/lib.sh"
require_macos
need_sudo

log "Disable system sleep while on the power adapter"
# sleep = idle *system* sleep (0 = never). displaysleep is left untouched, so the
# screen still turns off / locks on its own schedule.
sudo pmset -c sleep 0
ok "AC power: system sleep disabled (display sleep unchanged)"

log "Current power adapter settings:"
pmset -g custom
