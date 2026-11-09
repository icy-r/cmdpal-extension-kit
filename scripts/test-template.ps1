#!/usr/bin/env pwsh
# Scaffolds a throwaway extension from templates/DockExtension, builds it, and runs its --dump mode.
# Proves the template still compiles against the package versions the last sync pinned.
# Used by CI (.github/workflows/*.yml); also fine to run locally. Does not install anything.
$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent
$out = Join-Path ([IO.Path]::GetTempPath()) "cmdpal-kit-test-$([guid]::NewGuid().ToString('N').Substring(0, 8))"

$dotnet = (Get-Command dotnet -ErrorAction SilentlyContinue).Source
$userDotnet = Join-Path $env:LOCALAPPDATA "Microsoft\dotnet-user\dotnet.exe"
if (Test-Path $userDotnet) { $dotnet = $userDotnet; $env:DOTNET_ROOT = Split-Path $userDotnet }
if (-not $dotnet) { throw ".NET SDK not found. Install the .NET 10 SDK." }

try {
    & (Join-Path $PSScriptRoot "new-extension.ps1") -Name KitSelfTest -OutDir $out | Out-Null
    & $dotnet build (Join-Path $out "KitSelfTest/KitSelfTest.csproj") -c Debug -p:Platform=x64 -o (Join-Path $out "out/cli") -v:q -nologo
    if ($LASTEXITCODE -ne 0) { throw "Template build failed." }

    $dump = & (Join-Path $out "out/cli/KitSelfTest.exe") --dump | Out-String
    if ($dump -notmatch "Tooltip:") { throw "--dump printed nothing useful:`n$dump" }
    Write-Host "Template OK. --dump output:`n$dump"
}
finally {
    Remove-Item $out -Recurse -Force -ErrorAction SilentlyContinue
}
