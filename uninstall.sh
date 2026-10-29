#!/usr/bin/env bash
# uninstall.sh — remove Kirara's program files. Your data (~/.local/share/kirara: progress.db, content.db) stays.
set -uo pipefail
rm -rf "$HOME/.local/share/kirara/app" "$HOME/.local/share/kirara/app.new"
rm -f "$HOME/.local/bin/kirara" "$HOME/.local/share/applications/kirara.desktop" "$HOME/.local/share/icons/hicolor/scalable/apps/kirara.svg"
grep -qs "was renamed to kirara" "$HOME/.local/bin/jp-quiz" && rm -f "$HOME/.local/bin/jp-quiz"
gtk-update-icon-cache -q -t "$HOME/.local/share/icons/hicolor" 2>/dev/null || true
update-desktop-database -q "$HOME/.local/share/applications" 2>/dev/null || true
echo "Kirara removed (data kept in ~/.local/share/kirara)"
