#!/bin/zsh
# Install the Nix package manager.
#
# We use the Determinate Systems nix-installer: on macOS it is far more robust than
# the upstream script (handles the dedicated /nix APFS volume, survives macOS
# upgrades, clean uninstall) and enables the flakes + nix-command features that
# step 09 (nix profile install) needs. It installs *upstream* Nix by default.
set -euo pipefail
SCRIPT_DIR="${0:A:h}"; source "$SCRIPT_DIR/lib.sh"
require_macos

if command -v nix >/dev/null 2>&1 || [[ -e /nix/var/nix/profiles/default ]]; then
  ok "Nix already installed"
else
  log "Installing Nix (multi-user daemon; you may be prompted for your password)"
  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix \
    | sh -s -- install --no-confirm
  ok "Nix installed"
fi

load_nix
if command -v nix >/dev/null 2>&1; then
  ok "nix available: $(nix --version)"
else
  warn "Open a new terminal (or 'source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh')"
  warn "to get 'nix' on your PATH, then run step 09."
fi
