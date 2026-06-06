# macOS new-account setup

Automation for a fresh macOS user account (tested target: macOS 26 "Tahoe", Apple
Silicon). Each step is a small, idempotent script; `setup.sh` runs them in order.

## Usage

```sh
cd macos-setup
chmod +x *.sh
# 1) Paste your real keys into the untracked id_ed25519 / id_ed25519.pub files
#    (git-ignored; the script refuses the shipped placeholders).
./setup.sh            # run everything, with a confirmation prompt
./setup.sh --list     # list the steps
./setup.sh 06 07 08   # run only Homebrew + apps + ZeroTier join
```

You do **not** need to be signed in to the App Store — every app is installed via
Homebrew casks, not the Mac App Store.

Run the Terminal step (05) from a non-Terminal shell (iTerm/VS Code/SSH) if you can;
see the note in that script for why.

## Steps

| # | Script | What it does |
|---|--------|--------------|
| 01 | `01-keyboard-and-text.sh`     | Fastest key repeat/delay; turn off auto-correction and smart quotes |
| 02 | `02-screen-zoom.sh`           | Control + scroll to zoom the screen |
| 03 | `03-disable-hotkeys.sh`       | Free Cmd-M (and friends) from the menu so IntelliJ/Emacs can use them |
| 04 | `04-capslock-to-control.sh`   | Caps Lock → Control, persisted via a login LaunchAgent |
| 05 | `05-terminal-profile.sh`      | Terminal "Clear Light": Option-as-Meta, 120×40, 10k scrollback, no bell |
| 06 | `06-homebrew.sh`              | Install Homebrew + add to shell |
| 07 | `07-brew-apps.sh`             | Install zerotier-one, 1password, 1password-cli, firefox |
| 08 | `08-zerotier-join.sh`         | Join ZeroTier network `123456789012` |
| 09 | `09-nix.sh`                   | Install Nix (Determinate installer, flakes enabled) |
| 10 | `10-direnv-nix-direnv.sh`     | Install direnv + nix-direnv via Nix; hook into zsh |
| 11 | `11-ssh-keys.sh`              | Install `~/.ssh/id_ed25519{,.pub}` from the untracked key files |

## Things that need a logout or a click

- **Log out / back in** to fully apply: key repeat, Caps-Lock remap, screen zoom,
  and the freed menu shortcuts.
- **ZeroTier** prompts you to *Allow* its system extension the first time, and the
  node must be authorised in the ZeroTier controller for network `123456789012`.
- **`com.apple.universalaccess`** (zoom) is privacy-protected; if step 02 doesn't
  take effect, grant your terminal Full Disk Access or flip the toggle once in
  System Settings → Accessibility → Zoom.
- **Nix**: open a new terminal after step 09 so `nix` is on your PATH before step 10.

## Customising

- Key-repeat speed: edit `InitialKeyRepeat` / `KeyRepeat` in step 01.
- More menu shortcuts to free: add `NSUserKeyEquivalents` entries in step 03.
- ZeroTier network ID: `NETWORK_ID` in step 08.
- SSH key filename: `KEY_NAME` in step 11 (defaults to `id_ed25519`).
