# Kirara 雲母 — notes for Claude

Endless adaptive Japanese quiz, formerly JP Quiz (`jp-quiz`). One app of the Serpantinum Glass family: its own repo
(github.com/xDen4ik247/kirara), shipped as an option by the serpantinum-glass installer, which clones this repo.

## Rules (user decisions)
- **Rust only.** All new code (engine, helpers, tools, build steps) is Rust; the UI is QML (quickshell); tiny shell glue
  (`bin/kirara`, `install.sh`, `migrate.sh`, `tools/*.sh`) is fine. **No new Python.** `jpquiz/`, `build/` and `tests/`
  are frozen legacy Python: don't extend them or keep them in parity; port a step to Rust when a change needs it.
  New features go into `engine/` (`kirara-engine`) only.
- **Install what you finish.** After a change is verified, run `./install.sh` without being asked. It keeps
  `~/.local/share/kirara/progress.db`. An open window keeps the old code: tell the user to reopen it.
- No personal data in the repo; official Arch packages only.

## Layout and paths
- Data: `~/.local/share/kirara/{progress.db,content.db}` (`KIRARA_DATA`, `KIRARA_PROGRESS`, `KIRARA_CONTENT`;
  the old `JPQUIZ_*` names still work). `~/.local/share/jp-quiz` is a link to it after `migrate.sh`.
- The dev checkout's `data/` is a symlink to `~/Projects/jp-quiz/data` (raw downloads + built `content.db`, not in git).
  Without it, `install.sh` reuses the installed `content.db` or builds one (`tools/build-content.sh`).
- Anki: the deck `Japanese::Quiz` and note tag `jp-quiz` are names in the user's collection: never rename them.
- Window: app-id `kirara`, title "Kirara" (tests: "Kirara (test)", never steals focus), IPC target `kirara`.
- Tests: `cargo test --manifest-path engine/Cargo.toml` (the Anki test needs `data/content.db`).
