#!/bin/zsh
# Stop macOS menu shortcuts from shadowing app-defined keystrokes (IntelliJ, Emacs, ...).
#
# You can't *delete* a menu command's shortcut from the CLI, but you can remap it.
# We remap the menu item to a "Hyper" combo (Cmd+Ctrl+Opt+Shift+<key>) via
# NSGlobalDomain's NSUserKeyEquivalents. The plain keystroke (e.g. Cmd-M) then falls
# through to the focused application instead of triggering the macOS menu command.
#
# Modifier glyphs in the value string:  @=Command  ^=Control  ~=Option  $=Shift
# Keyed by the *menu item title*, so it applies in every app that exposes that title.
set -euo pipefail
SCRIPT_DIR="${0:A:h}"; source "$SCRIPT_DIR/lib.sh"
require_macos

log "Free up menu shortcuts so apps can use them"

# Cmd-M (Window > Minimize) -> Hyper-M. Frees plain Cmd-M for IntelliJ/Emacs/etc.
defaults write -g NSUserKeyEquivalents -dict-add "Minimize" '@~^$m'
ok 'Minimize remapped to Cmd+Ctrl+Opt+Shift+M (plain Cmd-M now passes through)'

# --- Cmd-/ ---------------------------------------------------------------------
# There is NO default macOS menu command bound to plain Cmd-/ , so there is usually
# nothing to disable -- IntelliJ "Comment with Line Comment" and Emacs already get it.
# If a *specific* app binds Cmd-/ to a menu item that shadows you, add its menu title:
#   defaults write -g NSUserKeyEquivalents -dict-add "<Menu Item Title>" '@~^$/'
#
# Other commonly-shadowing items you may want to free (uncomment as desired):
# defaults write -g NSUserKeyEquivalents -dict-add "Hide <App>" '@~^$h'   # Cmd-H
# defaults write -g NSUserKeyEquivalents -dict-add "Minimize All" '@~^$m'

warn "Already-running apps must be relaunched to pick up the new key equivalents."
