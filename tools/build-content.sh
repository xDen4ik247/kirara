#!/usr/bin/env bash
# Build the question bank data/content.db: downloads the open data (Tatoeba, JMdict, KANJIDIC, JLPT lists; ~80 MB)
# into data/raw/, then runs the content build (the frozen Python pipeline in build/) in its own uv venv
# (fugashi, unidic-lite, numpy; ~300 MB). install.sh runs this only when no question bank is installed yet.
set -euo pipefail
cd "$(dirname "$0")/.."
VENV="${KIRARA_VENV:-}"
if [ -z "$VENV" ]; then
    if [ -x "$HOME/.venvs/jp-quiz/bin/python" ]; then VENV="$HOME/.venvs/jp-quiz"; else VENV="$HOME/.venvs/kirara"; fi
fi
mkdir -p data
if [ ! -f data/raw/JMdict.gz ] || [ ! -f data/raw/eng_sentences.tsv.bz2 ]; then
    echo "kirara: downloading the open data (~80 MB)"
    bash build/fetch.sh
fi
if [ ! -x "$VENV/bin/python" ] || ! "$VENV/bin/python" -c 'import fugashi, unidic_lite, numpy' 2>/dev/null; then
    command -v uv >/dev/null || { echo "uv is missing (pacman -S uv)"; exit 1; }
    echo "kirara: build environment ${VENV/#$HOME/\~} (fugashi, unidic-lite, numpy; ~300 MB)"
    uv venv -q --seed --python 3.12 "$VENV"
    uv pip install -q --python "$VENV/bin/python" fugashi unidic-lite numpy
fi
echo "kirara: building the question bank (a few minutes)"
"$VENV/bin/python" -m build.make_content
[ -f data/content.db ]
