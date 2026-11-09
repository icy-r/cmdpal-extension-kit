#!/usr/bin/env pwsh
# Creates a new Command Palette Dock extension from templates/DockExtension.
#
#   .\scripts\new-extension.ps1 -Name WeatherDock
#   .\scripts\new-extension.ps1 -Name WeatherDock -DisplayName "Weather" -OutDir C:\src\WeatherDock
#
# Then:  cd extensions\WeatherDock; .\pack.ps1; .\add-to-dock.ps1
param(
    # PascalCase. Used for the namespace, project, exe, package identity and AppExtension Id.
    [Parameter(Mandatory)][ValidatePattern('^[A-Z][A-Za-z0-9]{2,39}$')][string]$Name,
    [string]$DisplayName,
    [string]$Description,
    [string]$OutDir
)
$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent
$template = Join-Path $root "templates/DockExtension"
if (-not $DisplayName) { $DisplayName = ($Name -creplace '(?<=[a-z0-9])(?=[A-Z])', ' ') }
if (-not $Description) { $Description = "$DisplayName for the Command Palette Dock" }
if (-not $OutDir) { $OutDir = Join-Path $root "extensions/$Name" }
if (Test-Path $OutDir) { throw "$OutDir already exists. Pick another -Name or -OutDir." }

$tokens = [ordered]@{
    "__Guid__"        = [guid]::NewGuid().ToString().ToUpperInvariant()   # COM class id: unique per extension
    "__DisplayName__" = $DisplayName
    "__Description__" = $Description
    "__Id__"          = "com." + $Name.ToLowerInvariant()                 # provider id; band id is <id>.band
    "__Name__"        = $Name
    "__namelower__"   = $Name.ToLowerInvariant()                          # data folder %USERPROFILE%\.<name>
}
$textTypes = @(".cs", ".csproj", ".props", ".ps1", ".md", ".appxmanifest", ".manifest", ".json", ".config", ".pubxml", ".svg", ".gitignore", "")

foreach ($file in Get-ChildItem $template -Recurse -File -Force) {
    $rel = [IO.Path]::GetRelativePath($template, $file.FullName)
    foreach ($k in $tokens.Keys) { $rel = $rel.Replace($k, $tokens[$k]) }
    $dest = Join-Path $OutDir $rel
    New-Item -ItemType Directory -Force (Split-Path $dest) | Out-Null
    if ($textTypes -contains $file.Extension.ToLowerInvariant()) {
        $text = [IO.File]::ReadAllText($file.FullName)
        foreach ($k in $tokens.Keys) { $text = $text.Replace($k, $tokens[$k]) }
        [IO.File]::WriteAllText($dest, $text)
    }
    else {
        Copy-Item $file.FullName $dest
    }
}

$left = Get-ChildItem $OutDir -Recurse -File | Select-String -Pattern '__[A-Za-z]+__' -List
if ($left) { throw "Unreplaced tokens in: $($left.Path -join ', ')" }

Write-Host "Created $OutDir"
Write-Host "  Name: $Name   Display name: $DisplayName   Provider id: $($tokens['__Id__'])   COM class: $($tokens['__Guid__'])"
Write-Host "Next:"
Write-Host "  cd `"$OutDir`""
Write-Host "  .\pack.ps1          # build and install (Developer Mode on; else run .\trust-cert.ps1 first)"
Write-Host "  .\add-to-dock.ps1   # pin the band"
