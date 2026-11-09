---
name: refresh-cmdpal-docs
description: >-
  Update this kit's copy of the PowerToys Command Palette docs, SDK source, samples and upstream AI
  skills. Use when the docs may be stale, when an API in the docs or SDK source seems missing, when
  the user mentions a new PowerToys release, or when they ask for the latest docs.
---

# Refresh the Command Palette docs

1. Check what the kit has now: `docs/upstream/SOURCES.md` (PowerToys tag and commits, pinned SDK
   version, newest SDK on NuGet).
2. Sync:
   ```powershell
   .\scripts\sync-docs.ps1                       # newest PowerToys release (the default)
   .\scripts\sync-docs.ps1 -PowerToysRef main    # unreleased work, for features not shipped yet
   ```
   Needs git and PowerShell 7, about 30 seconds. It rewrites `docs/upstream/`, `docs/INDEX.md`, the
   upstream skills in `.claude/skills/` (folders with `UPSTREAM.md`), `.github/instructions/`, and
   `templates/DockExtension/Directory.Packages.props`.
3. Check the template still builds: `.\scripts\test-template.ps1`.
4. Summarize for the user from `git diff --stat` and `SOURCES.md`: what changed upstream, and if
   the pinned SDK version moved, which APIs that unlocks or breaks.

Notes:

- Docs from `main` describe features that the user's installed PowerToys may not have. Say so when
  you use them.
- Do not edit generated files. Hand-written notes go in `docs/guides/`.
- CI runs the same sync every Monday (`.github/workflows/sync-docs.yml`), so a fresh clone is at
  most a week behind.
