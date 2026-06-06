#!/bin/zsh
# Install direnv + nix-direnv via Nix, then hook them into zsh.
set -euo pipefail
SCRIPT_DIR="${0:A:h}"; source "$SCRIPT_DIR/lib.sh"
require_macos
load_nix
command -v nix >/dev/null 2>&1 || { err "nix not on PATH. Run 09-nix.sh and open a new shell first."; exit 1; }

log "Installing direnv and nix-direnv into your user nix profile"
# nix-command + flakes are enabled by the Determinate installer; pass them explicitly
# so this also works on an upstream install.
NIX_OPTS=(--extra-experimental-features 'nix-command flakes')
nix "${NIX_OPTS[@]}" profile install nixpkgs#direnv nixpkgs#nix-direnv
ok "direnv + nix-direnv installed"

# Hook direnv into zsh.
ensure_line 'eval "$(direnv hook zsh)"' "$HOME/.zshrc"
ok "direnv hook added to ~/.zshrc"

# Wire nix-direnv into direnv (gives the fast, cached `use flake` / `use nix`).
DIRENVRC="$HOME/.config/direnv/direnvrc"
ensure_line 'source "$HOME/.nix-profile/share/nix-direnv/direnvrc"' "$DIRENVRC"
ok "nix-direnv sourced from $DIRENVRC"

warn "Open a new terminal so the direnv hook loads. In any project, drop a .envrc"
warn "(e.g. 'use flake') and run 'direnv allow'."
