#!/bin/zsh
# Remote Management (Apple Remote Desktop / Screen Sharing).
#
# Mirrors System Settings > General > Sharing > Remote Management, plus the
# "Computer Settings…" sheet behind it. There is no `defaults` write for this;
# Apple's `kickstart` tool inside ARDAgent.app is the supported way to script it,
# and it must run as root.
#
# IMPORTANT — what is and isn't scriptable on modern macOS:
#   Since macOS 12.1, `kickstart -activate` NO LONGER turns Remote Management on.
#   Apple gated the actual on/off switch behind System Settings or MDM; the old
#   -activate path now just prints "must be enabled from System Settings or via
#   MDM" and dies with a perl error. So this step does the half that still works
#   — it configures access, privileges and the Computer-Settings toggles — and
#   then walks you through the one click that has to be done by hand.
#   (Verified on macOS 26 "Tahoe": kickstart aborts in its -activate file-write.)
#
# Flags (verified from `kickstart -help` and the ARDAgent kickstart source):
#   -configure                    apply the settings that follow
#   -allowAccessFor -allUsers     grant access to all local users …
#   -privs -all                   … with every privilege (observe, control, etc.)
#   -clientopts                   the "Computer Settings…" toggles:
#     -setmenuextra -menuextra yes  Always show the status in the menu bar
#     -setreqperm   -reqperm   yes  Anyone may request permission to control screen
#     -setvnclegacy -vnclegacy no   VNC viewers may control screen with password (OFF)
#
# Note: -allowAccessFor -allUsers -privs -all reproduces the macOS "All users /
# full control" choice. Narrow it with `-allowAccessFor -specifiedUsers`
# `-users a,b` if you don't want every local user to have remote control.
set -euo pipefail
SCRIPT_DIR="${0:A:h}"; source "$SCRIPT_DIR/lib.sh"
require_macos
need_sudo

KICKSTART=/System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart
[[ -x "$KICKSTART" ]] || { err "kickstart not found at $KICKSTART"; exit 1; }

# The flag file kickstart writes ("enabled") once Remote Management is switched on.
RM_FLAG="/Library/Application Support/Apple/Remote Desktop/RemoteManagement.launchd"

log "Configure Remote Management options (access, privileges, Computer Settings)"
# Deliberately no -activate: it is a no-op-that-crashes on macOS 12.1+. -configure
# writes the prefs whether or not Remote Management is currently on, so the
# settings are already in place the moment you flip the switch.
sudo "$KICKSTART" -configure \
  -allowAccessFor -allUsers -privs -all \
  -clientopts \
    -setmenuextra -menuextra yes \
    -setreqperm   -reqperm   yes \
    -setvnclegacy -vnclegacy no
ok "Options set: all users / full control, menu-bar status on, guests may request control, VNC password mode off"

if [[ "$(sudo cat "$RM_FLAG" 2>/dev/null)" == "enabled" ]]; then
  ok "Remote Management is already enabled — you're done."
else
  warn "Remote Management itself is NOT on yet."
  warn "Apple blocks enabling it from the command line (macOS 12.1+); flip it once by hand:"
  warn "    System Settings > General > Sharing > Remote Management  →  turn ON"
  warn "Your options above are already saved, so they'll apply the moment you do."
  # Jump straight to the Sharing pane to make it a single click.
  open "x-apple.systempreferences:com.apple.Sharing-Settings.extension" 2>/dev/null || true
fi
