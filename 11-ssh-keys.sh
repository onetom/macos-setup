#!/bin/zsh
# Install an Ed25519 SSH key pair into ~/.ssh.
#
# The key material lives in two UNTRACKED files next to this script:
#     id_ed25519       (private key)
#     id_ed25519.pub   (public key)
# They are git-ignored so secrets never land in the repo. Paste your real keys into
# them before running; the script refuses to install the shipped placeholders.
#
# Filename note: your spec wrote `id_ed25519P{,.pub}`. The trailing "P" looked like a
# stray character, so KEY_NAME defaults to the conventional `id_ed25519`. Change it
# here (and rename the two source files to match) if that "P" was intentional.
set -euo pipefail
SCRIPT_DIR="${0:A:h}"; source "$SCRIPT_DIR/lib.sh"
require_macos

KEY_NAME="id_ed25519"
SRC_PRIV="$SCRIPT_DIR/$KEY_NAME"
SRC_PUB="$SCRIPT_DIR/$KEY_NAME.pub"
SSH_DIR="$HOME/.ssh"
DST_PRIV="$SSH_DIR/$KEY_NAME"
DST_PUB="$SSH_DIR/$KEY_NAME.pub"

for f in "$SRC_PRIV" "$SRC_PUB"; do
  [[ -f "$f" ]] || { err "Missing key file: $f  (create it and paste your key material)"; exit 1; }
done

if grep -q 'REPLACE_WITH_YOUR_' "$SRC_PRIV" "$SRC_PUB" 2>/dev/null; then
  err "Placeholder key material detected in $SRC_PRIV / $SRC_PUB."
  err "Paste your real keys into those files first."
  exit 1
fi

log "Installing key pair into $SSH_DIR ($KEY_NAME)"
mkdir -p "$SSH_DIR"; chmod 700 "$SSH_DIR"

umask 077
install -m 600 "$SRC_PRIV" "$DST_PRIV"
install -m 644 "$SRC_PUB"  "$DST_PUB"

# Sanity check: a valid private key fingerprints cleanly.
if ssh-keygen -y -f "$DST_PRIV" >/dev/null 2>&1; then
  ok "private key OK: $(ssh-keygen -lf "$DST_PRIV" | awk '{print $2}')"
else
  warn "ssh-keygen could not parse the private key — double-check $SRC_PRIV."
fi
ok "installed $DST_PRIV (600) and $DST_PUB (644)"
