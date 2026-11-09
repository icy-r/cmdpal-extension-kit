# __DisplayName__

A PowerToys Command Palette Dock extension, made with
[cmdpal-extension-kit](https://github.com/icy-r/cmdpal-extension-kit).

## Build and install

Needs Windows 11, PowerToys with the Command Palette Dock enabled, and the .NET 10 SDK.

```powershell
.\pack.ps1          # build and install, restart Command Palette
.\add-to-dock.ps1   # pin the band to the Dock
```

With Developer Mode off, run `.\trust-cert.ps1` once first.

## Where to change what

| File | What it does |
|---|---|
| `__Name__/StatusSource.cs` | **Your data.** Polls on a timer and raises `Changed`. |
| `__Name__/StatusBand.cs` | The Dock button: title, hover text (`Subtitle`), icon, right-click menu. |
| `__Name__/StatusPage.cs` | The click flyout: rows, sections, tags, details pane. |
| `__Name__/__Name__CommandsProvider.cs` | Registers the band and the top-level command. |
| `__Name__/Package.appxmanifest` | Package identity and the COM class Command Palette starts. |

Test without Command Palette:

```powershell
dotnet build __Name__\__Name__.csproj -c Debug -p:Platform=x64 -o out\cli
.\out\cli\__Name__.exe --dump | Out-String
```
