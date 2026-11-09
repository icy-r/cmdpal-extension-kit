# cmdpal-extension-kit

Build your own [PowerToys Command Palette](https://learn.microsoft.com/windows/powertoys/command-palette/overview)
extensions and **Dock widgets**, with an AI coding agent that always has the latest docs.

- **Always-current docs.** Every Monday a GitHub Action pulls the newest Command Palette docs from
  Microsoft Learn, the SDK source (IDL and Toolkit), the official sample extension and the official
  AI skills from [microsoft/PowerToys](https://github.com/microsoft/PowerToys). It commits only when
  upstream changed and the template still builds.
- **A tested skeleton.** `scripts/new-extension.ps1` creates a working Dock widget: a live band,
  a hover preview, a click flyout with sections, tags and a details pane, and a right-click menu.
- **AI-ready.** `AGENTS.md` / `CLAUDE.md` tell Claude Code, Cursor, Copilot or Codex where everything
  is. Skills in `.claude/skills/` cover scaffolding, refreshing docs, dock bands, settings, forms,
  fallback commands and publishing.
- **No Visual Studio.** Builds and installs with the .NET 10 SDK alone. No Windows SDK, no admin.

> Community project. Not affiliated with or endorsed by Microsoft.

## Quick start

Needs Windows 11, PowerToys with the Command Palette Dock enabled, the
[.NET 10 SDK](https://dotnet.microsoft.com/download), git and PowerShell 7. Developer Mode
(Settings → System → For developers) makes installing simplest.

```powershell
git clone https://github.com/icy-r/cmdpal-extension-kit
cd cmdpal-extension-kit
.\scripts\new-extension.ps1 -Name WeatherDock -DisplayName "Weather"
cd extensions\WeatherDock
.\pack.ps1          # build and install, restart Command Palette
.\add-to-dock.ps1   # pin the widget to the Dock
```

Then open the repo in your AI agent and ask, for example:

> Make WeatherDock show the temperature for my city from Open-Meteo, with a 3-day forecast in the flyout.

The agent reads `AGENTS.md`, finds the docs through `docs/INDEX.md`, checks APIs against the SDK
source, and follows the `new-dock-extension` skill.

## What's inside

| Path | What |
|---|---|
| `docs/INDEX.md` | One-line map of every doc (generated) |
| `docs/guides/` | Field notes: Dock behavior the official docs leave out, building without Visual Studio |
| `docs/upstream/` | Synced copy of the official docs, SDK source and samples (generated) |
| `templates/DockExtension/` | The project template |
| `scripts/new-extension.ps1` | Scaffold a new extension (fresh COM class GUID, all names filled in) |
| `scripts/sync-docs.ps1` | Pull the latest upstream docs (CI runs it weekly) |
| `scripts/test-template.ps1` | Scaffold, build and run a throwaway extension (CI runs it on every push) |
| `.claude/skills/` | Agent skills (`UPSTREAM.md` marks the synced ones) |
| `extensions/` | Your extensions |

## Keeping your fork current

- The `Sync upstream docs` workflow runs every Monday in forks too, once you enable Actions in
  the fork. Run it by hand from the Actions tab, optionally with `powertoys_ref: main` to get
  docs for features that are not released yet.
- Locally: `.\scripts\sync-docs.ps1`.

## Made with this kit

- [claude-dock](https://github.com/icy-r/claude-dock): live Claude Code session status, one click to the terminal.
- [work-dock](https://github.com/icy-r/work-dock): Jira issues and Bitbucket pull requests.

## License

The kit (scripts, template, guides) is [MIT](LICENSE). Files in `docs/upstream/` keep their
own licenses: Microsoft Learn content is [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/),
PowerToys source is MIT, both © Microsoft Corporation. See `docs/upstream/README.md`.
