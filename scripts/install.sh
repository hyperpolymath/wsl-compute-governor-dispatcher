#!/usr/bin/env bash
# SPDX-License-Identifier: MPL-2.0
# install.sh — wire wsl-compute-governor-dispatcher into the current user.
# Idempotent. No root needed (uses systemd --user).
set -euo pipefail
here="$(cd "$(dirname "$0")/.." && pwd)"

install -Dm755 "$here/bin/bgc"                "$HOME/.local/bin/bgc"
install -Dm755 "$here/scripts/estate-guard.sh" "$HOME/.local/bin/estate-guard.sh"
mkdir -p "$HOME/.config/systemd/user" "$HOME/.local/state"
for u in builds.slice estate-guard.service estate-guard.timer; do
  install -Dm644 "$here/systemd/$u" "$HOME/.config/systemd/user/$u"
done

systemctl --user daemon-reload
systemctl --user enable --now estate-guard.timer
loginctl enable-linger "$USER" 2>/dev/null || echo "note: linger needs sudo; timer runs while a WSL session is active."

echo "installed."
command -v bgc >/dev/null || echo "WARN: add ~/.local/bin to PATH so 'bgc' is found."
echo "next: edit %USERPROFILE%\\.wslconfig per config/wslconfig.example, then run 'wsl --shutdown' from PowerShell."
