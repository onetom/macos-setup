#!/bin/zsh
# Configure Terminal.app: default profile "Clear Light" + behavioural tweaks.
#
# Terminal stores each profile as a nested dict under `Window Settings`. A built-in
# profile only appears in your prefs once it's been selected, so we first use
# AppleScript to materialise "Clear Light" (which also pulls in its full colour set),
# then patch the remaining keys with PlistBuddy.
#
# NOTE: Terminal rewrites its prefs from memory when it quits, which can clobber
# direct plist edits. For a reliable result, run this step while Terminal is NOT the
# host shell (e.g. from iTerm/VS Code/SSH), or quit Terminal afterwards as instructed.
set -euo pipefail
SCRIPT_DIR="${0:A:h}"; source "$SCRIPT_DIR/lib.sh"
require_macos

PROFILE="Clear Light"
PLIST="$HOME/Library/Preferences/com.apple.Terminal.plist"
HOSTED_IN_TERMINAL=false
[[ "${TERM_PROGRAM:-}" == "Apple_Terminal" ]] && HOSTED_IN_TERMINAL=true

log "Materialising the \"$PROFILE\" profile and setting it as default"
osascript <<OSA
tell application "Terminal"
    set cs to (first settings set whose name is "$PROFILE")
    set default settings to cs
    set startup settings to cs
    set number of columns of cs to 120
    set number of rows of cs to 40
end tell
OSA
ok "default + startup profile = $PROFILE, window size 120x40"

# Flush Terminal's in-memory prefs to disk so PlistBuddy edits below stick.
if ! $HOSTED_IN_TERMINAL; then
  osascript -e 'tell application "Terminal" to quit' 2>/dev/null || true
  # wait for it to actually exit
  for _ in 1 2 3 4 5 6 7 8 9 10; do pgrep -x Terminal >/dev/null || break; sleep 0.3; done
fi

pb() { # set-or-add a typed key inside the Clear Light profile dict
  local key="$1" type="$2" val="$3"
  local path=":Window Settings:${PROFILE}:${key}"
  /usr/libexec/PlistBuddy -c "Set '$path' $val" "$PLIST" 2>/dev/null \
    || /usr/libexec/PlistBuddy -c "Add '$path' $type $val" "$PLIST"
}

log "Applying profile behaviour"
pb useOptionAsMetaKey   bool    true     # "Use Option as Meta key"
pb columnCount          integer 120      # default window width
pb rowCount             integer 40       # default window height
pb ShouldLimitScrollback bool   true     # "Limit number of rows to ..."
pb ScrollbackLines      integer 10000    # ... 10,000 (instead of available memory)
pb Bell                 bool    false    # turn OFF the audible bell
ok "meta key on, 120x40, scrollback=10000 rows, audible bell off"

# Make sure the on-disk defaults agree (belt and braces).
defaults write com.apple.Terminal "Default Window Settings" -string "$PROFILE"
defaults write com.apple.Terminal "Startup Window Settings" -string "$PROFILE"
killall cfprefsd 2>/dev/null || true

echo
log "Verification (read back from prefs):"
defaults read com.apple.Terminal "Default Window Settings"
for k in useOptionAsMetaKey columnCount rowCount ShouldLimitScrollback ScrollbackLines Bell; do
  printf '  %-22s = %s\n' "$k" "$(/usr/libexec/PlistBuddy -c "Print ':Window Settings:${PROFILE}:${k}'" "$PLIST" 2>/dev/null || echo '(unset)')"
done

if $HOSTED_IN_TERMINAL; then
  warn "You ran this inside Terminal.app. Quit Terminal completely (Cmd-Q) and reopen"
  warn "to load the new profile. If any value above is wrong, re-run this step from a"
  warn "non-Terminal shell so Terminal isn't holding stale prefs in memory."
fi
