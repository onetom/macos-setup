#!/usr/bin/env bash
# Populate an Ed25519 SSH key pair from values inlined below.
#
# >>> EDIT THIS FILE <<<  Paste your real private key between the PRIVATE markers and
# your real public key into PUBKEY. The script refuses to run while the placeholders
# are unchanged, so it can't accidentally install a dummy key.
#
# Filename note: your spec wrote `id_ed25519P{,.pub}`. The trailing "P" looked like a
# stray character, so KEY_NAME defaults to the conventional `id_ed25519`. Change it to
# `id_ed25519P` here if that was intentional.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; source "$SCRIPT_DIR/lib.sh"
require_macos

KEY_NAME="id_ed25519"
SSH_DIR="$HOME/.ssh"
PRIV="$SSH_DIR/$KEY_NAME"
PUB="$SSH_DIR/$KEY_NAME.pub"

# ---------------------------------------------------------------------------
# Inline your key material here.
# ---------------------------------------------------------------------------
read -r -d '' PRIVKEY <<'PRIVATE' || true
-----BEGIN OPENSSH PRIVATE KEY-----
REPLACE_WITH_YOUR_PRIVATE_KEY_BODY
-----END OPENSSH PRIVATE KEY-----
PRIVATE

PUBKEY='ssh-ed25519 REPLACE_WITH_YOUR_PUBLIC_KEY user@host'
# ---------------------------------------------------------------------------

if [[ "$PRIVKEY" == *REPLACE_WITH_YOUR_PRIVATE_KEY_BODY* || "$PUBKEY" == *REPLACE_WITH_YOUR_PUBLIC_KEY* ]]; then
  err "Placeholder key material detected. Edit $(basename "${BASH_SOURCE[0]}") and paste your real keys first."
  exit 1
fi

log "Writing key pair to $SSH_DIR ($KEY_NAME)"
mkdir -p "$SSH_DIR"; chmod 700 "$SSH_DIR"

umask 077
printf '%s\n' "$PRIVKEY" > "$PRIV"
chmod 600 "$PRIV"

printf '%s\n' "$PUBKEY" > "$PUB"
chmod 644 "$PUB"

# Sanity check: a valid private key fingerprints cleanly.
if ssh-keygen -y -f "$PRIV" >/dev/null 2>&1; then
  ok "private key OK: $(ssh-keygen -lf "$PRIV" | awk '{print $2}')"
else
  warn "ssh-keygen could not parse the private key — double-check the pasted contents."
fi
ok "wrote $PRIV (600) and $PUB (644)"
