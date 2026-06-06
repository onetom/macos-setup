#!/bin/zsh
# Join a ZeroTier network. Requires zerotier-one (installed in step 07) and its
# background service to be running + approved.
set -euo pipefail
SCRIPT_DIR="${0:A:h}"; source "$SCRIPT_DIR/lib.sh"
require_macos

NETWORK_ID="123456789012"

# Locate the CLI: the installer drops a symlink in /usr/local/bin, but fall back
# to the bundled binary under Application Support.
ZT_CLI=""
for cand in zerotier-cli /usr/local/bin/zerotier-cli \
            "/Library/Application Support/ZeroTier/One/zerotier-cli"; do
  if command -v "$cand" >/dev/null 2>&1 || [[ -x "$cand" ]]; then ZT_CLI="$cand"; break; fi
done
[[ -n "$ZT_CLI" ]] || { err "zerotier-cli not found. Install zerotier-one (step 07) and launch ZeroTier One.app once."; exit 1; }

need_sudo
# Wait briefly for the service to come up (it needs to be running to accept a join).
for _ in $(seq 1 10); do
  sudo "$ZT_CLI" info >/dev/null 2>&1 && break
  sleep 1
done

log "Joining ZeroTier network $NETWORK_ID"
sudo "$ZT_CLI" join "$NETWORK_ID"
echo
log "Current network status:"
sudo "$ZT_CLI" listnetworks || true

warn "If status shows ACCESS_DENIED, authorise this node in the ZeroTier Central"
warn "controller (my.zerotier.com) for network $NETWORK_ID."
warn "If the join fails, open ZeroTier One.app once and Allow its system extension,"
warn "then re-run this step."
