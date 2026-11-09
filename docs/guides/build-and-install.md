# Build and install without Visual Studio

The official path is Visual Studio with the Windows App SDK workload. The template in this kit
builds with only the **.NET 10 SDK**: no Visual Studio, no Windows SDK install, no admin rights.
Checked on Windows 11 24H2, November 2026.

## How the template does it

| Problem | Fix in the template |
|---|---|
| CsWinRT fails with "Could not find the Windows SDK" | `<CsWinRTWindowsMetadata>local</CsWinRTWindowsMetadata>` in the `.csproj` |
| MSIX tooling needs Visual Studio targets (`APPX3217`, missing `UAP.props`) | `<EnableMsixTooling>false</EnableMsixTooling>`; `pack.ps1` writes `AppxManifest.xml` itself |
| No `makeappx` / `signtool` | `pack.ps1` downloads the `Microsoft.Windows.SDK.BuildTools` NuGet package into `tools\` |
| An unsigned MSIX cannot be installed (`0x80073D2B`) | Developer Mode: register the folder, no MSIX at all. Otherwise sign with a self-signed cert |

## Two install modes

1. **Developer Mode on** (Settings → System → For developers). `pack.ps1` runs
   `Add-AppxPackage -Register out\layout\AppxManifest.xml`. Nothing is signed. Fastest loop.
2. **Developer Mode off.** Run `trust-cert.ps1` once. It makes a self-signed code-signing
   certificate whose subject matches the manifest `Publisher`, and trusts it for the current user.
   `pack.ps1` then packs, signs and installs an `.msix`.
   - `0x800B0109` (untrusted root): `TrustedPeople` was not enough on some machines. Use
     Developer Mode, or trust the certificate in `CurrentUser\Root` (`trust-cert.ps1 -Store Root`).
   - On a managed (work) PC, check your IT policy before you trust your own certificates.

## Inner loop

```powershell
.\pack.ps1          # build, stop Command Palette and all extensions, register, start Command Palette
.\add-to-dock.ps1   # once: pin the band (global and per-monitor lists)
```

`pack.ps1` must stop Command Palette first: it starts your extension, which locks the files in
`out\layout`. Command Palette may restart the extension at once, so `pack.ps1` retries the delete.

## Debugging without Command Palette

The template's `Program.cs` has a `--dump` mode that prints what the band would show. Build to a
separate folder so the installed copy is not locked:

```powershell
dotnet build <Name>\<Name>.csproj -c Debug -p:Platform=x64 -o out\cli
.\out\cli\<Name>.exe --dump | Out-String
```

The exe is a `WinExe`, so PowerShell does not wait for its output. Pipe it to `Out-String`.

Log files: write your own (for example to `%USERPROFILE%\.<name>\log.txt`). Command Palette does not
show extension output.
