#!/usr/bin/env bash
# Install / update the runnable copy:  ./install.sh
# App code -> ~/.local/share/kirara/app, question bank -> ~/.local/share/kirara/content.db,
# launcher -> ~/.local/bin/kirara, desktop entry -> ~/.local/share/applications/kirara.desktop,
# icon -> ~/.local/share/icons/hicolor/scalable/apps/kirara.svg.
# Your progress (~/.local/share/kirara/progress.db) is never touched. JP Quiz's data moves here once (migrate.sh).
# The question bank: data/content.db when this checkout has one, else the installed one, else it is built
# (tools/build-content.sh: ~80 MB download and a few minutes).
set -euo pipefail
cd "$(dirname "$0")"
bash ./migrate.sh
DEST="$HOME/.local/share/kirara"
ICONS="$HOME/.local/share/icons/hicolor/scalable/apps"
mkdir -p "$DEST" "$HOME/.local/bin" "$HOME/.local/share/applications" "$ICONS"
command -v cargo >/dev/null || { echo "cargo is needed to build the engine (pacman -S rust)"; exit 1; }
mkdir -p data
if [ ! -f data/content.db ] && [ -f "$DEST/content.db" ]; then
    cp "$DEST/content.db" data/content.db         # code-only update: reuse the installed question bank
fi
[ -f data/content.db ] || bash tools/build-content.sh
rm -rf "$DEST/app.new"
mkdir -p "$DEST/app.new"
cp -r qml assets "$DEST/app.new/"
install -m 755 uninstall.sh "$DEST/app.new/uninstall.sh"
# the engine is Rust (engine/, kirara-engine); the JLPT/everyday/常用 lists are compiled into it
cargo build --release --quiet --manifest-path engine/Cargo.toml
install -D -m 755 engine/target/release/kirara-engine "$DEST/app.new/bin/kirara-engine"
# everyday-word questions (slang, tech, brands, cars, food…) from Tatoeba, added to content.db (idempotent)
if [ -d data/raw ]; then
    engine/target/release/everyday-pack data/raw data/content.db
fi
# swap in one step (an open window live-reloads; a gap without app/ breaks that reload)
if [ -d "$DEST/app" ] && mv --exchange "$DEST/app.new" "$DEST/app" 2>/dev/null; then
    rm -rf "$DEST/app.new"
else
    rm -rf "$DEST/app" && mv "$DEST/app.new" "$DEST/app"
fi
cp data/content.db "$DEST/content.db.new" && mv "$DEST/content.db.new" "$DEST/content.db"
install -m 755 bin/kirara "$HOME/.local/bin/kirara"
install -m 644 kirara.desktop "$HOME/.local/share/applications/kirara.desktop"
install -m 644 assets/icon/kirara.svg "$ICONS/kirara.svg"
gtk-update-icon-cache -q -t "$HOME/.local/share/icons/hicolor" 2>/dev/null || true
update-desktop-database -q "$HOME/.local/share/applications" 2>/dev/null || true
echo "installed to $DEST (progress kept)"
