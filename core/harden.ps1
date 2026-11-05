<#
.SYNOPSIS
  收紧（或还原）DSH profile 的默认策略：禁用两个远程插件，approval=ask，sandbox=workspace-write。

.DESCRIPTION
  只追加/替换 profile 的 cordis.patch.yml 中带标记的一个「托管块」，
  绝不改动文件里其他 patch 内容。块首尾标记：
      # >>> dsh-install-kit:harden
      # <<< dsh-install-kit:harden
  -Apply   写入或更新（幂等：内容一致时不做任何事、不产生备份）
  -Restore 删除该块，策略回到 bundle 默认值

  每次真正改动前都会把原文件备份为
      cordis.patch.yml.bak-harden-<时间戳>
  并且保持原文件的换行风格（LF/CRLF）与无 BOM 编码。

  注意（Windows）：dsh-base 在 win32 上默认把 sandbox 设为 danger-full-access、
  approval 设为 never。本脚本写死 workspace-write / ask，能生效但可能降低
  工具可用性，也会让无人值守的 agent 卡在审批提示上。不确定就先用 -DryRun 看计划。

.PARAMETER Apply
  应用收紧策略。

.PARAMETER Restore
  移除本脚本写入的托管块（只移除它自己写的内容）。

.PARAMETER DshHome
  DSH_HOME 目录，默认 $env:DSH_HOME，其次 $env:USERPROFILE\.dsh。

.PARAMETER ProfileName
  profile 名，默认 web。

.PARAMETER PatchPath
  直接指定 cordis.patch.yml 路径（覆盖 -DshHome/-ProfileName 推导）。

.PARAMETER DryRun
  只打印将要发生的改动，不写文件、不备份。

.EXAMPLE
  .\harden.ps1 -Apply -DryRun

.EXAMPLE
  powershell -NoProfile -ExecutionPolicy Bypass -File .\harden.ps1 -Restore -DshHome "<DSH安装根>\home"
#>
[CmdletBinding()]
param(
    [switch]$Apply,
    [switch]$Restore,
    [string]$DshHome = $env:DSH_HOME,
    [string]$ProfileName = 'web',
    [string]$PatchPath = '',
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

# 输出固定为 UTF-8：agent 用管道抓取时不依赖控制台代码页（cp936 会糊掉中文）
try { [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false) } catch { }

$StartMarker = '# >>> dsh-install-kit:harden'
$EndMarker = '# <<< dsh-install-kit:harden'

# 托管块正文（顺序有意：先禁用，再策略）
# 托管块内容保持纯 ASCII：cordis.patch.yml 是无 BOM 的 UTF-8，
# 混入中文会让用 ANSI 读取该文件的工具把换行吞掉（已实测）。
$BlockLines = @(
    ('{0} (managed by harden.ps1; edits inside are overwritten on next -Apply)' -f $StartMarker),
    '- id: web-ui-remote-bridge',
    '  disabled: true',
    '- id: web-ui-task-board-remote',
    '  disabled: true',
    '- id: approval',
    '  config:',
    '    policy: ask',
    '- id: sandbox-policy',
    '  config:',
    '    mode: workspace-write',
    ('{0} (end)' -f $EndMarker)
)

function Write-Ok {
    param([string]$Message)
    Write-Host ("  OK  {0}" -f $Message) -ForegroundColor Green
}

function Write-Info {
    param([string]$Message)
    Write-Host ("  ..  {0}" -f $Message) -ForegroundColor Gray
}

function Write-Warn {
    param([string]$Message)
    Write-Host ("  !   {0}" -f $Message) -ForegroundColor Yellow
}

function Fail {
    param([string]$Message)
    throw $Message
}

function Get-BlockRange {
    param([string[]]$Lines)

    $start = -1
    $end = -1
    for ($i = 0; $i -lt $Lines.Count; $i++) {
        if ($Lines[$i].StartsWith($StartMarker)) {
            $start = $i
            continue
        }
        if ($Lines[$i].StartsWith($EndMarker) -and $start -ge 0) {
            $end = $i
            break
        }
    }
    if ($start -ge 0 -and $end -lt 0) {
        Fail ("找到起始标记但没有结束标记（{0}），文件可能被手工改坏；请先修复再运行。" -f $EndMarker)
    }
    if ($start -lt 0) { return $null }
    return [pscustomobject]@{ Start = $start; End = $end }
}

# ---------------------------------------------------------------- 主流程

Write-Host ''
Write-Host '  收紧 profile 策略（harden）' -ForegroundColor Cyan

try {
    if ($Apply -and $Restore) {
        Fail '不能同时给 -Apply 和 -Restore。'
    }
    if (-not $Apply -and -not $Restore) {
        Write-Host ''
        Write-Host '  用法：' -ForegroundColor Yellow
        Write-Host '    .\harden.ps1 -Apply    [-DshHome <目录>] [-ProfileName web] [-DryRun]'
        Write-Host '    .\harden.ps1 -Restore  [-DshHome <目录>] [-ProfileName web] [-DryRun]'
        exit 2
    }

    if (-not [string]::IsNullOrWhiteSpace($PatchPath)) {
        $patchFile = $PatchPath
    } else {
        if ([string]::IsNullOrWhiteSpace($DshHome)) {
            $DshHome = Join-Path $env:USERPROFILE '.dsh'
        }
        $DshHome = [System.IO.Path]::GetFullPath($DshHome)
        $patchFile = Join-Path $DshHome ('profiles\' + $ProfileName + '\cordis.patch.yml')
    }
    $patchFile = [System.IO.Path]::GetFullPath($patchFile)

    Write-Host ("  目标 : {0}" -f $patchFile)
    if ($DryRun) { Write-Host '  模式 : DRY RUN（不写文件）' -ForegroundColor Yellow }

    if (-not (Test-Path -LiteralPath $patchFile -PathType Leaf)) {
        Fail ("找不到 {0}`n请先运行 install.ps1，或用 -PatchPath 指定文件。" -f $patchFile)
    }

    $original = [System.IO.File]::ReadAllText($patchFile)
    if ($original.Length -eq 0) {
        $original = "[]`n"
    }

    $eol = "`n"
    if ($original.Contains("`r`n")) { $eol = "`r`n" }

    $normalized = $original -replace "`r`n", "`n"
    $lines = New-Object System.Collections.Generic.List[string]
    foreach ($line in ($normalized -split "`n")) { [void]$lines.Add($line) }

    # 末尾换行会切出一个空元素，去掉，稍后统一补回
    $hadTrailingNewline = $false
    if ($lines.Count -gt 0 -and $lines[$lines.Count - 1] -eq '') {
        $hadTrailingNewline = $true
        $lines.RemoveAt($lines.Count - 1)
    }

    $range = Get-BlockRange -Lines $lines.ToArray()

    if ($Restore) {
        if ($null -eq $range) {
            Write-Info '文件里没有 harden 托管块，无需还原。'
            if ($DryRun) { Write-Host '  DRY RUN 结束：未做任何修改。' -ForegroundColor Green }
            exit 0
        }

        $newLines = New-Object System.Collections.Generic.List[string]
        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($i -lt $range.Start -or $i -gt $range.End) { [void]$newLines.Add($lines[$i]) }
        }
        # 去掉块前后可能留下的多余空行（最多保留一个）
        while ($newLines.Count -gt 0 -and $newLines[$newLines.Count - 1] -eq '') {
            $newLines.RemoveAt($newLines.Count - 1)
        }

        Write-Host ''
        Write-Host ("  将删除托管块：第 {0}-{1} 行（共 {2} 行）" -f ($range.Start + 1), ($range.End + 1), ($range.End - $range.Start + 1)) -ForegroundColor Yellow
        if ($DryRun) {
            Write-Host '  DRY RUN 结束：未做任何修改。' -ForegroundColor Green
            exit 0
        }

        $backup = "{0}.bak-harden-{1}" -f $patchFile, (Get-Date -Format 'yyyyMMdd-HHmmss')
        Copy-Item -LiteralPath $patchFile -Destination $backup -Force
        Write-Ok ("已备份 -> {0}" -f $backup)

        $text = ($newLines -join $eol)
        if ($text.Length -gt 0 -and -not $text.EndsWith($eol)) { $text += $eol }
        [System.IO.File]::WriteAllText($patchFile, $text, (New-Object System.Text.UTF8Encoding($false)))

        Write-Ok '已移除托管块：两个远程插件恢复默认、approval/sandbox 回到 bundle 默认值'
        Write-Info ('还原后的默认值（Windows）：sandbox=danger-full-access，approval=never')
        Write-Info '建议再跑一次 verify.ps1 确认合成树完好'
        exit 0
    }

    # ---------------- Apply ----------------
    if ($null -eq $range) {
        Write-Host ''
        Write-Host ("  将追加托管块（{0} 行）到文件末尾" -f $BlockLines.Count) -ForegroundColor Yellow
    } else {
        $current = @($lines[$range.Start..$range.End])
        $same = (($current -join "`n") -eq ($BlockLines -join "`n"))
        if ($same) {
            Write-Ok '托管块已存在且内容一致，无需改动（幂等）'
            Write-Info 'profile 已是收紧状态：两个远程插件 disabled，approval=ask，sandbox=workspace-write'
            exit 0
        }
        Write-Host ''
        Write-Host ("  将替换现有托管块：第 {0}-{1} 行" -f ($range.Start + 1), ($range.End + 1)) -ForegroundColor Yellow
    }

    Write-Host ''
    Write-Host '  托管块内容：' -ForegroundColor Cyan
    foreach ($line in $BlockLines) { Write-Host ("    {0}" -f $line) -ForegroundColor DarkGray }
    Write-Host ''
    Write-Warn 'Windows 上 dsh-base 默认 danger-full-access / approval=never；改成 workspace-write / ask 可能降低工具可用性。'
    Write-Warn 'approval=ask 会让无人值守的 agent 卡在审批提示上，请确认有人在场。'

    if ($DryRun) {
        Write-Host '  DRY RUN 结束：未做任何修改。' -ForegroundColor Green
        exit 0
    }

    $backup = "{0}.bak-harden-{1}" -f $patchFile, (Get-Date -Format 'yyyyMMdd-HHmmss')
    Copy-Item -LiteralPath $patchFile -Destination $backup -Force
    Write-Ok ("已备份 -> {0}" -f $backup)

    if ($null -eq $range) {
        if ($lines.Count -gt 0) { [void]$lines.Add('') }
        foreach ($line in $BlockLines) { [void]$lines.Add($line) }
    } else {
        $newLines = New-Object System.Collections.Generic.List[string]
        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($i -eq $range.Start) {
                foreach ($line in $BlockLines) { [void]$newLines.Add($line) }
            }
            if ($i -ge $range.Start -and $i -le $range.End) { continue }
            [void]$newLines.Add($lines[$i])
        }
        $lines = $newLines
    }

    $text = ($lines -join $eol)
    if (-not $text.EndsWith($eol)) { $text += $eol }
    [System.IO.File]::WriteAllText($patchFile, $text, (New-Object System.Text.UTF8Encoding($false)))

    Write-Ok '已写入托管块'
    Write-Info '生效方式：重启 DSH（运行中的实例可能通过 HMR 即时重挂，行为不一定稳定）'
    Write-Info '建议：.\verify.ps1 -DshHome <DSH_HOME> 确认两个插件为 disabled'
    exit 0
} catch {
    Write-Host ''
    Write-Host ("  失败：{0}" -f $_.Exception.Message) -ForegroundColor Red
    exit 1
}
