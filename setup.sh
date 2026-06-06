#!/usr/bin/env bash
# Orchestrator: run the macOS setup steps in order.
#
#   ./setup.sh              # run every step, in order
#   ./setup.sh 06 07 08     # run only the steps whose filename starts with these
#   ./setup.sh --list       # show the steps
#
# Each NN-*.sh script is idempotent and can also be run on its own.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; source "$SCRIPT_DIR/lib.sh"
require_macos

# Collect the NN-*.sh step scripts in order (glob sorts lexicographically).
# Built with a loop instead of `mapfile` so it works on macOS's stock bash 3.2.
STEPS=()
for _f in "$SCRIPT_DIR"/[0-9][0-9]-*.sh; do STEPS+=("$(basename "$_f")"); done

if [[ "${1:-}" == "--list" ]]; then
  printf '%s\n' "${STEPS[@]}"; exit 0
fi

# Optional filter: keep only steps whose number prefix was passed as an argument.
if [[ $# -gt 0 ]]; then
  want=" $* "
  filtered=()
  for s in "${STEPS[@]}"; do
    [[ "$want" == *" ${s%%-*} "* ]] && filtered+=("$s")
  done
  STEPS=("${filtered[@]}")
fi

log "Will run ${#STEPS[@]} step(s):"; printf '   - %s\n' "${STEPS[@]}"
read -r -p "Proceed? [y/N] " ans; [[ "$ans" =~ ^[Yy]$ ]] || { warn "Aborted."; exit 0; }

# Prime sudo once so the brew/nix/zerotier steps don't stall on a password prompt.
need_sudo

for s in "${STEPS[@]}"; do
  echo; log "==================== $s ===================="
  if bash "$SCRIPT_DIR/$s"; then
    ok "$s completed"
  else
    err "$s failed (exit $?). Fix it and re-run:  ./setup.sh ${s%%-*}"
    exit 1
  fi
done

echo
ok "All selected steps finished."
warn "Log out and back in to apply key-repeat, Caps-Lock, zoom and hotkey changes."
