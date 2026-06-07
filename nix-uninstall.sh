#!/bin/zsh
# Uninstall Nix (upstream multi-user / daemon install) on macOS.
#
# Reverses what 08-nix.sh + the official installer set up: the daemon, the
# dedicated /nix APFS volume, the synthetic.conf mount-point entry, the _nixbld
# users/group, and the shell-init snippets. Every step is guarded so it is safe
# to run against a *partial* install (e.g. an aborted run that only got as far as
# creating the volume) as well as a complete one.
#
# A reboot is required at the end: /etc/synthetic.conf is only re-read at boot,
# so the /nix mount-point mapping lingers until then.
set -euo pipefail
SCRIPT_DIR="${0:A:h}"; source "$SCRIPT_DIR/lib.sh"
require_macos

# --- confirmation -----------------------------------------------------------
ASSUME_YES=0
[[ "${1:-}" == "-y" || "${1:-}" == "--yes" ]] && ASSUME_YES=1
if (( ! ASSUME_YES )); then
  warn "This will remove Nix and DELETE the 'Nix Store' APFS volume on this Mac."
  printf '%sProceed? [y/N] %s' "$_YELLOW" "$_R"
  read -r reply </dev/tty
  [[ "$reply" == [yY]* ]] || { err "Aborted."; exit 1; }
fi

need_sudo

# --- 1. stop & remove the launchd daemons -----------------------------------
for d in org.nixos.nix-daemon org.nixos.darwin-store; do
  plist="/Library/LaunchDaemons/$d.plist"
  if [[ -e "$plist" ]]; then
    log "Removing launchd daemon $d"
    sudo launchctl bootout system "$plist" 2>/dev/null || true
    sudo rm -f "$plist"
    ok "Removed $d"
  fi
done

# --- 2. restore shell init files --------------------------------------------
# The installer backs each file up to *.backup-before-nix before editing it.
for f in /etc/zshrc /etc/bashrc /etc/profile /etc/zprofile /etc/bash.bashrc; do
  if [[ -e "$f.backup-before-nix" ]]; then
    log "Restoring $f from backup-before-nix"
    sudo mv -f "$f.backup-before-nix" "$f"
    ok "Restored $f"
  fi
done

# --- 3. delete the _nixbld build users and group ----------------------------
nixbld_users=$(sudo dscl . -list /Users 2>/dev/null | grep -E '^_?nixbld' || true)
if [[ -n "$nixbld_users" ]]; then
  log "Deleting _nixbld build users"
  while IFS= read -r u; do
    [[ -n "$u" ]] && sudo dscl . -delete "/Users/$u" 2>/dev/null || true
  done <<< "$nixbld_users"
  ok "Removed build users"
fi
if sudo dscl . -read /Groups/nixbld >/dev/null 2>&1; then
  sudo dscl . -delete /Groups/nixbld 2>/dev/null || true
  ok "Removed nixbld group"
fi

# --- 4. unmount & delete the Nix Store APFS volume --------------------------
if mount | grep -qE ' /nix '; then
  log "Unmounting /nix"
  sudo diskutil unmount force /nix || true
fi
# Last field of the matching `diskutil list` row is the volume's diskNsM id.
nix_vol=$(diskutil list | awk '/Nix Store/ {print $NF}' | head -n1)
if [[ -n "$nix_vol" ]]; then
  log "Deleting APFS volume 'Nix Store' ($nix_vol)"
  sudo diskutil apfs deleteVolume "$nix_vol"
  ok "Deleted volume $nix_vol"
else
  ok "No 'Nix Store' volume to delete"
fi

# --- 5. drop the /nix entry from /etc/synthetic.conf ------------------------
if [[ -e /etc/synthetic.conf ]]; then
  # Keep any non-nix lines; remove the file entirely if nix was its only content.
  remaining=$(sudo grep -vE '^nix([[:space:]]|$)' /etc/synthetic.conf || true)
  if [[ -z "${remaining//[[:space:]]/}" ]]; then
    log "Removing /etc/synthetic.conf (only held the nix entry)"
    sudo rm -f /etc/synthetic.conf
  else
    log "Stripping nix line from /etc/synthetic.conf (keeping other entries)"
    printf '%s\n' "$remaining" | sudo tee /etc/synthetic.conf >/dev/null
  fi
  ok "synthetic.conf cleaned"
fi

# --- 6. drop the /nix entry from /etc/fstab ---------------------------------
if [[ -e /etc/fstab ]] && sudo grep -q '/nix' /etc/fstab; then
  log "Removing /nix line from /etc/fstab"
  sudo sed -i '' '/[[:space:]]\/nix[[:space:]]/d' /etc/fstab
  ok "fstab cleaned"
fi

# --- 7. remove leftover directories -----------------------------------------
if [[ -d /nix ]]; then
  if sudo rmdir /nix 2>/dev/null; then
    ok "Removed empty /nix mount-point"
  else
    warn "/nix is not empty (store volume may still be mounted) — left in place"
  fi
fi
[[ -d /etc/nix ]] && { sudo rm -rf /etc/nix; ok "Removed /etc/nix"; }

# Per-user profile leftovers (current user).
for d in "$HOME/.nix-profile" "$HOME/.nix-defexpr" "$HOME/.nix-channels" \
         "$HOME/.local/state/nix" "$HOME/.cache/nix"; do
  [[ -e "$d" ]] && { rm -rf "$d"; ok "Removed ${d/#$HOME/~}"; }
done
# root's profile leftovers (the daemon install writes these too).
for d in /var/root/.nix-profile /var/root/.nix-defexpr /var/root/.nix-channels; do
  [[ -e "$d" ]] && { sudo rm -rf "$d"; ok "Removed $d"; }
done

ok "Nix uninstalled."
warn "Reboot now so macOS forgets the /nix synthetic mount-point:  sudo reboot"
warn "After rebooting you can re-run 08-nix.sh for a clean install."
