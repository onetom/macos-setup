#!/bin/zsh
# Join one or more ZeroTier networks. Requires zerotier-one (installed in step 11)
# and its background service to be running + approved.
set -euo pipefail
SCRIPT_DIR="${0:A:h}"; source "$SCRIPT_DIR/lib.sh"
require_macos

# Locate the CLI: the installer drops a symlink in /usr/local/bin, but fall back
# to the bundled binary under Application Support.
ZT_CLI=""
for cand in zerotier-cli /usr/local/bin/zerotier-cli \
            "/Library/Application Support/ZeroTier/One/zerotier-cli"; do
  if command -v "$cand" >/dev/null 2>&1 || [[ -x "$cand" ]]; then ZT_CLI="$cand"; break; fi
done
[[ -n "$ZT_CLI" ]] || { err "zerotier-cli not found. Install zerotier-one (step 11) and launch ZeroTier One.app once."; exit 1; }

need_sudo
# Wait briefly for the service to come up (it needs to be running to accept a join).
for _ in $(seq 1 10); do
  sudo "$ZT_CLI" info >/dev/null 2>&1 && break
  sleep 1
done

# Validate and join a single network. ZeroTier network IDs are 16 hex digits.
join_network() {
  local id="$1"
  [[ "$id" =~ '^[0-9a-fA-F]{16}$' ]] || { err "Invalid network ID: '$id' (expected 16 hex digits)."; return 1; }
  log "Joining ZeroTier network $id"
  sudo "$ZT_CLI" join "$id"
}

# Any IDs passed on the command line are joined first (non-interactive use).
for id in "$@"; do join_network "$id" || true; done

# Then prompt for further IDs, one per line, until a blank line or EOF. This is
# how a full setup.sh run reaches this step (it passes no args), so you can add
# as many networks as you like, or just press Enter to skip.
log "Enter ZeroTier network IDs to join (16 hex digits, from my.zerotier.com)."
log "Press Enter on an empty line when done."
while read -r "id?Network ID (blank to finish): "; do
  [[ -n "$id" ]] || break
  join_network "$id" || true
done

echo
log "Current network status:"
sudo "$ZT_CLI" listnetworks || true

warn "If a network shows ACCESS_DENIED, authorise this node in the ZeroTier Central"
warn "controller (my.zerotier.com) for that network."
warn "If a join fails, open ZeroTier One.app once and Allow its system extension,"
warn "then re-run this step."
