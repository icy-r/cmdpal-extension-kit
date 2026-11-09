---
name: new-dock-extension
description: >-
  Create a new PowerToys Command Palette extension with a Dock widget (band) from this kit's
  template, then build, install and pin it. Use when asked to make a new Command Palette extension,
  Dock widget, toolbar widget, status widget, or "something on the Dock that shows X".
---

# New Dock extension

## Steps

1. **Name it.** PascalCase, 3–40 letters or digits, for example `WeatherDock`. It becomes the
   namespace, project, exe, package identity and provider id (`com.weatherdock`).
2. **Scaffold** from the repo root:
   ```powershell
   .\scripts\new-extension.ps1 -Name WeatherDock -DisplayName "Weather"
   ```
   This creates `extensions/WeatherDock/` with a fresh COM class GUID. Never copy an existing
   extension by hand: two extensions with the same GUID or package name break each other.
3. **Read before you code.** Open `docs/INDEX.md`, then `docs/guides/dock-field-notes.md`. Check
   every API you use against `docs/upstream/powertoys/sdk/` (IDL and Toolkit source): the template
   pins the SDK version in `docs/upstream/SOURCES.md`, and APIs newer than that do not exist yet.
4. **Put the user's data in `StatusSource.cs`.** Keep the shape: a timer, a `Current` snapshot
   record, a `Changed` event. Do slow I/O there, never in property getters or `GetItems()`.
5. **Shape the UI** in `StatusBand.cs` (Dock button, hover text in `Subtitle`, icon, right-click
   `MoreCommands`) and `StatusPage.cs` (flyout rows, sections, tags, details pane).
6. **Test without Command Palette** (from the extension folder):
   ```powershell
   dotnet build <Name>\<Name>.csproj -c Debug -p:Platform=x64 -o out\cli
   .\out\cli\<Name>.exe --dump | Out-String
   ```
   Extend `--dump` in `Program.cs` to print anything new you show.
7. **Install and pin:** `.\pack.ps1`, then `.\add-to-dock.ps1` once. `pack.ps1` restarts Command
   Palette and every extension; tell the user before you run it, because their Dock blinks.

## Rules that cost hours when broken

- Update `ListItem` properties in place. Assign `WrappedDockItem.Items` or call
  `RaiseItemsChanged()` only when rows are added, removed or reordered: both rebuild the UI, and
  `RaiseItemsChanged()` resets the user's selection to the first row.
- Every Dock item needs a command with a non-empty `Id`.
- Hover text is plain text (`Title + "\n" + Subtitle`). Put rich content in the flyout's details pane.
- There is no double-click. Use the right-click menu (`MoreCommands`) for secondary actions.
- Never store secrets in the repo or in plain files. Use Windows Credential Manager, and have the
  user type secrets in their own terminal, not in the chat.
