<#
.SYNOPSIS
  DSH profile 验证器：渲染合成树并检查关键不变量，输出 PASS/FAIL 表。

.DESCRIPTION
  以 `<dsh>/lib/bin.js --profile <name> --dump-config` 渲染 profile 的合成配置树，
  然后检查：
    1) dump 退出码与 stderr 致命模式（skipping profile bundle / declares no dsh.bundle / duplicate）
    2) 顶层 id 无重复
    3) 白名单（默认 ..\reference\expected-ids.json）：
         mustExist      必须存在的顶层 id
         mustBeDisabled 必须字面量 disabled: true 的顶层 id
         mustNotExist   不应出现的顶层 id
       -RequiredIds / -MustBeDisabled 可在白名单之外追加检查项
    4) profile package.json 里的 link: 依赖在本机可解析
  顶层 entry 总数只作信息输出，不参与 PASS/FAIL（随 DSH 与插件版本变化）。

  只读：不写 profile。唯一的副作用是 dsh 自己会把 profile 根目录的 cordis.yml
  重写为标准空数组 `[]`（内容等价，正常现象）。

  退出码：0 = 全部 PASS（WARN 不影响）；1 = 存在 FAIL；2 = 无法执行（缺 node / dsh / profile）。

.PARAMETER DshHome
  DSH_HOME 目录，其下应有 profiles\<ProfileName>。
  默认取 $env:DSH_HOME，其次 $env:USERPROFILE\.dsh。

.PARAMETER ProfileName
  profile 名，默认 web。

.PARAMETER DshBin
  dsh 的 lib\bin.js 路径，或 DSH 安装根（含 node_modules\@deepseek-ai\dsh）。
  省略时依次尝试：$DshHome 的上一级安装根、$env:APPDATA\npm 全局包。

.PARAMETER ExpectedIdsFile
  白名单 JSON，默认脚本上一级的 reference\expected-ids.json。
  文件缺失或无法解析时判 FAIL。

.PARAMETER RequiredIds
  在白名单 mustExist 之外追加的必需顶层 id（可选，默认空）。

.PARAMETER MustBeDisabled
  在白名单 mustBeDisabled 之外追加的、必须显式 `disabled: true` 的顶层 id（可选，默认空）。

.PARAMETER ForbiddenStderr
  stderr 中出现即判 FAIL 的子串（不区分大小写）。

.EXAMPLE
  powershell -NoProfile -ExecutionPolicy Bypass -File .\verify.ps1 -DshHome "<DSH安装根>\home"

.EXAMPLE
  .\verify.ps1 -DshHome "$env:USERPROFILE\.dsh" -ProfileName web -RequiredIds web-ui-ssh
#>
[CmdletBinding()]
param(
    [string]$DshHome = $env:DSH_HOME,
    [string]$ProfileName = 'web',
    [string]$DshBin = '',
    [string]$ExpectedIdsFile = '',
    [string[]]$RequiredIds = @(),
    [string[]]$MustBeDisabled = @(),
    [string[]]$ForbiddenStderr = @('skipping profile bundle', 'declares no dsh.bundle', 'duplicate'),
    [string]$ExpectedDshVersion = '0.2.1-rc.5',
    [int]$TimeoutSeconds = 120
)

$ErrorActionPreference = 'Stop'

# 输出固定为 UTF-8：agent 用管道抓取时不依赖控制台代码页（cp936 会糊掉中文）
try { [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false) } catch { }

# ---------------------------------------------------------------- 输出工具

$script:Rows = New-Object System.Collections.ArrayList

function Add-Row {
    param([string]$Check, [string]$Result, [string]$Detail)
    [void]$script:Rows.Add([pscustomobject]@{ Check = $Check; Result = $Result; Detail = $Detail })
}

function Get-DisplayWidth {
    param([string]$Text)
    if ([string]::IsNullOrEmpty($Text)) { return 0 }
    $width = 0
    foreach ($ch in $Text.ToCharArray()) {
        $code = [int][char]$ch
        if (($code -ge 0x1100 -and $code -le 0x115F) -or
            ($code -ge 0x2E80 -and $code -le 0xA4CF) -or
            ($code -ge 0xAC00 -and $code -le 0xD7A3) -or
            ($code -ge 0xF900 -and $code -le 0xFAFF) -or
            ($code -ge 0xFE30 -and $code -le 0xFE6F) -or
            ($code -ge 0xFF00 -and $code -le 0xFF60) -or
            ($code -ge 0xFFE0 -and $code -le 0xFFE6)) {
            $width += 2
        } else {
            $width += 1
        }
    }
    return $width
}

function Format-Cell {
    param([string]$Text, [int]$Width)
    if ($null -eq $Text) { $Text = '' }
    $Text = $Text -replace "[\r\n]+", ' '
    if ((Get-DisplayWidth $Text) -le $Width) {
        $pad = $Width - (Get-DisplayWidth $Text)
        return $Text + (' ' * $pad)
    }
    $sb = New-Object System.Text.StringBuilder
    $used = 0
    foreach ($ch in $Text.ToCharArray()) {
        $w = Get-DisplayWidth ([string]$ch)
        if ($used + $w -gt ($Width - 3)) { break }
        [void]$sb.Append($ch)
        $used += $w
    }
    [void]$sb.Append('...')
    $pad = $Width - (Get-DisplayWidth $sb.ToString())
    if ($pad -lt 0) { $pad = 0 }
    return $sb.ToString() + (' ' * $pad)
}

function Write-Table {
    $checkHeader = Format-Cell '检查项' 34
    $resultHeader = Format-Cell '结果' 8
    Write-Host ''
    Write-Host ('  ' + $checkHeader + $resultHeader + '说明') -ForegroundColor Cyan
    Write-Host ('  ' + ('-' * 108)) -ForegroundColor DarkGray
    foreach ($row in $script:Rows) {
        $color = 'Gray'
        if ($row.Result -eq 'PASS') { $color = 'Green' }
        elseif ($row.Result -eq 'WARN') { $color = 'Yellow' }
        elseif ($row.Result -eq 'FAIL') { $color = 'Red' }
        Write-Host ('  ' + (Format-Cell $row.Check 34) + (Format-Cell $row.Result 8) + $row.Detail) -ForegroundColor $color
    }
    Write-Host ''
}

# ---------------------------------------------------------------- 路径解析

function Resolve-DshBinPath {
    param([string]$HomeDir, [string]$Explicit)

    if (-not [string]::IsNullOrWhiteSpace($Explicit)) {
        $candidate = $Explicit
        if (Test-Path -LiteralPath $candidate -PathType Container) {
            $candidate = Join-Path $candidate 'node_modules\@deepseek-ai\dsh\lib\bin.js'
        }
        if (Test-Path -LiteralPath $candidate -PathType Leaf) { return (Resolve-Path -LiteralPath $candidate).Path }
        throw "-DshBin 指向的路径不存在：$Explicit"
    }

    $candidates = New-Object System.Collections.ArrayList
    if (-not [string]::IsNullOrWhiteSpace($env:DSH_BIN)) {
        if ($env:DSH_BIN -like '*.js') {
            [void]$candidates.Add($env:DSH_BIN)
        } else {
            [void]$candidates.Add((Join-Path $env:DSH_BIN 'node_modules\@deepseek-ai\dsh\lib\bin.js'))
        }
    }
    if (-not [string]::IsNullOrWhiteSpace($HomeDir)) {
        $parent = Split-Path -Parent $HomeDir
        if (-not [string]::IsNullOrWhiteSpace($parent)) {
            [void]$candidates.Add((Join-Path $parent 'node_modules\@deepseek-ai\dsh\lib\bin.js'))
        }
    }
    if ($env:APPDATA) {
        [void]$candidates.Add((Join-Path $env:APPDATA 'npm\node_modules\@deepseek-ai\dsh\lib\bin.js'))
    }
    if ($env:LOCALAPPDATA) {
        [void]$candidates.Add((Join-Path $env:LOCALAPPDATA 'npm\node_modules\@deepseek-ai\dsh\lib\bin.js'))
    }

    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
            return (Resolve-Path -LiteralPath $candidate).Path
        }
    }

    throw "找不到 dsh 的 lib\bin.js。请用 -DshBin 指向它，例如：-DshBin '<DSH 安装根>\node_modules\@deepseek-ai\dsh\lib\bin.js'。已尝试：$($candidates -join '; ')"
}

function Read-JsonFile {
    param([string]$Path)
    $raw = [System.IO.File]::ReadAllText($Path)
    return ($raw | ConvertFrom-Json)
}

function Get-LinkDependencies {
    param([string]$PackageJsonPath)

    $result = New-Object System.Collections.ArrayList
    if (-not (Test-Path -LiteralPath $PackageJsonPath)) { return $result }

    $pkg = Read-JsonFile -Path $PackageJsonPath
    $deps = $pkg.dependencies
    if ($null -eq $deps) { return $result }

    $baseDir = Split-Path -Parent $PackageJsonPath
    foreach ($prop in $deps.PSObject.Properties) {
        $spec = [string]$prop.Value
        if ($spec -notmatch '^link:(.+)$') { continue }
        $target = $matches[1]
        if (-not [System.IO.Path]::IsPathRooted($target)) {
            $target = Join-Path $baseDir $target
        }
        $exists = Test-Path -LiteralPath $target
        [void]$result.Add([pscustomobject]@{ Package = $prop.Name; Target = $target; Exists = $exists })
    }
    return $result
}

# 取某个顶层 entry 的 disabled 原始值；返回 @{ Found; Value }
function Get-EntryDisabledValue {
    param([string[]]$Lines, [string]$TargetId)

    $inBlock = $false
    $found = $false
    $value = $null

    foreach ($line in $Lines) {
        if ($line -match '^- id:[ \t]*(?<id>[^\r\n]+?)[ \t]*$') {
            $id = $matches['id'].Trim().Trim([char[]]@("'", '"'))
            $inBlock = ($id -eq $TargetId)
            if ($inBlock) { $found = $true; $value = $null }
            continue
        }
        if ($inBlock) {
            if ($line -match '^[^\s]') { $inBlock = $false; continue }
            if ($line -match '^  disabled:[ \t]*(?<v>[^\r\n]*)$') {
                $value = $matches['v'].Trim()
            }
        }
    }

    return [pscustomobject]@{ Found = $found; Value = $value }
}

# ---------------------------------------------------------------- 主流程

$exitCode = 2
$tempDir = $null
$oldHome = $env:DSH_HOME

try {
    if ([string]::IsNullOrWhiteSpace($DshHome)) {
        $DshHome = Join-Path $env:USERPROFILE '.dsh'
    }
    $DshHome = [System.IO.Path]::GetFullPath($DshHome)
    $profilePath = Join-Path $DshHome ('profiles\' + $ProfileName)

    Write-Host ''
    Write-Host '  DSH profile 验证' -ForegroundColor Cyan
    Write-Host "  DSH_HOME : $DshHome"
    Write-Host "  profile  : $ProfileName  ($profilePath)"
    Write-Host ''

    if (-not (Test-Path -LiteralPath $profilePath -PathType Container)) {
        Add-Row 'profile 目录' 'FAIL' "不存在：$profilePath（先运行 install.ps1）"
        $exitCode = 2
        Write-Table
        exit $exitCode
    }
    Add-Row 'profile 目录' 'PASS' $profilePath

    # ---------- 白名单 ----------
    if ([string]::IsNullOrWhiteSpace($ExpectedIdsFile)) {
        $ExpectedIdsFile = Join-Path (Split-Path -Parent $PSScriptRoot) 'reference\expected-ids.json'
    }
    $wlExist = @()
    $wlDisabled = @()
    $wlNotExist = @()
    $whitelistOk = $false
    if (-not (Test-Path -LiteralPath $ExpectedIdsFile -PathType Leaf)) {
        Add-Row '白名单文件' 'FAIL' "不存在：$ExpectedIdsFile"
    } else {
        try {
            $wl = [System.IO.File]::ReadAllText($ExpectedIdsFile, [System.Text.Encoding]::UTF8) | ConvertFrom-Json
            $wlExist = @($wl.mustExist | Where-Object { $_ })
            $wlDisabled = @($wl.mustBeDisabled | Where-Object { $_ })
            $wlNotExist = @($wl.mustNotExist | Where-Object { $_ })
            $wlVer = ''
            if ($null -ne $wl.verifiedWith -and $wl.verifiedWith.dsh) { $wlVer = "，验证于 dsh $($wl.verifiedWith.dsh)" }
            Add-Row '白名单文件' 'PASS' ("{0}（mustExist {1} / mustBeDisabled {2} / mustNotExist {3}{4}）" -f $ExpectedIdsFile, $wlExist.Count, $wlDisabled.Count, $wlNotExist.Count, $wlVer)
            $whitelistOk = $true
        } catch {
            Add-Row '白名单文件' 'FAIL' ("无法解析 {0}：{1}" -f $ExpectedIdsFile, $_.Exception.Message)
        }
    }
    $allRequired = @(@($wlExist) + @($RequiredIds) | Where-Object { $_ } | Select-Object -Unique)
    $allDisabled = @(@($wlDisabled) + @($MustBeDisabled) | Where-Object { $_ } | Select-Object -Unique)

    $profileFiles = @('package.json', 'pnpm-workspace.yaml', 'cordis.patch.yml')
    $missingFiles = @()
    foreach ($f in $profileFiles) {
        if (-not (Test-Path -LiteralPath (Join-Path $profilePath $f) -PathType Leaf)) { $missingFiles += $f }
    }
    if ($missingFiles.Count -gt 0) {
        Add-Row 'profile 配置文件' 'FAIL' ("缺少：" + ($missingFiles -join ', '))
    } else {
        Add-Row 'profile 配置文件' 'PASS' ($profileFiles -join ', ')
    }
    if (Test-Path -LiteralPath (Join-Path $profilePath 'pnpm-lock.yaml') -PathType Leaf) {
        Add-Row 'pnpm-lock.yaml' 'PASS' '存在'
    } else {
        Add-Row 'pnpm-lock.yaml' 'WARN' '不存在（尚未 pnpm install？）'
    }

    $nodeExe = $null
    $nodeCmd = Get-Command node -ErrorAction SilentlyContinue
    if ($null -eq $nodeCmd) {
        Add-Row 'node' 'FAIL' '未找到 node（请安装 Node.js 并重开终端）'
    } else {
        $nodeExe = $nodeCmd.Source
        $nodeVersion = (& $nodeExe --version 2>&1 | Out-String).Trim()
        if ($nodeVersion -match '^v(\d+)\.') {
            $nodeMajor = [int]$matches[1]
            if ($nodeMajor -lt 20) {
                Add-Row 'node 版本' 'FAIL' "$nodeVersion（需要 >= v20，推荐 v22/v24）"
            } elseif ($nodeMajor -lt 22) {
                Add-Row 'node 版本' 'WARN' "$nodeVersion（< v22，未在发布组合中验证）"
            } else {
                Add-Row 'node 版本' 'PASS' $nodeVersion
            }
        } else {
            Add-Row 'node 版本' 'WARN' "无法解析：$nodeVersion"
        }
    }

    $dshBinPath = $null
    $dshVersion = $null
    if ($null -ne $nodeExe) {
        try {
            $dshBinPath = Resolve-DshBinPath -HomeDir $DshHome -Explicit $DshBin
            $rawVersion = (& $nodeExe $dshBinPath --version 2>&1 | Out-String).Trim()
            $dshVersion = $rawVersion
            Add-Row 'dsh 入口' 'PASS' $dshBinPath
            if ($rawVersion -eq $ExpectedDshVersion) {
                Add-Row 'dsh 版本' 'PASS' $rawVersion
            } else {
                Add-Row 'dsh 版本' 'WARN' ("$rawVersion（验证基线 $ExpectedDshVersion；其他版本未测试）")
            }
        } catch {
            Add-Row 'dsh 入口' 'FAIL' $_.Exception.Message
        }
    }

    $linkDeps = @(Get-LinkDependencies -PackageJsonPath (Join-Path $profilePath 'package.json'))
    $brokenLinks = @($linkDeps | Where-Object { -not $_.Exists })
    if ($brokenLinks.Count -gt 0) {
        $detail = ($brokenLinks | ForEach-Object { "$($_.Package) -> $($_.Target)" }) -join '; '
        Add-Row 'link: 依赖' 'FAIL' ("本机不存在：" + $detail)
    } elseif ($linkDeps.Count -gt 0) {
        Add-Row 'link: 依赖' 'PASS' ("$($linkDeps.Count) 个，均存在")
    } else {
        Add-Row 'link: 依赖' 'PASS' '无'
    }

    $dumpOk = $false
    if ($null -ne $dshBinPath -and $null -ne $nodeExe) {
        $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ('dsh-verify-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
        New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
        $outFile = Join-Path $tempDir 'dump-config.txt'
        $errFile = Join-Path $tempDir 'dump-config.err'

        $env:DSH_HOME = $DshHome
        $argString = '"{0}" --profile "{1}" --dump-config' -f $dshBinPath, $ProfileName

        # 用 .NET Process 而不是 Start-Process：PS 5.1 的 Start-Process 在环境里同时存在
        # NO_PROXY/no_proxy 这类仅大小写不同的变量时会抛 ArgumentException（关键字重复）。
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = $nodeExe
        $psi.Arguments = $argString
        $psi.WorkingDirectory = $profilePath
        $psi.UseShellExecute = $false
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError = $true
        $psi.CreateNoWindow = $true

        $proc = New-Object System.Diagnostics.Process
        $proc.StartInfo = $psi
        [void]$proc.Start()
        $stdoutTask = $proc.StandardOutput.ReadToEndAsync()
        $stderrTask = $proc.StandardError.ReadToEndAsync()

        $finished = $proc.WaitForExit($TimeoutSeconds * 1000)
        if (-not $finished) {
            try { $proc.Kill() } catch { }
            Add-Row '--dump-config' 'FAIL' ("超时（{0}s）" -f $TimeoutSeconds)
        } else {
            $stdout = $stdoutTask.Result
            $stderr = $stderrTask.Result
            [System.IO.File]::WriteAllText($outFile, $stdout, (New-Object System.Text.UTF8Encoding($false)))
            [System.IO.File]::WriteAllText($errFile, $stderr, (New-Object System.Text.UTF8Encoding($false)))
            if ($proc.ExitCode -ne 0) {
                Add-Row '--dump-config' 'FAIL' ("退出码 {0}，见 {1}" -f $proc.ExitCode, $errFile)
            } else {
                Add-Row '--dump-config' 'PASS' ("退出码 0，输出 {0}" -f $outFile)
                $dumpOk = $true
            }
        }

        if (-not (Test-Path -LiteralPath $outFile -PathType Leaf)) {
            Add-Row '--dump-config 输出' 'FAIL' '未生成输出文件'
            $dumpOk = $false
        }

        if ($dumpOk) {
            $dumpText = [System.IO.File]::ReadAllText($outFile, [System.Text.Encoding]::UTF8)
            $lines = $dumpText -split "\r?\n"

            $ids = New-Object System.Collections.ArrayList
            foreach ($m in [regex]::Matches($dumpText, '(?m)^- id:[ \t]*(?<id>[^\r\n]+?)[ \t]*$')) {
                [void]$ids.Add($m.Groups['id'].Value.Trim().Trim([char[]]@("'", '"')))
            }

            Add-Row '顶层 entry 数' 'INFO' "$($ids.Count)（仅供参考，不判定）"

            $dupGroups = @($ids | Group-Object | Where-Object { $_.Count -gt 1 })
            if ($dupGroups.Count -eq 0) {
                Add-Row '顶层 id 重复' 'PASS' '0'
            } else {
                $detail = ($dupGroups | ForEach-Object { "$($_.Name)×$($_.Count)" }) -join ', '
                Add-Row '顶层 id 重复' 'FAIL' ("$($dupGroups.Count) 个 id 重复：" + $detail)
            }

            $idSet = New-Object 'System.Collections.Generic.HashSet[string]'
            foreach ($id in $ids) { [void]$idSet.Add($id) }

            $missingRequired = @()
            foreach ($required in $allRequired) {
                if (-not $idSet.Contains($required)) { $missingRequired += $required }
            }
            if ($allRequired.Count -eq 0) {
                Add-Row 'mustExist' 'FAIL' '白名单为空或未加载'
            } elseif ($missingRequired.Count -eq 0) {
                Add-Row 'mustExist' 'PASS' ("$($allRequired.Count) 个均在")
            } else {
                Add-Row 'mustExist' 'FAIL' ("缺少 $($missingRequired.Count) 个：" + ($missingRequired -join ', '))
            }

            $presentForbidden = @()
            foreach ($nx in $wlNotExist) {
                if ($idSet.Contains($nx)) { $presentForbidden += $nx }
            }
            if ($presentForbidden.Count -eq 0) {
                Add-Row 'mustNotExist' 'PASS' ("$($wlNotExist.Count) 个均不存在")
            } else {
                Add-Row 'mustNotExist' 'FAIL' ("不应存在：" + ($presentForbidden -join ', '))
            }

            foreach ($target in $allDisabled) {
                $state = Get-EntryDisabledValue -Lines $lines -TargetId $target
                if (-not $state.Found) {
                    Add-Row "禁用：$target" 'FAIL' '该 id 不存在'
                } elseif ($null -eq $state.Value) {
                    Add-Row "禁用：$target" 'FAIL' '没有 disabled 字段（视为启用）；运行 harden.ps1 -Apply'
                } elseif ($state.Value -eq 'true') {
                    Add-Row "禁用：$target" 'PASS' 'disabled: true'
                } elseif ($state.Value -eq 'false') {
                    Add-Row "禁用：$target" 'FAIL' 'disabled: false；运行 harden.ps1 -Apply'
                } else {
                    Add-Row "禁用：$target" 'WARN' "disabled 为表达式，无法静态判定：$($state.Value)"
                }
            }

            $errText = ''
            if (Test-Path -LiteralPath $errFile -PathType Leaf) {
                $errText = [System.IO.File]::ReadAllText($errFile, [System.Text.Encoding]::UTF8)
            }
            $errText = $errText.Trim()

            $forbiddenHits = @()
            if ($errText.Length -gt 0) {
                foreach ($pattern in $ForbiddenStderr) {
                    # PowerShell 的 -match 默认不区分大小写
                    if ($errText -match [regex]::Escape($pattern)) {
                        $forbiddenHits += $pattern
                    }
                }
            }

            if ($forbiddenHits.Count -eq 0) {
                Add-Row 'stderr 致命模式' 'PASS' '无'
            } else {
                $hint = ($errText -split "\r?\n" | Select-Object -First 3) -join ' | '
                Add-Row 'stderr 致命模式' 'FAIL' ("命中：" + ($forbiddenHits -join ', ') + "；$hint")
            }

            if ($errText.Length -gt 0) {
                $errLines = @($errText -split "\r?\n" | Where-Object { $_.Trim().Length -gt 0 })
                Add-Row 'stderr 其他告警' 'WARN' ("$($errLines.Count) 行，首行：" + $errLines[0])
            } else {
                Add-Row 'stderr 其他告警' 'PASS' 'stderr 为空'
            }

            Write-Host "  证据保留：$tempDir" -ForegroundColor DarkGray
        }
    } elseif ($null -eq $nodeExe) {
        Add-Row '--dump-config' 'FAIL' '缺少 node，无法渲染'
    }

    $failCount = @($script:Rows | Where-Object { $_.Result -eq 'FAIL' }).Count
    $passCount = @($script:Rows | Where-Object { $_.Result -eq 'PASS' }).Count
    $warnCount = @($script:Rows | Where-Object { $_.Result -eq 'WARN' }).Count

    Write-Table
    if ($failCount -eq 0) {
        Write-Host "  结论：PASS（$passCount 通过，$warnCount 告警）" -ForegroundColor Green
        $exitCode = 0
    } else {
        Write-Host "  结论：FAIL（$failCount 项失败，$passCount 通过，$warnCount 告警）" -ForegroundColor Red
        $exitCode = 1
    }
} catch {
    Add-Row '执行' 'FAIL' $_.Exception.Message
    Write-Table
    Write-Host "  结论：FAIL（异常中止）" -ForegroundColor Red
    $exitCode = 2
} finally {
    if ($null -eq $oldHome) {
        Remove-Item Env:\DSH_HOME -ErrorAction SilentlyContinue
    } else {
        $env:DSH_HOME = $oldHome
    }
}

exit $exitCode
