# Dock field notes

Behavior of the Command Palette Dock that the official docs do not spell out. Each point was checked
on a real install: **PowerToys v0.103 (Command Palette 0.13.13061), SDK
`Microsoft.CommandPalette.Extensions` 0.11.260520004, November 2026.** Newer versions may differ, so
re-check a point before you build on it, and update this file when it changes.

Sources: the [Claude Dock](https://github.com/icy-r/claude-dock) and
[Work Dock](https://github.com/icy-r/work-dock) extensions, built with this kit.

## Bands and items

- A band is an `ICommandItem` returned from `CommandProvider.GetDockBands()`. For a strip of
  buttons, subclass `WrappedDockItem` and set its `Items` (a list of `ListItem`).
- Every item needs a command with a non-empty `Id`, and the provider needs an `Id`. Items without one
  are ignored.
- **Update items in place.** Change `Title`, `Subtitle` and `Icon` on the existing `ListItem`
  objects; the Dock picks up the property change. Assign `Items` again only when items come or go.
  Replacing `Items` rebuilds every button, which flickers and closes an open tooltip.
- Raise changes from any thread: the toolkit marshals property-change events. Keep the work done on
  each update small, because it can run often.
- **`RaiseItemsChanged()` resets the selection.** On a `ListPage` (also in a Dock flyout), every
  call reloads the list and selects the first row. A page that calls it on every poll makes the
  user's selection jump back within seconds. Keep the `ListItem` objects, update their properties
  in place, and call `RaiseItemsChanged()` only when rows are added, removed or reordered. Assigning
  a new `Details` object re-renders the details pane, so assign it only when its content changed.

## Hover preview (tooltip)

- The tooltip of a Dock item is `Title + "\n" + Subtitle`. A multi-line `Subtitle` is therefore a
  hover preview. This is the only rich-ish hover the Dock has: **plain text only**, no Markdown,
  no colors. Emoji work.
- In the **Compact** Dock size the subtitle line is not drawn on the bar, but it still shows in
  the tooltip. In bigger sizes, set `ShowSubtitles: false` on the band (see *Settings file* below) so
  the preview text does not appear on the bar itself. `add-to-dock.ps1` does that.

## Click, flyout and context menu

- Item command is a `ListPage` → clicking opens a flyout (about 500 px wide). Set
  `ShowDetails = true` and give each `ListItem` a `Details` to get a details pane on the right
  (`Details.Size = ContentSize.Large`, about 480 px). Sections (`ListItem.Section`) and colored
  `Tags` (`ColorHelpers.FromRgb` backgrounds) render in the flyout.
- Item command is an `InvokableCommand` → clicking runs it. Return `CommandResult.Dismiss()`, or
  `CommandResult.ShowToast(message)` to show an error.
- **Right-click** shows the item's `MoreCommands` as a context menu. Use it for secondary actions
  (rename, copy, open folder).
- There is **no double-click event**. Two quick clicks do not reliably arrive as two invokes.
- `SetForegroundWindow` works from `Invoke()`: Command Palette calls `CoAllowSetForegroundWindow`
  on the extension process, so an extension can bring another app's window to the front.

## Icons

- `IconHelpers.FromRelativePath("Assets\\name.svg")` loads SVG files from the package. Colored SVG
  dots are an easy status indicator, and they stay sharp at every Dock size.
- `new IconInfo("")` uses a Segoe Fluent Icons glyph, drawn in the theme's text color.

## API availability

- Command Palette 0.13 has an `IDetails2` (rich details content), but no published SDK package
  contains it yet (newest stable at the time of writing: 0.12.260812002). Do not depend on APIs that
  are only in the PowerToys `main` branch; check `docs/upstream/powertoys/sdk/` and the version the
  template pins (`docs/upstream/SOURCES.md`).

## Settings file

Dock layout lives in
`%LOCALAPPDATA%\Packages\Microsoft.CommandPalette_8wekyb3d8bbwe\LocalState\settings.json`:

```jsonc
"DockSettings": {
  "StartBands":  [ { "ProviderId": "<PackageFamilyName>!App!<AppExtension Id>", "CommandId": "<band id>",
                     "ShowTitles": null, "ShowSubtitles": false } ],
  "CenterBands": [ ... ],
  "EndBands":    [ ... ],
  "MonitorConfigs": [ { "IsCustomized": true, "StartBands": [ ... ], ... } ]  // per-monitor overrides
}
```

- `ProviderId` is the package family name, `!App!`, and the `Id` of the `uap3:AppExtension` in
  `Package.appxmanifest`.
- A monitor with `IsCustomized: true` uses its own band lists, not the global ones. A script that
  adds or moves a band must handle both.
- Edit the file only while Command Palette is stopped; it rewrites the file on exit.

## Restarting Command Palette

Stopping only `Microsoft.CmdPal.UI` leaves every extension process running. The next Command
Palette reuses those processes, but their links to the old instance are dead, so their bands stop
updating (seen with a third-party media widget). Always stop the extension processes too.
`cmdpal.ps1` in the template does this: it finds every package that declares a
`com.microsoft.commandpalette` app extension and stops its processes, including helper processes and
sparse packages (PowerToys) whose exe runs outside the package folder.
