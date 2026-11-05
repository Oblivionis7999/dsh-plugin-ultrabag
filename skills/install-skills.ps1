#Requires -Version 5.1
<#
.SYNOPSIS
    Install DSH skills from their own upstream repositories.

.DESCRIPTION
    The skills are deliberately NOT vendored into this repository. Together they
    are 43.80 MiB across 13472 files, and ppt-master alone accounts for 38.2 MiB
    of that. Shipping a copy would bloat every clone for content that is already
    published upstream under MIT.

    So this script fetches each skill from its own upstream and installs it into
    <DshHome>\skills\<name>. Nothing is ever deleted: an existing skill is only
    replaced when -Force is given, and even then it is first renamed to
    <name>.bak-<timestamp>.

    Default behaviour installs only skills with a verified upstream
    (status "known-good" in skills.manifest.json). Skills marked "unverified"
    need -SkipUnverified:$false. Skills marked "skip" are never installed; the
    script prints the reason.

.PARAMETER DshHome
    The DSH home directory. Skills are installed to <DshHome>\skills\<name>.
    Defaults to the DSH_HOME environment variable. Required when that is unset.

.PARAMETER Only
    Install only the named skills. Comma separated and repeatable:
      -Only tdd,code-review,wizard
    An unknown name aborts before anything is touched.

.PARAMETER DryRun
    Print the plan and exit. No network access, nothing written to disk.

.PARAMETER Force
    Replace skills that already exist. The existing directory is renamed to
    <name>.bak-<timestamp> first. Without -Force an existing skill is left
    exactly as it is.

.PARAMETER SkipUnverified
    Skip skills whose upstream is unverified or unknown. Defaults to true.
    Pass -SkipUnverified:$false to attempt the unverified ones as well. Note
    that the "-Switch:$false" form only parses when the script is invoked from
    inside PowerShell; when it is launched with "powershell.exe -File", use
    -IncludeUnverified instead.

.PARAMETER IncludeUnverified
    Convenience switch: same effect as -SkipUnverified:$false, but it works in
    every invocation mode.

.PARAMETER Manifest
    Path to skills.manifest.json. Defaults to the copy beside this script.

.PARAMETER CacheDir
    Where upstream checkouts are cached and reused. Defaults to a folder under
    the system temp directory.

.EXAMPLE
    .\install-skills.ps1 -DryRun
    Uses the DSH_HOME environment variable and touches nothing.

.EXAMPLE
    .\install-skills.ps1 -Only tdd,code-review,pr -DshHome "$HOME\dsh"

.EXAMPLE
    .\install-skills.ps1 -Force -IncludeUnverified -DshHome "$HOME\dsh"

.NOTES
    Exit codes: 0 = everything installed and validated, 1 = at least one skill
    failed, 2 = usage error.
#>
[CmdletBinding()]
param(
    [string]$DshHome,
    [string[]]$Only,
    [switch]$DryRun,
    [switch]$Force,
    [switch]$SkipUnverified = $true,
    [switch]$IncludeUnverified,
    [string]$Manifest,
    [string]$CacheDir
)

if ($IncludeUnverified) { $SkipUnverified = $false }

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

# --------------------------------------------------------------------------
# Output helpers
# --------------------------------------------------------------------------

function Write-Info { param([string]$Message) Write-Host $Message }
function Write-Ok   { param([string]$Message) Write-Host $Message -ForegroundColor Green }
function Write-Warn { param([string]$Message) Write-Host "WARN  $Message" -ForegroundColor Yellow }
function Write-Err  { param([string]$Message) Write-Host "ERROR $Message" -ForegroundColor Red }
function Write-Head {
    param([string]$Message)
    Write-Host ''
    Write-Host "== $Message ==" -ForegroundColor Cyan
}

# --------------------------------------------------------------------------
# Small utilities
# --------------------------------------------------------------------------

function Format-Size {
    param([long]$Bytes)
    if ($Bytes -ge 1MB) { return ('{0:N1} MB' -f ($Bytes / 1MB)) }
    if ($Bytes -ge 1KB) { return ('{0:N1} KB' -f ($Bytes / 1KB)) }
    return ('{0} B' -f $Bytes)
}

function Get-TreeSize {
    param([string]$Path)
    $total = 0L
    Get-ChildItem -LiteralPath $Path -Recurse -File -Force -ErrorAction SilentlyContinue |
        ForEach-Object { $total += $_.Length }
    return $total
}

function Get-FrontmatterName {
    param([string]$SkillMdPath)
    $lines = @(Get-Content -LiteralPath $SkillMdPath -Encoding UTF8 -TotalCount 40 -ErrorAction SilentlyContinue)
    foreach ($line in $lines) {
        if ($line -match '^name:\s*(.+?)\s*$') {
            $value = $matches[1].Trim()
            $value = $value.Trim('"').Trim("'")
            return $value
        }
    }
    return $null
}

# --------------------------------------------------------------------------
# Frontmatter validation
# --------------------------------------------------------------------------

function Get-YamlKeyEntry {
    param([string[]]$Lines, [string]$Key)
    $pattern = '^\s*' + [regex]::Escape($Key) + '\s*:\s*(.*)$'
    for ($i = 0; $i -lt $Lines.Count; $i++) {
        if ($Lines[$i] -match $pattern) {
            return [pscustomobject]@{ Index = $i; Raw = $matches[1] }
        }
    }
    return $null
}

function Test-YamlScalar {
    param(
        $Entry,
        [string]$Key,
        [string[]]$Lines,
        [System.Collections.Generic.List[string]]$Problems
    )
    if ($null -eq $Entry) {
        $Problems.Add(($Key + ' is missing from the frontmatter'))
        return $false
    }
    $raw = $Entry.Raw.Trim()
    if ($raw -eq '') {
        $Problems.Add(($Key + ' is empty'))
        return $false
    }
    # Block scalar (| or >) is valid; its content lives on the following indented lines.
    if ($raw -in @('|', '>', '|-', '>-', '|+', '>+')) {
        if (($Entry.Index + 1) -lt $Lines.Count -and $Lines[$Entry.Index + 1] -match '^\s+\S') {
            return $true
        }
        $Problems.Add(($Key + ' declares a block scalar but has no indented body'))
        return $false
    }
    $looksQuoted = $raw.StartsWith('"') -or $raw.StartsWith("'") -or $raw.StartsWith('[') -or $raw.StartsWith('{')
    if (-not $looksQuoted) {
        if ($raw -match ': ') {
            $Problems.Add(('YAML PITFALL: ' + $Key + ' contains an unquoted ": " -- YAML will keep only the text before it. ' +
                'Wrap the whole value in double quotes, e.g.  ' + $Key + ': "Some words: more words"'))
        }
        if ($raw -match '\s#') {
            $Problems.Add(('YAML PITFALL: ' + $Key + ' contains an unquoted " #" -- everything after it is read as a comment. ' +
                'Wrap the whole value in double quotes.'))
        }
    }
    return $true
}

function Test-SkillDirectory {
    param([string]$SkillDir)

    $result = [pscustomobject]@{
        Directory      = $SkillDir
        HasSkillMd     = $false
        FrontmatterOk  = $false
        HasName        = $false
        HasDescription = $false
        Hidden         = $false
        Problems       = New-Object System.Collections.Generic.List[string]
    }

    $md = Join-Path $SkillDir 'SKILL.md'
    if (-not (Test-Path -LiteralPath $md -PathType Leaf)) {
        $result.Problems.Add('SKILL.md is missing')
        return $result
    }
    $result.HasSkillMd = $true

    $lines = @(Get-Content -LiteralPath $md -Encoding UTF8 -ErrorAction Stop)
    if ($lines.Count -eq 0) {
        $result.Problems.Add('SKILL.md is empty')
        return $result
    }
    if ($lines[0].Trim() -ne '---') {
        $result.Problems.Add('frontmatter is missing (the first line is not ---)')
        return $result
    }

    $end = -1
    for ($i = 1; $i -lt $lines.Count; $i++) {
        if ($lines[$i].Trim() -eq '---') { $end = $i; break }
    }
    if ($end -lt 0) {
        $result.Problems.Add('frontmatter is not closed (no closing ---)')
        return $result
    }

    $result.FrontmatterOk = $true
    $fm = $lines[1..($end - 1)]

    foreach ($line in $fm) {
        if ($line -match '^disable-model-invocation:\s*true\s*$') { $result.Hidden = $true }
    }

    $nameEntry = Get-YamlKeyEntry -Lines $fm -Key 'name'
    $descEntry = Get-YamlKeyEntry -Lines $fm -Key 'description'

    $result.HasName = Test-YamlScalar -Entry $nameEntry -Key 'name' -Lines $fm -Problems $result.Problems
    $result.HasDescription = Test-YamlScalar -Entry $descEntry -Key 'description' -Lines $fm -Problems $result.Problems

    return $result
}

# --------------------------------------------------------------------------
# Upstream acquisition
# --------------------------------------------------------------------------

function Expand-ZipUpstream {
    param([string]$Url, [string]$DestRoot)

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $zip = Join-Path $CacheDir ('dl-' + [guid]::NewGuid().ToString('N') + '.zip')
    $stage = Join-Path $CacheDir ('stage-' + [guid]::NewGuid().ToString('N'))

    Write-Info ('  downloading ' + $Url)
    Invoke-WebRequest -Uri $Url -OutFile $zip -UseBasicParsing

    New-Item -ItemType Directory -Force -Path $stage | Out-Null
    Expand-Archive -LiteralPath $zip -DestinationPath $stage -Force

    $inner = Get-ChildItem -LiteralPath $stage -Directory -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($inner) {
        Move-Item -LiteralPath $inner.FullName -Destination $DestRoot
    } else {
        Move-Item -LiteralPath $stage -Destination $DestRoot
    }

    Remove-Item -LiteralPath $zip -Force -ErrorAction SilentlyContinue
    if (Test-Path -LiteralPath $stage) { Remove-Item -LiteralPath $stage -Recurse -Force -ErrorAction SilentlyContinue }
}

function Get-UpstreamRoot {
    param([string]$SourceId)

    if ($script:SourceCache.ContainsKey($SourceId)) { return $script:SourceCache[$SourceId] }

    $spec = $null
    if ($manifestData.sources -and ($manifestData.sources.PSObject.Properties.Name -contains $SourceId)) {
        $spec = $manifestData.sources.$SourceId
    }
    if (-not $spec -or -not $spec.repo) {
        throw ('No usable upstream is declared for source "' + $SourceId + '"')
    }

    $dest = Join-Path $CacheDir ($SourceId -replace '[^A-Za-z0-9._-]', '_')
    if (Test-Path -LiteralPath $dest) {
        Write-Info ('  reusing cached upstream: ' + $SourceId)
        $script:SourceCache[$SourceId] = $dest
        return $dest
    }

    New-Item -ItemType Directory -Force -Path $CacheDir | Out-Null
    $ref = if ($spec.ref) { $spec.ref } else { 'main' }

    # npm is the most reliable route for rea-agents when npm is available.
    if ($spec.npmPackage -and (Get-Command npm -ErrorAction SilentlyContinue)) {
        try {
            $pkg = $spec.npmPackage
            if ($spec.npmVersion) { $pkg = $pkg + '@' + $spec.npmVersion }
            $packDir = Join-Path $CacheDir ('npmpack-' + [guid]::NewGuid().ToString('N'))
            New-Item -ItemType Directory -Force -Path $packDir | Out-Null
            Write-Info ('  npm pack ' + $pkg)
            & npm pack $pkg --pack-destination $packDir --silent 2>$null | Out-Null
            $tgz = Get-ChildItem -LiteralPath $packDir -Filter '*.tgz' -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($tgz -and (Get-Command tar -ErrorAction SilentlyContinue)) {
                $extract = Join-Path $packDir 'x'
                New-Item -ItemType Directory -Force -Path $extract | Out-Null
                & tar -xzf $tgz.FullName -C $extract 2>$null
                $pkgDir = Join-Path $extract 'package'
                if (Test-Path -LiteralPath $pkgDir) {
                    Move-Item -LiteralPath $pkgDir -Destination $dest
                    Remove-Item -LiteralPath $packDir -Recurse -Force -ErrorAction SilentlyContinue
                    $script:SourceCache[$SourceId] = $dest
                    return $dest
                }
            }
            Remove-Item -LiteralPath $packDir -Recurse -Force -ErrorAction SilentlyContinue
            Write-Warn '  npm pack did not yield a package tree, falling back to git'
        } catch {
            Write-Warn ('  npm pack failed (' + $_.Exception.Message + '), falling back to git')
        }
    }

    if (Get-Command git -ErrorAction SilentlyContinue) {
        Write-Info ('  git clone ' + $spec.repo + ' (' + $ref + ')')
        & git clone --depth 1 --branch $ref --quiet $spec.repo $dest 2>$null | Out-Null
        if ($LASTEXITCODE -eq 0 -and (Test-Path -LiteralPath $dest)) {
            $script:SourceCache[$SourceId] = $dest
            return $dest
        }
        if (Test-Path -LiteralPath $dest) {
            Remove-Item -LiteralPath $dest -Recurse -Force -ErrorAction SilentlyContinue
        }
        Write-Warn '  git clone failed, falling back to a zip download'
    }

    Expand-ZipUpstream -Url ($spec.repo + '/archive/refs/heads/' + $ref + '.zip') -DestRoot $dest

    $script:SourceCache[$SourceId] = $dest
    return $dest
}

function Get-SkillIndex {
    param([string]$SourceId)

    if ($script:SkillIndex.ContainsKey($SourceId)) { return $script:SkillIndex[$SourceId] }

    $root = Get-UpstreamRoot -SourceId $SourceId
    $map = @{}

    $mdFiles = @(Get-ChildItem -LiteralPath $root -Recurse -File -Filter 'SKILL.md' -ErrorAction SilentlyContinue)
    foreach ($md in $mdFiles) {
        $dir = $md.Directory
        if (-not $dir) { continue }

        $keys = @($dir.Name)
        # A skill may live at the repository root (ppt-master does). In that case
        # the checkout directory name is derived from the URL and does not match,
        # so the frontmatter name is used as an additional key.
        $fmName = Get-FrontmatterName -SkillMdPath $md.FullName
        if ($fmName) { $keys += $fmName }

        foreach ($key in $keys) {
            if (-not $map.ContainsKey($key)) {
                $map[$key] = New-Object System.Collections.Generic.List[string]
            }
            if (-not $map[$key].Contains($dir.FullName)) { $map[$key].Add($dir.FullName) }
        }
    }

    $script:SkillIndex[$SourceId] = $map
    return $map
}

function Select-BestSkillDir {
    param([string[]]$Candidates, [string]$Name)

    if (-not $Candidates -or $Candidates.Count -eq 0) { return $null }
    if ($Candidates.Count -eq 1) { return $Candidates[0] }

    $scored = foreach ($c in $Candidates) {
        $depth = ($c -split '[\\/]').Count
        $bonus = 0
        if ($c -match '[\\/]skills[\\/]' + [regex]::Escape($Name) + '$') { $bonus = -2 }
        elseif ($c -match '[\\/]skills[\\/][^\\/]+[\\/]' + [regex]::Escape($Name) + '$') { $bonus = -1 }
        [pscustomobject]@{ Path = $c; Score = ($depth + $bonus) }
    }

    return ($scored | Sort-Object Score, Path | Select-Object -First 1).Path
}

# --------------------------------------------------------------------------
# Copy
# --------------------------------------------------------------------------

function Copy-SkillTree {
    param([string]$Source, [string]$Destination)

    New-Item -ItemType Directory -Force -Path $Destination | Out-Null

    $robocopy = Get-Command robocopy.exe -ErrorAction SilentlyContinue
    if ($robocopy) {
        & robocopy $Source $Destination /E /XD .git .github /NFL /NDL /NJH /NJS /NP /R:2 /W:2 | Out-Null
        $code = $LASTEXITCODE
        if ($code -ge 8) { throw ('robocopy failed with exit code ' + $code) }
        return
    }

    Copy-Item -Path (Join-Path $Source '*') -Destination $Destination -Recurse -Force
}

# --------------------------------------------------------------------------
# Main
# --------------------------------------------------------------------------

$script:SourceCache = @{}
$script:SkillIndex = @{}
$script:Installed = New-Object System.Collections.Generic.List[object]
$script:Failed = New-Object System.Collections.Generic.List[object]

if (-not $Manifest) { $Manifest = Join-Path $PSScriptRoot 'skills.manifest.json' }
if (-not (Test-Path -LiteralPath $Manifest -PathType Leaf)) {
    Write-Err ('Manifest not found: ' + $Manifest)
    exit 2
}
$manifestData = Get-Content -LiteralPath $Manifest -Raw -Encoding UTF8 | ConvertFrom-Json

if (-not $DshHome) { $DshHome = $env:DSH_HOME }
if (-not $DshHome) {
    Write-Err 'DshHome was not given and DSH_HOME is not set. Pass -DshHome <path>.'
    exit 2
}
$DshHome = [System.IO.Path]::GetFullPath($DshHome)
if (-not (Test-Path -LiteralPath $DshHome -PathType Container)) {
    Write-Err ('DshHome does not exist: ' + $DshHome)
    exit 2
}

$SkillsRoot = Join-Path $DshHome 'skills'
if (-not $CacheDir) { $CacheDir = Join-Path ([System.IO.Path]::GetTempPath()) 'dsh-skills-cache' }

Write-Head 'DSH skills installer'
Write-Info ('Manifest : ' + $Manifest)
Write-Info ('DshHome  : ' + $DshHome)
Write-Info ('Target   : ' + $SkillsRoot)
Write-Info ('Cache    : ' + $CacheDir)
if ($DryRun) { Write-Info 'Mode     : DRY RUN (no network, no writes)' } else { Write-Info 'Mode     : INSTALL' }
if ($Force) { Write-Info 'Force    : existing skills are backed up and replaced' }

# ---- selection -----------------------------------------------------------

$allSkills = @($manifestData.skills)
$selected = $allSkills

if ($Only -and $Only.Count -gt 0) {
    $wanted = New-Object System.Collections.Generic.List[string]
    foreach ($item in $Only) {
        foreach ($piece in ($item -split ',')) {
            $trimmed = $piece.Trim()
            if ($trimmed) { $wanted.Add($trimmed) }
        }
    }
    $knownNames = @($allSkills | ForEach-Object { $_.name })
    $unknown = @($wanted | Where-Object { $knownNames -notcontains $_ })
    if ($unknown.Count -gt 0) {
        Write-Err ('Unknown skill name(s): ' + ($unknown -join ', '))
        Write-Info ('Known names: ' + (($knownNames | Sort-Object) -join ', '))
        exit 2
    }
    $selected = @($allSkills | Where-Object { $wanted -contains $_.name })
}

$toInstall = New-Object System.Collections.Generic.List[object]
$skipped = New-Object System.Collections.Generic.List[object]

foreach ($skill in $selected) {
    if ($skill.status -eq 'skip') {
        $skipped.Add([pscustomobject]@{ Name = $skill.name; Reason = ('unverified upstream: ' + $skill.statusReason) })
        continue
    }
    if ($SkipUnverified -and $skill.status -eq 'unverified') {
        $skipped.Add([pscustomobject]@{ Name = $skill.name; Reason = ('unverified upstream: ' + $skill.statusReason) })
        continue
    }
    $toInstall.Add($skill)
}

Write-Head ('Plan: ' + $toInstall.Count + ' to install, ' + $skipped.Count + ' skipped, ' + $allSkills.Count + ' in manifest')

if ($skipped.Count -gt 0) {
    Write-Host ''
    Write-Host 'Skipped:' -ForegroundColor DarkGray
    foreach ($s in $skipped) {
        Write-Host ('  - ' + $s.Name) -ForegroundColor DarkGray -NoNewline
        Write-Host (': ' + $s.Reason) -ForegroundColor DarkGray
    }
    if ($SkipUnverified) {
        Write-Host ''
        Write-Host 'Unverified skills are skipped by default. Rerun with -IncludeUnverified to include them.' -ForegroundColor DarkGray
    }
}

if ($DryRun) {
    Write-Head 'Dry run - would install'
    foreach ($skill in $toInstall) {
        $target = Join-Path $SkillsRoot $skill.name
        $state = if (Test-Path -LiteralPath $target) { 'exists' } else { 'new' }
        Write-Host ('  {0,-32} {1,-20} {2,10}  {3}' -f $skill.name, $skill.source, $skill.size, $state)
    }
    Write-Head 'Dry run complete'
    Write-Info 'Nothing was downloaded and nothing was written.'
    exit 0
}

# ---- install -------------------------------------------------------------

$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$validationProblems = New-Object System.Collections.Generic.List[string]

foreach ($skill in $toInstall) {
    $name = $skill.name
    $target = Join-Path $SkillsRoot $name

    Write-Host ''
    Write-Host ('[' + $name + ']') -ForegroundColor White

    # Existing install handling.
    if (Test-Path -LiteralPath $target) {
        $item = Get-Item -LiteralPath $target -Force
        $isLink = [bool]($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint)

        if (-not $Force) {
            Write-Warn '  already installed - left untouched (use -Force to replace)'
            $script:Installed.Add([pscustomobject]@{
                Name       = $name
                Source     = $skill.source
                Size       = $skill.size
                Hidden     = [bool]$skill.hidden
                Action     = 'kept'
                Validation = 'skipped'
            })
            continue
        }

        $backup = $target + '.bak-' + $timestamp
        $suffix = 1
        while (Test-Path -LiteralPath $backup) {
            $backup = $target + '.bak-' + $timestamp + '-' + $suffix
            $suffix++
        }
        Move-Item -LiteralPath $target -Destination $backup
        if ($isLink) {
            Write-Warn ('  existing entry was a reparse point (junction/symlink); moved it, its target was not touched -> ' + (Split-Path -Leaf $backup))
        } else {
            Write-Warn ('  backed up existing -> ' + (Split-Path -Leaf $backup))
        }
    }

    # Locate upstream copy.
    $sourceDir = $null
    try {
        $index = Get-SkillIndex -SourceId $skill.source
        if ($index.ContainsKey($name)) {
            $sourceDir = Select-BestSkillDir -Candidates ([string[]]$index[$name]) -Name $name
        }
    } catch {
        Write-Err ('  could not prepare upstream "' + $skill.source + '": ' + $_.Exception.Message)
        $script:Failed.Add([pscustomobject]@{ Name = $name; Reason = $_.Exception.Message })
        continue
    }

    if (-not $sourceDir) {
        Write-Err ('  not found in upstream ' + $skill.source)
        $script:Failed.Add([pscustomobject]@{ Name = $name; Reason = 'not present in upstream ' + $skill.source })
        continue
    }

    # Fail fast on a malformed upstream skill.
    $pre = Test-SkillDirectory -SkillDir $sourceDir
    if (-not $pre.HasSkillMd) {
        Write-Err '  upstream copy has no SKILL.md'
        $script:Failed.Add([pscustomobject]@{ Name = $name; Reason = 'upstream copy has no SKILL.md' })
        continue
    }

    try {
        Copy-SkillTree -Source $sourceDir -Destination $target
    } catch {
        Write-Err ('  copy failed: ' + $_.Exception.Message)
        $script:Failed.Add([pscustomobject]@{ Name = $name; Reason = 'copy failed: ' + $_.Exception.Message })
        if (Test-Path -LiteralPath $target) {
            Remove-Item -LiteralPath $target -Recurse -Force -ErrorAction SilentlyContinue
        }
        continue
    }

    # Validate what actually landed on disk.
    $check = Test-SkillDirectory -SkillDir $target
    $validation = 'ok'
    if (-not $check.HasSkillMd) { $validation = 'FAILED: SKILL.md missing' }
    elseif (-not $check.FrontmatterOk) { $validation = 'FAILED: frontmatter' }
    elseif (-not ($check.HasName -and $check.HasDescription)) { $validation = 'FAILED: name/description' }

    foreach ($problem in $check.Problems) {
        $validationProblems.Add(('[' + $name + '] ' + $problem))
    }

    $installedBytes = Get-TreeSize -Path $target
    $hidden = $check.Hidden
    $manifestHidden = [bool]$skill.hidden
    if ($hidden -ne $manifestHidden) {
        Write-Warn ('  hidden flag mismatch: manifest=' + $manifestHidden + ' actual=' + $hidden)
    }

    if ($validation -eq 'ok') {
        Write-Ok ('  installed ' + (Format-Size $installedBytes) + ' -> ' + $target)
    } else {
        Write-Err ('  ' + $validation)
        $script:Failed.Add([pscustomobject]@{ Name = $name; Reason = $validation })
    }

    $script:Installed.Add([pscustomobject]@{
        Name       = $name
        Source     = $skill.source
        Size       = (Format-Size $installedBytes)
        Hidden     = $hidden
        Action     = 'installed'
        Validation = $validation
    })
}

# ---- summary -------------------------------------------------------------

Write-Head 'Result'
if ($script:Installed.Count -gt 0) {
    $script:Installed |
        Select-Object Name, Source, Size, @{Name = 'Hidden'; Expression = { if ($_.Hidden) { 'yes' } else { 'no' } } }, Action, Validation |
        Format-Table -AutoSize |
        Out-String |
        Write-Host
} else {
    Write-Info 'No skills were installed.'
}

$okCount = @($script:Installed | Where-Object { $_.Validation -eq 'ok' -or $_.Validation -eq 'skipped' }).Count
$badCount = $script:Failed.Count

Write-Host ('Installed: ' + $okCount + '   Failed: ' + $badCount + '   Skipped: ' + $skipped.Count) -ForegroundColor Cyan

if ($validationProblems.Count -gt 0) {
    Write-Head 'Validation notes'
    foreach ($problem in $validationProblems) { Write-Warn $problem }
    Write-Info 'A description containing an unquoted ": " is valid-looking YAML that silently loses everything after the colon.'
    Write-Info 'Quote the value instead:  description: "First sentence: second sentence"'
}

if ($badCount -gt 0) {
    Write-Head 'Failures'
    foreach ($failure in $script:Failed) {
        Write-Host ('  ' + $failure.Name + ': ' + $failure.Reason) -ForegroundColor Red
    }
}

# ---- junctions elsewhere -------------------------------------------------

$agentsSkills = Join-Path $env:USERPROFILE '.agents\skills'
if (Test-Path -LiteralPath $agentsSkills -PathType Container) {
    $links = @(Get-ChildItem -LiteralPath $agentsSkills -Force -ErrorAction SilentlyContinue |
        Where-Object { $_.Attributes -band [System.IO.FileAttributes]::ReparsePoint })
    if ($links.Count -gt 0) {
        Write-Head 'Linked skill directories'
        foreach ($link in $links) {
            $targetInfo = $null
            try { $targetInfo = (Get-Item -LiteralPath $link.FullName -Force).Target } catch { }
            Write-Info ('  ' + $link.Name + ' -> ' + ($targetInfo -join ', '))
        }
        Write-Info 'A junction points at a path, not at content, so it keeps resolving after a reinstall.'
        Write-Info 'Recreate it by hand only if the skill moved to a different path.'
    }
}

Write-Head 'Done'
if ($badCount -gt 0) { exit 1 }
exit 0
