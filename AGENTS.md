# Agent guide: cmdpal-extension-kit

This repo helps people (and AI coding agents) build PowerToys **Command Palette** extensions,
especially **Dock** widgets. It holds a weekly-synced copy of the official docs and SDK source, a
tested project template, and scripts to scaffold, build and install.

## Where things are

| Path | What | Edit? |
|---|---|---|
| `docs/INDEX.md` | Map of every doc, one line each. **Start here.** | generated |
| `docs/guides/` | Field notes verified on real installs (Dock behavior, building without Visual Studio) | yes |
| `docs/upstream/learn/` | Microsoft Learn Command Palette docs, incl. the full API reference | generated |
| `docs/upstream/powertoys/sdk/` | SDK IDL and Toolkit C# source: **ground truth for API names and signatures** | generated |
| `docs/upstream/powertoys/samples/` | The official sample extension | generated |
| `docs/upstream/SOURCES.md` | Upstream commits, PowerToys release, pinned and newest SDK version | generated |
| `templates/DockExtension/` | The project template (`__Name__` and other tokens) | yes |
| `extensions/<Name>/` | Extensions scaffolded from the template | yes |
| `.claude/skills/` | Skills; folders with `UPSTREAM.md` are synced from PowerToys | generated / yes |

Generated files are overwritten by `scripts/sync-docs.ps1`. Never edit them by hand.

## How to work

1. **Look things up, don't guess.** The Command Palette SDK changes often. Before you use an API,
   find it in `docs/upstream/powertoys/sdk/` and check that it exists in the SDK version the template
   pins (`docs/upstream/SOURCES.md`). If it is missing, the docs may be stale: run the
   `refresh-cmdpal-docs` skill.
2. **Read the field notes** (`docs/guides/dock-field-notes.md`) before you write Dock code. They list
   behavior the official docs leave out, such as `RaiseItemsChanged()` resetting the selection.
3. **New extension:** use the `new-dock-extension` skill (`scripts/new-extension.ps1`). Do not copy
   an existing extension folder: the COM class GUID and package name must be unique.
4. **Build check:** `scripts/test-template.ps1` after any template change.
5. **Feature how-tos:** the upstream skills (`add-dock-band`, `add-extension-settings`,
   `add-fallback-commands`, `add-adaptive-card-form`, `publish-extension`) were written for the
   upstream template; the same code shapes apply to this template.

## Environment

- Windows 11, PowerToys with the Command Palette Dock enabled, .NET 10 SDK, PowerShell 7.
- `pack.ps1` registers the build folder when Developer Mode is on; otherwise it signs an MSIX with
  a self-signed certificate from `trust-cert.ps1`.
- `pack.ps1` and `add-to-dock.ps1` restart Command Palette and every extension. Warn the user first:
  their Dock goes blank for a few seconds.

## Safety

- No secrets in the repo, in logs, or in chat. Store tokens in Windows Credential Manager and have
  the user type them in their own terminal.
- `add-to-dock.ps1` edits Command Palette's `settings.json` and keeps a backup next to it.
