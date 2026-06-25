#!/usr/bin/env bash
# SPDX-License-Identifier: MPL-2.0
# uninstall.sh — remove the user-level units and wrapper. Leaves .wslconfig alone.
set -uo pipefail
systemctl --user disable --now estate-guard.timer 2>/dev/null || true
rm -f "$HOME/.config/systemd/user/builds.slice" \
      "$HOME/.config/systemd/user/estate-guard.service" \
      "$HOME/.config/systemd/user/estate-guard.timer" \
      "$HOME/.local/bin/bgc" \
      "$HOME/.local/bin/estate-guard.sh"
systemctl --user daemon-reload 2>/dev/null || true
echo "uninstalled (your .wslconfig was not touched)."
