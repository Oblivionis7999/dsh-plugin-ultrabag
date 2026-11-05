<#
.SYNOPSIS
    用白名单自检一份 DSH `--dump-config` 输出；可选地与另一份 dump 做全树 id 级对比。

.DESCRIPTION
    只读，不改任何文件、不启动服务。

    默认模式（白名单）：
      读取 -Mine 的顶层 entry，对照 -Expected（默认同目录 expected-ids.json）：
        * mustExist      缺失即报告
        * mustBeDisabled 不是字面量 disabled: true 即报告
        * mustNotExist   出现即报告
      另外报告顶层 id 重复。条目总数只作信息输出。

    -Full 模式（全树）：
      需要 -Reference 指向另一份 dump，报告「谁少了 / 谁多了 / 谁被关了」。
      刻意不打印整行 diff：两千行输出里绝大多数是路径和版本噪音。

    判定口径：
      * 「顶层 entry」= 缩进为 0 的 `- id:` 行。
      * 缩进的 `- id:` 是 group 内部的嵌套条目，不参与条目级比较。
      * `name:` / `disabled:` 只认缩进恰为 2 的，避免把 group 内部的
        disabled 误算到上面的顶层条目头上。
      * 没有 `disabled:` 行 = 启用（on）；`true` = 关闭（off）；
        `!!js ...` = 条件（js），dump 不求值，只能按文本比。

.PARAMETER Mine
    自己生成的那份 dump，例如 my-dump.txt。

.PARAMETER Expected
    白名单 JSON，默认脚本同目录的 expected-ids.json。仅默认模式使用。

.PARAMETER Full
    切换到全树对比模式，此时必须给 -Reference。

.PARAMETER Reference
    全树对比的基准 dump（例如另一台机器上导出的那份）。仅 -Full 时使用。

.PARAMETER IncludeOrder
    仅 -Full：额外报告条目相对顺序的变化（bundle insert 顺序也会影响组合结果）。

.EXAMPLE
    .\compare.ps1 -Mine .\my-dump.txt

.EXAMPLE
    .\compare.ps1 -Mine .\my-dump.txt -Full -Reference .\other-dump.txt -IncludeOrder
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Mine,
    [string]$Expected = '',
    [switch]$Full,
    [string]$Reference = '',
    [switch]$IncludeOrder
)

$ErrorActionPreference = 'Stop'
try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $OutputEncoding = [System.Text.Encoding]::UTF8
}
catch { }

# ---------------------------------------------------------------- 解析
function Read-DumpConfig {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "找不到文件: $Path"
    }

    $lines  = [System.IO.File]::ReadAllLines($Path)
    $result = New-Object System.Collections.ArrayList
    $cur    = $null

    $reTopId   = [regex]'^-\s+id:\s*(.+?)\s*$'
    $reName    = [regex]'^  name:\s*(.+?)\s*$'
    $reDisable = [regex]'^  disabled:\s*(.*?)\s*$'

    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i].TrimEnd()

        if ($line -match '^\s*#') { continue }
        if ($line.Trim().Length -eq 0) { continue }

        if ($reTopId.IsMatch($line)) {
            $id = $reTopId.Match($line).Groups[1].Value.Trim()
            $id = $id.Trim("'").Trim('"')
            $cur = New-Object PSObject -Property @{
                Id          = $id
                Name        = ''
                Disabled    = 'on'
                DisabledRaw = ''
                Line        = $i + 1
            }
            [void]$result.Add($cur)
            continue
        }

        if ($null -eq $cur) { continue }

        if ($reName.IsMatch($line)) {
            $cur.Name = $reName.Match($line).Groups[1].Value.Trim().Trim("'").Trim('"')
            continue
        }

        if ($reDisable.IsMatch($line)) {
            $raw = $reDisable.Match($line).Groups[1].Value.Trim()
            $cur.DisabledRaw = $raw
            if ($raw -eq 'true') { $cur.Disabled = 'off' }
            elseif ($raw -eq 'false') { $cur.Disabled = 'on' }
            elseif ($raw -like '!!js*') { $cur.Disabled = 'js' }
            elseif ($raw.Length -eq 0) { $cur.Disabled = 'on' }
            else { $cur.Disabled = 'other' }
            continue
        }
    }

    return $result
}

function Build-Index {
    param($Entries, [string]$Label)

    # PowerShell 的 @{} 对字符串键默认大小写不敏感，正好可用
    $map  = @{}
    $dups = New-Object System.Collections.ArrayList

    foreach ($e in $Entries) {
        if ($map.ContainsKey($e.Id)) { [void]$dups.Add($e.Id) }
        else { $map[$e.Id] = $e }
    }

    if ($dups.Count -gt 0) {
        $u = ($dups | Sort-Object -Unique) -join ', '
        Write-Host ("  ! {0} 内部有重复 id: {1}" -f $Label, $u) -ForegroundColor Yellow
    }

    return $map
}

# ---------------------------------------------------------------- 白名单模式
if (-not $Full) {
    if ([string]::IsNullOrWhiteSpace($Expected)) {
        $Expected = Join-Path $PSScriptRoot 'expected-ids.json'
    }
    if (-not (Test-Path -LiteralPath $Expected -PathType Leaf)) {
        throw "找不到白名单: $Expected"
    }
    $wl = [System.IO.File]::ReadAllText($Expected, [System.Text.Encoding]::UTF8) | ConvertFrom-Json
    $mustExist      = @($wl.mustExist | Where-Object { $_ })
    $mustBeDisabled = @($wl.mustBeDisabled | Where-Object { $_ })
    $mustNotExist   = @($wl.mustNotExist | Where-Object { $_ })

    $myEntries = @(Read-DumpConfig -Path $Mine)
    Write-Host ''
    Write-Host '== DSH 配置白名单自检 ==' -ForegroundColor Cyan
    Write-Host ("  本地  : {0}  ({1} 条顶层 entry，仅供参考)" -f $Mine, $myEntries.Count)
    Write-Host ("  白名单: {0}" -f $Expected)
    $myMap = Build-Index -Entries $myEntries -Label '本地'

    $problems = 0
    $dupIds = @($myEntries | Group-Object Id | Where-Object { $_.Count -gt 1 } | ForEach-Object { $_.Name })
    if ($dupIds.Count -gt 0) { $problems += $dupIds.Count }

    $missing = @($mustExist | Where-Object { -not $myMap.ContainsKey($_) })
    Write-Host ''
    if ($missing.Count -eq 0) {
        Write-Host ("-- mustExist: {0} 个均在" -f $mustExist.Count) -ForegroundColor Green
    } else {
        Write-Host ("-- 缺失: {0} 个    (bundle 没装上 / 被 profile.bundles 漏了)" -f $missing.Count) -ForegroundColor Red
        foreach ($id in $missing) { Write-Host ("   {0}" -f $id) -ForegroundColor Red }
        $problems += $missing.Count
    }

    $notDisabled = New-Object System.Collections.ArrayList
    foreach ($id in $mustBeDisabled) {
        if (-not $myMap.ContainsKey($id)) {
            [void]$notDisabled.Add(("{0,-34} 不存在" -f $id))
        } elseif ($myMap[$id].DisabledRaw -ne 'true') {
            $raw = $myMap[$id].DisabledRaw
            if ([string]::IsNullOrEmpty($raw)) { $raw = '(无 disabled 字段，视为启用)' }
            [void]$notDisabled.Add(("{0,-34} disabled: {1}" -f $id, $raw))
        }
    }
    if ($notDisabled.Count -eq 0) {
        Write-Host ("-- mustBeDisabled: {0} 个均为 disabled: true" -f $mustBeDisabled.Count) -ForegroundColor Green
    } else {
        Write-Host ("-- 未禁用: {0} 个    (运行 core\harden.ps1 -Apply)" -f $notDisabled.Count) -ForegroundColor Red
        foreach ($t in $notDisabled) { Write-Host ("   {0}" -f $t) -ForegroundColor Red }
        $problems += $notDisabled.Count
    }

    $present = @($mustNotExist | Where-Object { $myMap.ContainsKey($_) })
    if ($present.Count -eq 0) {
        Write-Host ("-- mustNotExist: {0} 个均不存在" -f $mustNotExist.Count) -ForegroundColor Green
    } else {
        Write-Host ("-- 不应存在: {0} 个" -f $present.Count) -ForegroundColor Red
        foreach ($id in $present) { Write-Host ("   {0}" -f $id) -ForegroundColor Red }
        $problems += $present.Count
    }

    Write-Host ''
    if ($problems -gt 0) {
        Write-Host ("汇总：{0} 处问题。" -f $problems) -ForegroundColor Cyan
        exit 1
    }
    Write-Host '汇总：白名单检查全部通过。' -ForegroundColor Green
    exit 0
}

if ([string]::IsNullOrWhiteSpace($Reference)) {
    throw '-Full 模式需要 -Reference <另一份 dump 文件>'
}

# ---------------------------------------------------------------- 入口
$refEntries = @(Read-DumpConfig -Path $Reference)
$myEntries  = @(Read-DumpConfig -Path $Mine)

Write-Host ''
Write-Host '== DSH 配置条目级对比 ==' -ForegroundColor Cyan
Write-Host ("  参考: {0}  ({1} 条顶层 entry)" -f $Reference, $refEntries.Count)
Write-Host ("  本地: {0}  ({1} 条顶层 entry)" -f $Mine, $myEntries.Count)

$diffNum = 0
if ($refEntries.Count -ne $myEntries.Count) {
    Write-Host ("  .. 条目总数不同: 参考 {0} / 本地 {1}（仅供参考，以下面的 id 级差异为准）" -f $refEntries.Count, $myEntries.Count) -ForegroundColor DarkGray
}

$refMap = Build-Index -Entries $refEntries -Label '参考'
$myMap  = Build-Index -Entries $myEntries  -Label '本地'

$missing = New-Object System.Collections.ArrayList
$extra   = New-Object System.Collections.ArrayList
$changed = New-Object System.Collections.ArrayList

foreach ($e in $refEntries) {
    if (-not $myMap.ContainsKey($e.Id)) {
        [void]$missing.Add($e)
        continue
    }
    $o = $myMap[$e.Id]
    if ($o.Disabled -ne $e.Disabled) {
        [void]$changed.Add((New-Object PSObject -Property @{
                    Id = $e.Id; Name = $e.Name
                    Was = $e.Disabled; Now = $o.Disabled
                    WasRaw = $e.DisabledRaw; NowRaw = $o.DisabledRaw
                }))
    }
    elseif ($e.Name -and $o.Name -and $e.Name -ne $o.Name) {
        [void]$changed.Add((New-Object PSObject -Property @{
                    Id = $e.Id; Name = $e.Name
                    Was = 'name'; Now = 'name'
                    WasRaw = $e.Name; NowRaw = $o.Name
                }))
    }
}

foreach ($e in $myEntries) {
    if (-not $refMap.ContainsKey($e.Id)) { [void]$extra.Add($e) }
}

# ---------------------------------------------------------------- 输出
if ($diffNum -eq 0 -and $missing.Count -eq 0 -and $extra.Count -eq 0 -and $changed.Count -eq 0) {
    Write-Host ''
    Write-Host '结论：条目集合与开关状态完全一致。' -ForegroundColor Green
    Write-Host '（路径、注释头、版本差异不在本脚本比较范围内，属正常噪音。）' -ForegroundColor DarkGray
}
else {
    if ($missing.Count -gt 0) {
        Write-Host ''
        Write-Host ("-- 参考有、你缺: {0} 条    (bundle 没装上 / 被 profile.bundles 漏了)" -f $missing.Count) -ForegroundColor Red
        foreach ($it in $missing) {
            Write-Host ("   {0,-34} {1}" -f $it.Id, $it.Name) -ForegroundColor Red
        }
        $diffNum += $missing.Count
    }

    if ($extra.Count -gt 0) {
        Write-Host ''
        Write-Host ("-- 你有、参考没有: {0} 条    (你自己 patch 加的 / 版本更新)" -f $extra.Count) -ForegroundColor Yellow
        foreach ($it in $extra) {
            Write-Host ("   {0,-34} {1}" -f $it.Id, $it.Name) -ForegroundColor Yellow
        }
        $diffNum += $extra.Count
    }

    if ($changed.Count -gt 0) {
        Write-Host ''
        Write-Host ("-- 开关/名字不同: {0} 条" -f $changed.Count) -ForegroundColor Magenta
        foreach ($it in $changed) {
            if ($it.Was -eq 'name') {
                Write-Host ("   {0,-34} name: {1}  ->  {2}" -f $it.Id, $it.WasRaw, $it.NowRaw) -ForegroundColor Magenta
            }
            else {
                $note = ''
                if ($it.Now -eq 'js' -or $it.Was -eq 'js') {
                    $note = '   (!!js 条件表达式，dump 不求值)'
                }
                Write-Host ("   {0,-34} disabled: {1} -> {2}{3}" -f $it.Id, $it.Was, $it.Now, $note) -ForegroundColor Magenta
            }
        }
        $diffNum += $changed.Count
    }
}

# ---------------------------------------------------------------- 顺序
if ($IncludeOrder) {
    $refPos = @{}
    for ($i = 0; $i -lt $refEntries.Count; $i++) { $refPos[$refEntries[$i].Id] = $i }

    $moved = New-Object System.Collections.ArrayList
    $myCommon = @($myEntries | Where-Object { $refMap.ContainsKey($_.Id) })
    for ($i = 0; $i -lt $myCommon.Count; $i++) {
        $id = $myCommon[$i].Id
        $delta = $i - $refPos[$id]
        if ($delta -ne 0) {
            [void]$moved.Add((New-Object PSObject -Property @{
                        Id = $id; Ref = $refPos[$id]; Mine = $i; Delta = $delta
                    }))
        }
    }

    if ($moved.Count -eq 0) {
        Write-Host ''
        Write-Host '-- 顺序: 一致' -ForegroundColor DarkGray
    }
    else {
        Write-Host ''
        Write-Host ("-- 顺序不同: {0} 条    (insert 位置影响组合顺序)" -f $moved.Count) -ForegroundColor DarkCyan
        foreach ($it in $moved) {
            Write-Host ("   {0,-34} ref #{1} -> 本地 #{2} ({3})" -f $it.Id, $it.Ref, $it.Mine, $it.Delta) -ForegroundColor DarkCyan
        }
    }
}

Write-Host ''
if ($diffNum -gt 0) {
    Write-Host ("汇总：{0} 处条目级差异。" -f $diffNum) -ForegroundColor Cyan
    exit 1
}
Write-Host '汇总：0 处条目级差异。' -ForegroundColor Green
exit 0
