#!/usr/bin/env pwsh
# Pulls the latest Command Palette docs, SDK source, samples and AI skills from upstream.
#
#   docs/upstream/learn/       <- MicrosoftDocs/windows-dev-docs  hub/powertoys/command-palette (CC BY 4.0)
#   docs/upstream/powertoys/   <- microsoft/PowerToys             src/modules/cmdpal/...         (MIT)
#   .claude/skills/<name>/     <- the extension template's AI skills (marked with UPSTREAM.md)
#   .github/instructions/      <- the extension template's Copilot instructions
#   templates/DockExtension/Directory.Packages.props <- the template's package versions
#   docs/INDEX.md              <- a generated map of every doc, for people and AI agents
#
# Everything listed above is generated. Do not edit it by hand: the next sync overwrites it.
# CI runs this weekly (.github/workflows/sync-docs.yml). Needs git and PowerShell 7.
param(
    # "latest-release" = the newest PowerToys release tag (what users have installed). Or "main", or any tag.
    [string]$PowerToysRef = "latest-release",
    [string]$DocsRef = "docs"
)
$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent
$work = Join-Path ([IO.Path]::GetTempPath()) "cmdpal-kit-sync-$([guid]::NewGuid().ToString('N').Substring(0, 8))"
$headers = @{ "User-Agent" = "cmdpal-extension-kit-sync" }
if ($env:GITHUB_TOKEN) { $headers.Authorization = "Bearer $env:GITHUB_TOKEN" }

function Invoke-Git {
    & git @args
    if ($LASTEXITCODE -ne 0) { throw "git $($args -join ' ') failed ($LASTEXITCODE)" }
}

# Shallow, blob-less, sparse clone: downloads only the folders we need.
function Get-Sparse([string]$Url, [string]$Ref, [string]$Dir, [string[]]$Paths) {
    Invoke-Git -c advice.detachedHead=false clone --quiet --depth 1 --filter=blob:none --sparse --branch $Ref $Url $Dir
    Invoke-Git -C $Dir sparse-checkout set @Paths
    [pscustomobject]@{
        Sha  = (& git -C $Dir rev-parse HEAD).Trim()
        Date = (& git -C $Dir log -1 --format=%cs).Trim()
    }
}

# Copies files matching $Include from $From to $To, keeping the folder tree. Skips build output.
function Copy-Tree([string]$From, [string]$To, [string[]]$Include = @("*")) {
    if (-not (Test-Path $From)) { throw "Upstream path missing: $From (did the upstream layout change?)" }
    Get-ChildItem $From -Recurse -File -Include $Include |
        Where-Object { $_.FullName -notmatch '[\\/](bin|obj|node_modules)[\\/]' } |
        ForEach-Object {
            $rel = [IO.Path]::GetRelativePath($From, $_.FullName)
            $dest = Join-Path $To $rel
            New-Item -ItemType Directory -Force (Split-Path $dest) | Out-Null
            Copy-Item $_.FullName $dest -Force
        }
}

function Reset-Dir([string]$Dir) {
    if (Test-Path $Dir) { Remove-Item $Dir -Recurse -Force }
    New-Item -ItemType Directory -Force $Dir | Out-Null
}

try {
    # ---- resolve refs
    $release = Invoke-RestMethod "https://api.github.com/repos/microsoft/PowerToys/releases/latest" -Headers $headers
    if ($PowerToysRef -eq "latest-release") { $PowerToysRef = $release.tag_name }
    $nugetVersions = (Invoke-RestMethod "https://api.nuget.org/v3-flatcontainer/microsoft.commandpalette.extensions/index.json").versions
    $nugetLatest = $nugetVersions | Where-Object { $_ -notmatch '-' } | Select-Object -Last 1
    Write-Host "PowerToys $PowerToysRef (latest release $($release.tag_name)); Learn docs '$DocsRef'; SDK NuGet $nugetLatest"

    # ---- fetch
    $cmdpal = "src/modules/cmdpal"
    $pt = Get-Sparse "https://github.com/microsoft/PowerToys.git" $PowerToysRef (Join-Path $work "pt") @(
        "$cmdpal/doc", "$cmdpal/extensionsdk", "$cmdpal/ExtensionTemplate", "$cmdpal/ext/SamplePagesExtension")
    $learn = Get-Sparse "https://github.com/MicrosoftDocs/windows-dev-docs.git" $DocsRef (Join-Path $work "learn") @(
        "hub/powertoys/command-palette")
    $ptc = Join-Path $work "pt/$cmdpal"
    $tpl = Join-Path $ptc "ExtensionTemplate/TemplateCmdPalExtension"

    # ---- docs/upstream
    $up = Join-Path $root "docs/upstream"
    Reset-Dir $up
    Copy-Tree (Join-Path $work "learn/hub/powertoys/command-palette") (Join-Path $up "learn") @("*.md", "*.yml")
    $ptOut = Join-Path $up "powertoys"
    New-Item -ItemType Directory -Force $ptOut | Out-Null
    Copy-Item (Join-Path $ptc "README.md") (Join-Path $ptOut "README.md")
    Copy-Tree (Join-Path $ptc "doc") (Join-Path $ptOut "design-docs") @("*.md")
    Copy-Tree (Join-Path $ptc "extensionsdk") (Join-Path $ptOut "sdk") @("*.idl", "*.cs", "README.md")
    Copy-Tree (Join-Path $ptc "ext/SamplePagesExtension") (Join-Path $ptOut "samples/SamplePagesExtension") @("*.cs", "*.md")
    Copy-Tree $tpl (Join-Path $ptOut "extension-template") @("*.cs", "*.csproj", "*.props", "*.appxmanifest", "*.manifest", "*.md", "*.json", "*.config", "*.pubxml")

    # ---- AI skills and instructions from the extension template
    $skillsDir = Join-Path $root ".claude/skills"
    New-Item -ItemType Directory -Force $skillsDir | Out-Null
    Get-ChildItem $skillsDir -Directory | Where-Object { Test-Path (Join-Path $_.FullName "UPSTREAM.md") } | Remove-Item -Recurse -Force
    foreach ($skill in Get-ChildItem (Join-Path $tpl ".github/skills") -Directory) {
        $dest = Join-Path $skillsDir $skill.Name
        if ((Test-Path $dest) -and -not (Test-Path (Join-Path $dest "UPSTREAM.md"))) {
            Write-Warning "Skipping upstream skill '$($skill.Name)': a hand-written skill with that name exists."
            continue
        }
        Copy-Tree $skill.FullName $dest
        Set-Content (Join-Path $dest "UPSTREAM.md") @"
Synced from microsoft/PowerToys ``$cmdpal/ExtensionTemplate/TemplateCmdPalExtension/.github/skills/$($skill.Name)``
at $PowerToysRef ($($pt.Sha)). Do not edit: scripts/sync-docs.ps1 overwrites this folder.
The skill was written for the upstream template project (TemplateCmdPalExtension); in this kit the
same code lives in templates/DockExtension and in extensions/<Name> after scaffolding.
"@
    }
    $instr = Join-Path $root ".github/instructions"
    New-Item -ItemType Directory -Force $instr | Out-Null
    Copy-Tree (Join-Path $tpl ".github/instructions") $instr @("*.md")

    # ---- template package versions (tested together upstream)
    New-Item -ItemType Directory -Force (Join-Path $root "templates/DockExtension") | Out-Null
    Copy-Item (Join-Path $tpl "Directory.Packages.props") (Join-Path $root "templates/DockExtension/Directory.Packages.props") -Force
    $pinned = ([xml](Get-Content (Join-Path $tpl "Directory.Packages.props") -Raw)).Project.ItemGroup.PackageVersion |
        Where-Object Include -eq "Microsoft.CommandPalette.Extensions" | Select-Object -ExpandProperty Version

    # ---- sources and attribution
    Set-Content (Join-Path $up "README.md") @"
# Upstream docs (generated)

Do not edit files in this folder. ``scripts/sync-docs.ps1`` replaces it on every sync.
Write your own notes in ``docs/guides/`` instead.

| Folder | Source | License |
|---|---|---|
| ``learn/`` | [MicrosoftDocs/windows-dev-docs](https://github.com/MicrosoftDocs/windows-dev-docs/tree/$DocsRef/hub/powertoys/command-palette), published at <https://learn.microsoft.com/windows/powertoys/command-palette/overview> | [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/), © Microsoft Corporation |
| ``powertoys/`` | [microsoft/PowerToys](https://github.com/microsoft/PowerToys/tree/$PowerToysRef/$cmdpal) | [MIT](https://github.com/microsoft/PowerToys/blob/main/LICENSE), © Microsoft Corporation |

The files are copied unchanged, except that only text formats are kept (no images, no build output).
See ``SOURCES.md`` for the exact commits.
"@
    Set-Content (Join-Path $up "SOURCES.md") @"
# Sources of this sync

| Source | Ref | Commit | Commit date |
|---|---|---|---|
| microsoft/PowerToys | ``$PowerToysRef`` | [``$($pt.Sha.Substring(0, 10))``](https://github.com/microsoft/PowerToys/commit/$($pt.Sha)) | $($pt.Date) |
| MicrosoftDocs/windows-dev-docs | ``$DocsRef`` | [``$($learn.Sha.Substring(0, 10))``](https://github.com/MicrosoftDocs/windows-dev-docs/commit/$($learn.Sha)) | $($learn.Date) |

- Latest PowerToys release: [``$($release.tag_name)``]($($release.html_url)), published $($release.published_at.ToString("yyyy-MM-dd")).
- SDK package ``Microsoft.CommandPalette.Extensions``: template pins ``$pinned``; newest stable on NuGet is ``$nugetLatest``.
"@

    # ---- INDEX.md: one line per doc, from its front-matter title/description or first heading
    $lines = [System.Collections.Generic.List[string]]::new()
    $lines.Add("# Docs index (generated)")
    $lines.Add("")
    $lines.Add("Generated by ``scripts/sync-docs.ps1``. Start here, then open the file you need.")
    $lines.Add("Ground truth for API names and signatures: ``upstream/powertoys/sdk/`` (the IDL and the Toolkit source).")
    foreach ($section in @(
            @{ Title = "Field notes (hand-written, verified on real installs)"; Dir = "guides" },
            @{ Title = "Microsoft Learn: Command Palette"; Dir = "upstream/learn" },
            @{ Title = "PowerToys design docs and specs"; Dir = "upstream/powertoys" })) {
        $dir = Join-Path $root "docs/$($section.Dir)"
        if (-not (Test-Path $dir)) { continue }
        $lines.Add(""); $lines.Add("## $($section.Title)"); $lines.Add("")
        foreach ($f in Get-ChildItem $dir -Recurse -File -Filter *.md | Sort-Object FullName) {
            $rel = [IO.Path]::GetRelativePath((Join-Path $root "docs"), $f.FullName).Replace('\', '/')
            if ($rel -match '/(samples|sdk|extension-template)/' -or $f.Name -in "SOURCES.md") { continue }
            # API reference folders: list only their landing page, with a page count.
            $apiDir = if ($rel -match '/learn/(microsoft-commandpalette-[^/]+)/') { $Matches[1] } else { $null }
            if ($apiDir -and $f.BaseName -ne $apiDir) { continue }
            $text = Get-Content $f.FullName -Raw
            $title = if ($text -match '(?m)^title:\s*(.+)$') { $Matches[1].Trim().Trim('"') } elseif ($text -match '(?m)^#\s+(.+)$') { $Matches[1].Trim() } else { $f.BaseName }
            $title = ($title -replace '!\[[^\]]*\]\([^)]*\)', '').Trim()
            if ($apiDir) { $title = "API reference: $title ($((Get-ChildItem $f.DirectoryName -File).Count) pages)" }
            $desc = if ($text -match '(?m)^description:\s*(.+)$') { " — " + $Matches[1].Trim().Trim('"') } else { "" }
            $lines.Add("- [$title]($rel)$desc")
        }
    }
    $lines.Add(""); $lines.Add("## Source code references"); $lines.Add("")
    foreach ($ref in @(
            @{ Path = "upstream/powertoys/sdk"; What = "SDK: ``Microsoft.CommandPalette.Extensions.idl`` (interfaces) and the Toolkit C# source (base classes, helpers)" },
            @{ Path = "upstream/powertoys/samples/SamplePagesExtension"; What = "Official sample extension: every page type, forms, markdown, dock bands" },
            @{ Path = "upstream/powertoys/extension-template"; What = "The official 'new extension' template, unchanged" })) {
        $count = (Get-ChildItem (Join-Path $root "docs/$($ref.Path)") -Recurse -File -ErrorAction SilentlyContinue | Measure-Object).Count
        $lines.Add("- [``$($ref.Path)/``]($($ref.Path)) ($count files): $($ref.What)")
    }
    [IO.File]::WriteAllText((Join-Path $root "docs/INDEX.md"), ($lines -join "`n") + "`n")

    Write-Host "Synced: PowerToys $PowerToysRef $($pt.Sha.Substring(0, 10)), Learn $($learn.Sha.Substring(0, 10))."
}
finally {
    if (Test-Path $work) { Remove-Item $work -Recurse -Force -ErrorAction SilentlyContinue }
}
