#!/usr/bin/env bash
# migrate.sh — one-time move of JP Quiz's data to Kirara (the app's new name). install.sh runs it first; re-running is a no-op.
#   ./migrate.sh            ~/.local/share/jp-quiz → ~/.local/share/kirara (the old path stays as a link), retires the
#                           old desktop entry and icon, and turns ~/.local/bin/jp-quiz into a shim that runs kirara
#   ./migrate.sh --revert   undo that; then reinstall the old app (serpantinum-glass tag pre-app-split)
# It refuses while the app is open and never merges: if both the old and the new folder exist it stops.
# Anki is not touched: the deck (Japanese::Quiz) and the note tag (jp-quiz) keep their names.
set -euo pipefail
OLD=jp-quiz NEW=kirara NAME=Kirara
PARENTS=(.local/share)                      # $HOME/<parent>/$OLD → $HOME/<parent>/$NEW
OLD_UNITS=()
NEW_UNITS=()
OLD_FILES=(.local/share/applications/jp-quiz.desktop .local/share/icons/hicolor/scalable/apps/jp-quiz.svg)
NEW_FILES=(.local/bin/kirara .local/share/applications/kirara.desktop .local/share/icons/hicolor/scalable/apps/kirara.svg)
SHIM=.local/bin/jp-quiz
BACKUP=(.local/share/jp-quiz/progress.db)
RUNNING='(jp-quiz|kirara)-engine'
RUNNING_EXCEPT=''

UNITS_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
say() { printf 'migrate: %s\n' "$*"; }
have_systemd() { command -v systemctl >/dev/null 2>&1 && systemctl --user show-environment >/dev/null 2>&1; }
running() { pgrep -af "$RUNNING" 2>/dev/null | grep -Ev -e "${RUNNING_EXCEPT:-^$}" | grep -q .; }
refresh() {
    gtk-update-icon-cache -q -t "$HOME/.local/share/icons/hicolor" 2>/dev/null || true
    update-desktop-database -q "$HOME/.local/share/applications" 2>/dev/null || true
}
stop_units() {
    local u
    for u in "$@"; do
        have_systemd && systemctl --user disable --now "$u" >/dev/null 2>&1 || true
        rm -f "$UNITS_DIR/$u"
    done
    [ $# -gt 0 ] && have_systemd && systemctl --user daemon-reload 2>/dev/null || true
}

forward() {
    local p o n todo=0 f bdir=""
    for p in "${PARENTS[@]}"; do
        o="$HOME/$p/$OLD"; n="$HOME/$p/$NEW"
        if [ -d "$o" ] && [ ! -L "$o" ]; then
            [ -e "$n" ] && { say "both ~/$p/$OLD and ~/$p/$NEW exist: not merging them, sort that out by hand"; exit 3; }
            todo=1
        fi
    done
    if [ "$todo" = 1 ]; then
        running && { say "$NAME (or its pre-rename version) is running: close it, then install again"; exit 2; }
        # staged outside the folders that move (~/.local/state/$NEW may be one of them), filed after the moves
        mkdir -p "$HOME/.local/state"
        bdir=$(mktemp -d "$HOME/.local/state/.$NEW-pre-migrate.XXXXXX")
        for f in "${BACKUP[@]}"; do [ -f "$HOME/$f" ] && cp -a "$HOME/$f" "$bdir/"; done
    fi
    stop_units "${OLD_UNITS[@]}"
    for p in "${PARENTS[@]}"; do
        o="$HOME/$p/$OLD"; n="$HOME/$p/$NEW"
        if [ -d "$o" ] && [ ! -L "$o" ]; then
            mv -T "$o" "$n" || { say "could not move ~/$p/$OLD → ~/$p/$NEW: stopped (backup: ${bdir/#$HOME/\~})"; exit 4; }
            ln -s "$NEW" "$o"
            say "moved ~/$p/$OLD → ~/$p/$NEW (the old path stays as a link)"
        fi
    done
    for f in "${OLD_FILES[@]}"; do rm -f "$HOME/$f"; done
    if [ -n "$SHIM" ]; then
        mkdir -p "$(dirname "$HOME/$SHIM")"
        printf '#!/bin/sh\n# %s was renamed to %s: this shim keeps old keybinds and scripts working.\nexec "$HOME/.local/bin/%s" "$@"\n' \
            "$OLD" "$NEW" "$NEW" > "$HOME/$SHIM"
        chmod 755 "$HOME/$SHIM"
    fi
    if [ -n "$bdir" ]; then
        mkdir -p "$HOME/.local/state/$NEW"
        mv -T "$bdir" "$HOME/.local/state/$NEW/pre-migrate-$(date +%Y%m%d-%H%M%S)"
        say "backup of the key files: ~/.local/state/$NEW/pre-migrate-*"
    fi
    mkdir -p "$HOME/.local/share/$NEW" && touch "$HOME/.local/share/$NEW/.migrated"
    refresh
}

revert() {
    local p o n f
    running && { say "$NAME is running: close it first"; exit 2; }
    stop_units "${NEW_UNITS[@]}"
    rm -f "$HOME/.local/share/$NEW/.migrated"
    for p in "${PARENTS[@]}"; do
        o="$HOME/$p/$OLD"; n="$HOME/$p/$NEW"
        if [ -L "$o" ] && [ -d "$n" ] && [ ! -L "$n" ]; then
            rm "$o" && mv -T "$n" "$o" || { say "could not move ~/$p/$NEW back: stopped"; exit 4; }
            say "moved ~/$p/$NEW back to ~/$p/$OLD"
        fi
    done
    for f in "${NEW_FILES[@]}"; do rm -f "$HOME/$f"; done
    [ -n "$SHIM" ] && grep -qs "was renamed to $NEW" "$HOME/$SHIM" && rm -f "$HOME/$SHIM"
    refresh
    say "reverted: reinstall the pre-rename app from serpantinum-glass (git tag pre-app-split, apps/$OLD/install.sh)"
}

case "${1:-}" in
    --revert) revert ;;
    "") forward ;;
    *) echo "usage: $0 [--revert]" >&2; exit 64 ;;
esac
