# Pins the __DisplayName__ band to the Command Palette Dock and restarts Command Palette.
# Band: __Id__.band
#
# The band goes at the start of -Section, in the global band lists and in every monitor that has its
# own (customized) band lists. A band that is already on a Dock stays where you put it.
# Backs up settings.json first.
param(
    [ValidateSet("StartBands", "CenterBands", "EndBands")][string]$Section = "EndBands",
    [string[]]$BandIds = @("__Id__.band")
)
$ErrorActionPreference = "Stop"

$pkg = Get-AppxPackage -Name __Name__
if (-not $pkg) { throw "__Name__ package is not installed. Run pack.ps1 first." }
$providerId = "$($pkg.PackageFamilyName)!App!__Name__"
$settingsPath = Join-Path $env:LOCALAPPDATA "Packages\Microsoft.CommandPalette_8wekyb3d8bbwe\LocalState\settings.json"

# Stop Command Palette so it does not overwrite our change on exit. Stop its extensions too,
# else they keep a dead link to the old instance and their bands stop updating.
. (Join-Path $PSScriptRoot "cmdpal.ps1")
[void](Stop-CommandPalette)

$backup = "$settingsPath.__namelower__-backup-$(Get-Date -Format yyyyMMdd-HHmmss)"
Copy-Item $settingsPath $backup
# JsonNode keeps every other value exactly as Command Palette wrote it.
$root = [System.Text.Json.Nodes.JsonNode]::Parse([IO.File]::ReadAllText($settingsPath))
$dock = $root["DockSettings"]
if ($null -eq $dock) { throw "No DockSettings in settings.json - enable the Dock in Command Palette settings first." }

# Each Dock layout: the global one, plus each monitor with its own band lists.
$layouts = @(@{ Name = "global"; Node = $dock })
if ($dock["MonitorConfigs"]) {
    foreach ($m in $dock["MonitorConfigs"].AsArray()) {
        if ($m["IsCustomized"] -and $m["IsCustomized"].GetValue[bool]()) {
            $layouts += @{ Name = "monitor $($m['FallbackDisplayNumber'])"; Node = $m }
        }
    }
}

function Test-Band($layout, [string]$id) {
    foreach ($name in "StartBands", "CenterBands", "EndBands") {
        $list = $layout[$name]
        if ($null -eq $list) { continue }
        foreach ($b in $list.AsArray()) {
            if ($b["ProviderId"].GetValue[string]() -eq $providerId -and $b["CommandId"].GetValue[string]() -eq $id) { return $true }
        }
    }
    return $false
}

foreach ($layout in $layouts) {
    foreach ($bandId in $BandIds) {
        if (Test-Band $layout.Node $bandId) {
            Write-Host "$bandId is already on the $($layout.Name) Dock."
            continue
        }

        # ShowSubtitles=false: the subtitle holds the hover text, so keep it off the bar.
        $band = [System.Text.Json.Nodes.JsonNode]::Parse((@{ ProviderId = $providerId; CommandId = $bandId; ShowTitles = $null; ShowSubtitles = $false } | ConvertTo-Json -Compress))
        if ($null -eq $layout.Node[$Section]) { $layout.Node[$Section] = [System.Text.Json.Nodes.JsonArray]::new() }
        $layout.Node[$Section].AsArray().Insert(0, $band)
        Write-Host "Added $bandId to the $($layout.Name) Dock ($Section)."
    }
}

$opts = [System.Text.Json.JsonSerializerOptions]::new(); $opts.WriteIndented = $true
$opts.Encoder = [System.Text.Encodings.Web.JavaScriptEncoder]::UnsafeRelaxedJsonEscaping
[IO.File]::WriteAllText($settingsPath, $root.ToJsonString($opts))
Write-Host "Backup: $backup"

Start-CommandPalette
Write-Host "Command Palette restarted."
