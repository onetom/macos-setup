#!/bin/zsh
# Install the Nix package manager via the official upstream installer.
#
# This uses nixos.org's own install script. On macOS it performs a multi-user
# (daemon) install, creating the dedicated /nix APFS volume and /etc/nix/nix.conf.
# The upstream installer does NOT enable flakes, so afterwards we turn on the
# nix-command + flakes experimental features that step 09 (nix profile install)
# needs.
set -euo pipefail
SCRIPT_DIR="${0:A:h}"; source "$SCRIPT_DIR/lib.sh"
require_macos

NIX_CONF=/etc/nix/nix.conf

if command -v nix >/dev/null 2>&1 || [[ -e /nix/var/nix/profiles/default ]]; then
  ok "Nix already installed"
else
  log "Installing Nix (multi-user daemon; you may be prompted for your password)"
  # Process substitution keeps the installer's interactive prompts on the terminal.
  sh <(curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install) --daemon
  ok "Nix installed"
fi

# Enable flakes + the new CLI. The upstream installer leaves these off by default.
log "Enabling experimental features (nix-command, flakes) in $NIX_CONF"
if [[ -e "$NIX_CONF" ]] && grep -qE '^[[:space:]]*experimental-features[[:space:]]*=.*\bflakes\b' "$NIX_CONF"; then
  ok "experimental-features already enabled"
else
  need_sudo
  printf 'experimental-features = nix-command flakes\n' | sudo tee -a "$NIX_CONF" >/dev/null
  ok "experimental-features enabled (restart the nix-daemon or open a new shell to apply)"
fi

load_nix
if command -v nix >/dev/null 2>&1; then
  ok "nix available: $(nix --version)"
else
  warn "Open a new terminal (or 'source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh')"
  warn "to get 'nix' on your PATH, then run step 09."
fi
