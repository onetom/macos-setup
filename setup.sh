#!/bin/zsh
# Orchestrator: run the macOS setup steps in order.
#
#   ./setup.sh                              # run every step, in order
#   ./setup.sh 06 07 08                     # only these steps (by number prefix)
#   ./setup.sh 04-capslock-to-control.sh    # ... full filename works too
#   ./setup.sh --list                       # show the steps
#
# Each NN-*.sh script is idempotent and can also be run on its own.
set -euo pipefail
SCRIPT_DIR="${0:A:h}"; source "$SCRIPT_DIR/lib.sh"
require_macos

# All NN-*.sh step scripts, in order. Glob qualifiers do the work that needed a
# loop under bash 3.2:  N = null_glob (no error if none),  :t = tail (basename).
steps=( "$SCRIPT_DIR"/[0-9][0-9]-*.sh(N:t) )

if [[ "${1:-}" == "--list" ]]; then
  print -l -- "${steps[@]}"; exit 0
fi

# Optional filter: keep only steps named on the command line. Each argument is
# reduced to its leading number (${a%%-*}), so "04" and "04-capslock-to-control.sh"
# both select step 04. zsh expands an empty array cleanly under `set -u`.
if (( $# )); then
  want=()
  for a in "$@"; do want+=("${a%%-*}"); done
  filtered=()
  for s in "${steps[@]}"; do
    [[ " ${want[*]} " == *" ${s%%-*} "* ]] && filtered+=("$s")
  done
  steps=( "${filtered[@]}" )
fi

(( ${#steps[@]} )) || { warn "No steps matched: $*"; exit 0; }

log "Will run ${#steps[@]} step(s):"; printf '   - %s\n' "${steps[@]}"
read -r "ans?Proceed? [y/N] "; [[ "${ans:-}" =~ ^[Yy]$ ]] || { warn "Aborted."; exit 0; }

# Prime sudo once so the brew/nix/zerotier steps don't stall on a password prompt.
need_sudo

for s in "${steps[@]}"; do
  echo; log "==================== $s ===================="
  if zsh "$SCRIPT_DIR/$s"; then
    ok "$s completed"
  else
    err "$s failed (exit $?). Fix it and re-run:  ./setup.sh ${s%%-*}"
    exit 1
  fi
done

echo
ok "All selected steps finished."
warn "Log out and back in to apply key-repeat, Caps-Lock, zoom and hotkey changes."
