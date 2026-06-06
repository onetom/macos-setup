#!/usr/bin/env bash
# Shared helpers for the macOS setup scripts. Sourced by every step script.

# Pretty logging (color only when stdout is a TTY).
if [[ -t 1 ]]; then
  _B=$'\033[1m'; _BLUE=$'\033[34m'; _GREEN=$'\033[32m'; _YELLOW=$'\033[33m'; _RED=$'\033[31m'; _R=$'\033[0m'
else
  _B=""; _BLUE=""; _GREEN=""; _YELLOW=""; _RED=""; _R=""
fi
log()  { printf '%s==>%s %s\n'  "${_BLUE}${_B}" "$_R" "$*"; }
ok()   { printf '%s  \xe2\x9c\x93%s %s\n' "$_GREEN" "$_R" "$*"; }
warn() { printf '%s  !%s %s\n'  "$_YELLOW" "$_R" "$*"; }
err()  { printf '%s  \xe2\x9c\x97%s %s\n' "$_RED" "$_R" "$*" >&2; }

require_macos() {
  [[ "$(uname -s)" == "Darwin" ]] || { err "This script targets macOS only."; exit 1; }
}

# Detect the Homebrew prefix (Apple Silicon vs Intel) and load it into the env.
brew_prefix() {
  if   [[ -x /opt/homebrew/bin/brew ]]; then echo /opt/homebrew
  elif [[ -x /usr/local/bin/brew   ]]; then echo /usr/local
  else return 1; fi
}
load_brew() {
  local p; p="$(brew_prefix)" || return 1
  eval "$("$p/bin/brew" shellenv)"
}

# Source the nix daemon profile into the current shell, if nix is installed.
load_nix() {
  local d="/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
  [[ -e "$d" ]] && . "$d"
  [[ -e "$HOME/.nix-profile/bin" ]] && export PATH="$HOME/.nix-profile/bin:$PATH"
}

# Append a line to a file only if it is not already present.
ensure_line() {
  local line="$1" file="$2"
  mkdir -p "$(dirname "$file")"; touch "$file"
  grep -qxF -- "$line" "$file" || printf '%s\n' "$line" >> "$file"
}

# Prime sudo once up front so later sudo calls don't interrupt mid-run.
need_sudo() {
  if ! sudo -n true 2>/dev/null; then
    log "Some steps need administrator rights. Enter your password if prompted."
    sudo -v
  fi
}
