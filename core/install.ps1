<#
.SYNOPSIS
  把「整机镜像」profile 安装到本机的 DSH_HOME 下，并自动验证。

.DESCRIPTION
  非交互安装脚本，按 5 步执行，任一步失败即停止并打印回滚命令：
    1) 环境检查：node / pnpm / dsh 版本、模板完整性、link: 依赖、DSH 是否仍在运行
    2) 备份现有 profile 配置到 <profile>\.backup-install-<时间戳>\
    3) 从 profile-template\ 复制 package.json / pnpm-workspace.yaml / cordis.patch.yml
       （模板若带 pnpm-lock.yaml、cordis.yml 也一并复制）
    4) pnpm install（可选 --frozen-lockfile）
    5) 调用 verify.ps1 输出 PASS/FAIL 表

  不会删除任何文件，不会碰 sessions / storages / attachments / usage / archive 等运行数据，
  也不需要管理员权限。

.PARAMETER DshHome
  DSH_HOME 目录（其下应有 profiles\<ProfileName>）。
  默认取 $env:DSH_HOME，其次 $env:USERPROFILE\.dsh。
  独立 WebUI 版通常传 "<安装根>\home"。

.PARAMETER ProfileName
  profile 名，默认 web。

.PARAMETER DryRun
  只做只读检查并打印将执行的动作，不写文件、不装依赖、不验证。

.PARAMETER SkipPnpm
  跳过 pnpm install（已装过依赖，或想手动装）。

.PARAMETER DshBin
  dsh 的 lib\bin.js 路径，或 DSH 安装根。省略时先看 $env:DSH_BIN，再自动探测
  （<DSH_HOME> 的上一级安装根、%APPDATA%\npm 全局包）。

.PARAMETER TemplateDir
  模板目录，默认脚本同级的 profile-template\。

.PARAMETER FrozenLockfile
  pnpm install 加 --frozen-lockfile（lockfile 与 package.json 不一致时直接失败）。
  要求模板带 pnpm-lock.yaml；模板不带时指定该开关会直接失败。

.PARAMETER ExpectedDshVersion
  期望的 dsh 版本，默认 0.2.1-rc.5。不一致只告警，除非同时给 -StrictVersion。

.PARAMETER StrictVersion
  dsh 版本不等于 -ExpectedDshVersion 时直接失败。

.PARAMETER AllowLocalLinks
  允许 package.json 里的 link: 依赖指向本机不存在的目录（默认视为发布阻断并失败）。

.EXAMPLE
  powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1 `
      -DshHome "<DSH安装根>\home" -DryRun

.EXAMPLE
  powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1 `
      -DshHome "<DSH安装根>\home"
#>
[CmdletBinding()]
param(
    [string]$DshHome = $env:DSH_HOME,
    [string]$ProfileName = 'web',
    [switch]$DryRun,
    [switch]$SkipPnpm,
    [string]$DshBin = '',
    [string]$TemplateDir = '',
    [switch]$FrozenLockfile,
    [string]$ExpectedDshVersion = '0.2.1-rc.5',
    [switch]$StrictVersion,
    [switch]$AllowLocalLinks,
    [int]$TimeoutSeconds = 120
)

$ErrorActionPreference = 'Stop'

# 输出固定为 UTF-8：agent 用管道抓取时不依赖控制台代码页（cp936 会糊掉中文）
try { [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false) } catch { }

# ---------------------------------------------------------------- 输出与状态

$script:Step = 0
$script:StepName = '初始化'
$script:ProfilePath = $null
$script:BackupDir = $null
$script:ProfileCreated = $false

function Write-Step {
    param([string]$Name)
    $script:Step += 1
    $script:StepName = $Name
    Write-Host ''
    Write-Host ("  [{0}/5] {1}" -f $script:Step, $Name) -ForegroundColor Cyan
}

function Write-Ok {
    param([string]$Message)
    Write-Host ("        OK  {0}" -f $Message) -ForegroundColor Green
}

function Write-Info {
    param([string]$Message)
    Write-Host ("        ..  {0}" -f $Message) -ForegroundColor Gray
}

function Write-Warn {
    param([string]$Message)
    Write-Host ("        !   {0}" -f $Message) -ForegroundColor Yellow
}

function Fail {
    param([string]$Message)
    throw $Message
}

# ---------------------------------------------------------------- 工具函数

function Resolve-DshBinPath {
    param([string]$HomeDir, [string]$Explicit)

    if (-not [string]::IsNullOrWhiteSpace($Explicit)) {
        $candidate = $Explicit
        if (Test-Path -LiteralPath $candidate -PathType Container) {
            $candidate = Join-Path $candidate 'node_modules\@deepseek-ai\dsh\lib\bin.js'
        }
        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
            return (Resolve-Path -LiteralPath $candidate).Path
        }
        Fail "-DshBin 指向的路径不存在：$Explicit"
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

    Fail ("找不到 dsh 的 lib\bin.js。请用 -DshBin 指向它。已尝试：{0}" -f ($candidates -join '; '))
}

function Get-LinkDependencies {
    param([string]$PackageJsonPath, [string]$BaseDir)

    $result = New-Object System.Collections.ArrayList
    if (-not (Test-Path -LiteralPath $PackageJsonPath)) { return $result }

    $raw = [System.IO.File]::ReadAllText($PackageJsonPath)
    try {
        $pkg = $raw | ConvertFrom-Json
    } catch {
        Fail ("package.json 不是合法 JSON：$PackageJsonPath`n{0}" -f $_.Exception.Message)
    }

    if ($null -eq $pkg.dependencies) { return $result }
    foreach ($prop in $pkg.dependencies.PSObject.Properties) {
        $spec = [string]$prop.Value
        if ($spec -notmatch '^link:(.+)$') { continue }
        $target = $matches[1]
        if (-not [System.IO.Path]::IsPathRooted($target)) {
            $target = Join-Path $BaseDir $target
        }
        [void]$result.Add([pscustomobject]@{
            Package = $prop.Name
            Target  = $target
            Exists  = (Test-Path -LiteralPath $target)
        })
    }
    return $result
}

function Write-RollbackScript {
    param([string]$BackupDir, [string]$ProfilePath, [string[]]$Files)

    $eol = "`r`n"
    $lines = New-Object System.Collections.ArrayList
    [void]$lines.Add('<#')
    [void]$lines.Add('  install.ps1 自动生成的回滚脚本')
    [void]$lines.Add(("  生成时间：{0}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')))
    [void]$lines.Add('  作用：把 profile 配置恢复到本次安装之前（不含 node_modules）。')
    [void]$lines.Add('  用法：powershell -NoProfile -ExecutionPolicy Bypass -File .\rollback.ps1')
    [void]$lines.Add('#>')
    [void]$lines.Add('$ErrorActionPreference = ''Stop''')
    [void]$lines.Add('')
    foreach ($file in $Files) {
        $src = (Join-Path $BackupDir $file).Replace("'", "''")
        $dst = $ProfilePath.Replace("'", "''")
        [void]$lines.Add(("Copy-Item -LiteralPath '{0}' -Destination '{1}' -Force" -f $src, $dst))
    }
    [void]$lines.Add('')
    [void]$lines.Add('Write-Host ''已恢复安装前的 profile 配置。''')
    [void]$lines.Add('Write-Host ''如依赖也已变化，请再执行：pnpm install --frozen-lockfile''')

    $path = Join-Path $BackupDir 'rollback.ps1'
    [System.IO.File]::WriteAllText($path, (($lines -join $eol) + $eol), (New-Object System.Text.UTF8Encoding($true)))
    return $path
}

function Find-RunningDshProcesses {
    try {
        $procs = Get-CimInstance -ClassName Win32_Process -Filter "Name = 'node.exe'" -ErrorAction SilentlyContinue |
            Where-Object { $_.CommandLine -and $_.CommandLine -like '*@deepseek-ai*dsh*bin.js*' }
        return @($procs)
    } catch {
        return @()
    }
}

# ---------------------------------------------------------------- 主流程

Write-Host ''
Write-Host '  DSH profile 安装器' -ForegroundColor Cyan

try {
    # ---------- 归一化参数 ----------
    if ([string]::IsNullOrWhiteSpace($DshHome)) {
        $DshHome = Join-Path $env:USERPROFILE '.dsh'
    }
    $DshHome = [System.IO.Path]::GetFullPath($DshHome)

    if ([string]::IsNullOrWhiteSpace($TemplateDir)) {
        $TemplateDir = Join-Path $PSScriptRoot 'profile-template'
    }
    $TemplateDir = [System.IO.Path]::GetFullPath($TemplateDir)

    $script:ProfilePath = Join-Path $DshHome ('profiles\' + $ProfileName)
    $profilePath = $script:ProfilePath

    # 模板必需三件；pnpm-lock.yaml 可选（模板不带时由 pnpm install 生成）
    $profileFiles = @('package.json', 'pnpm-workspace.yaml', 'cordis.patch.yml')
    $copyFiles = @('package.json', 'pnpm-workspace.yaml', 'cordis.patch.yml')
    $optionalFiles = @('pnpm-lock.yaml', 'cordis.yml')

    Write-Host ("  DSH_HOME : {0}" -f $DshHome)
    Write-Host ("  profile  : {0}" -f $profilePath)
    Write-Host ("  模板     : {0}" -f $TemplateDir)
    if ($DryRun) { Write-Host '  模式     : DRY RUN（只检查，不修改）' -ForegroundColor Yellow }

    # ---------- 1. 环境检查 ----------
    Write-Step '环境检查'

    if (-not (Test-Path -LiteralPath $DshHome -PathType Container)) {
        Fail ("DSH_HOME 不存在：$DshHome`n如果这是独立 WebUI 版，请传 -DshHome '<安装根>\home'。")
    }
    Write-Ok "DSH_HOME 存在"

    $nodeCmd = Get-Command node -ErrorAction SilentlyContinue
    if ($null -eq $nodeCmd) {
        Fail '未找到 node。请先安装 Node.js（>= v20，推荐 v22/v24）并重新打开终端。'
    }
    $nodeExe = $nodeCmd.Source
    $nodeVersion = (& $nodeExe --version 2>&1 | Out-String).Trim()
    if ($nodeVersion -notmatch '^v(\d+)\.') {
        Write-Warn ("无法解析 node 版本：{0}" -f $nodeVersion)
    } else {
        $nodeMajor = [int]$matches[1]
        if ($nodeMajor -lt 20) {
            Fail ("node 版本过低：{0}（需要 >= v20）" -f $nodeVersion)
        } elseif ($nodeMajor -lt 22) {
            Write-Warn ("node {0} < v22，未在发布验证组合中测试过" -f $nodeVersion)
        } else {
            Write-Ok ("node {0}" -f $nodeVersion)
        }
    }

    $dshBinPath = Resolve-DshBinPath -HomeDir $DshHome -Explicit $DshBin
    $dshVersion = (& $nodeExe $dshBinPath --version 2>&1 | Out-String).Trim()
    if ([string]::IsNullOrWhiteSpace($dshVersion)) { $dshVersion = '未知' }
    if ($dshVersion -eq $ExpectedDshVersion) {
        Write-Ok ("dsh {0}" -f $dshVersion)
    } elseif ($StrictVersion) {
        Fail ("dsh 版本 {0} ≠ 期望 {1}（-StrictVersion 下视为失败）" -f $dshVersion, $ExpectedDshVersion)
    } else {
        Write-Warn ("dsh {0} ≠ 验证基线 {1}，其他版本行为未测试" -f $dshVersion, $ExpectedDshVersion)
    }
    Write-Info ("dsh 入口：{0}" -f $dshBinPath)

    $pnpmExe = $null
    if (-not $SkipPnpm) {
        $pnpmCmd = Get-Command pnpm -ErrorAction SilentlyContinue
        if ($null -eq $pnpmCmd) {
            Fail ("未找到 pnpm。请先安装：npm install -g pnpm@11.28.9（或 corepack enable），或加 -SkipPnpm 跳过依赖安装。")
        }
        $pnpmExe = $pnpmCmd.Source
        $pnpmVersion = (& $pnpmExe --version 2>&1 | Out-String).Trim()
        Write-Ok ("pnpm {0}" -f $pnpmVersion)
    } else {
        Write-Info '已指定 -SkipPnpm，跳过 pnpm 检查'
    }

    $templatePackageJson = Join-Path $TemplateDir 'package.json'
    if (-not (Test-Path -LiteralPath $TemplateDir -PathType Container)) {
        Fail ("模板目录不存在：$TemplateDir`n请确认发布包完整（profile-template\ 应与脚本同级）。")
    }
    $missingTemplate = @()
    foreach ($file in $profileFiles) {
        if (-not (Test-Path -LiteralPath (Join-Path $TemplateDir $file) -PathType Leaf)) {
            $missingTemplate += $file
        }
    }
    if ($missingTemplate.Count -gt 0) {
        Fail ("模板缺少文件：{0}`n模板目录：{1}" -f ($missingTemplate -join ', '), $TemplateDir)
    }
    $templateHasLock = Test-Path -LiteralPath (Join-Path $TemplateDir 'pnpm-lock.yaml') -PathType Leaf
    if ($templateHasLock) {
        Write-Ok '模板文件齐全（含 pnpm-lock.yaml）'
    } else {
        Write-Ok '模板文件齐全（不带 pnpm-lock.yaml，将由 pnpm install 解析生成）'
        if ($FrozenLockfile) {
            Fail '指定了 -FrozenLockfile，但模板没有 pnpm-lock.yaml。去掉 -FrozenLockfile 重试。'
        }
    }

    $templatePkg = [System.IO.File]::ReadAllText($templatePackageJson) | ConvertFrom-Json
    $bundles = @()
    if ($null -ne $templatePkg.dsh -and $null -ne $templatePkg.dsh.profile -and $null -ne $templatePkg.dsh.profile.bundles) {
        $bundles = @($templatePkg.dsh.profile.bundles)
    }
    if ($bundles.Count -eq 0) {
        Fail '模板 package.json 缺少 dsh.profile.bundles（或为空），dsh 不会加载任何 bundle。'
    }
    Write-Ok ("bundles {0} 个" -f $bundles.Count)
    if ($pnpmExe -and $templatePkg.packageManager -match 'pnpm@([0-9]+)') {
        $expectedPnpmMajor = [int]$matches[1]
        $actualPnpmMajor = $null
        if ($pnpmVersion -match '^(\d+)\.') { $actualPnpmMajor = [int]$matches[1] }
        if ($null -ne $actualPnpmMajor -and $actualPnpmMajor -ne $expectedPnpmMajor) {
            Write-Warn ("pnpm 主版本 {0} ≠ 模板 packageManager 要求的 {1}；若 lockfile 报错，请装 pnpm@{1}.x" -f $actualPnpmMajor, $expectedPnpmMajor)
        }
    }

    $linkDeps = @(Get-LinkDependencies -PackageJsonPath $templatePackageJson -BaseDir $profilePath)
    $brokenLinks = @($linkDeps | Where-Object { -not $_.Exists })
    if ($brokenLinks.Count -gt 0) {
        $detail = ($brokenLinks | ForEach-Object { "  {0} -> {1}" -f $_.Package, $_.Target }) -join "`n"
        if ($AllowLocalLinks) {
            Write-Warn ("有 {0} 个 link: 依赖在本机不存在（-AllowLocalLinks 已放行）：`n{1}" -f $brokenLinks.Count, $detail)
        } else {
            Fail ("模板里有 link: 依赖指向本机不存在的目录，pnpm install 会失败，镜像也不可移植：`n{0}`n处理：把该包发布成正常版本并改 package.json，或把目录一起放进发布包；确认无碍可加 -AllowLocalLinks。" -f $detail)
        }
    } elseif ($linkDeps.Count -gt 0) {
        Write-Ok ("link: 依赖 {0} 个，均存在" -f $linkDeps.Count)
    }

    $running = @(Find-RunningDshProcesses)
    if ($running.Count -gt 0) {
        $pids = ($running | ForEach-Object { $_.ProcessId }) -join ', '
        Write-Warn ("检测到 {0} 个 dsh 进程（PID {1}）可能正在使用该 profile；HMR 会在改动时即时重挂，建议先停止服务再安装。" -f $running.Count, $pids)
    }

    # ---------- DryRun 出口 ----------
    if ($DryRun) {
        $planTs = Get-Date -Format 'yyyyMMdd-HHmmss'
        Write-Host ''
        Write-Host '  [DRY RUN] 将执行：' -ForegroundColor Yellow
        if (Test-Path -LiteralPath $profilePath -PathType Container) {
            Write-Host ("    1) 备份现有配置 -> {0}" -f (Join-Path $profilePath ('.backup-install-' + $planTs)))
        } else {
            Write-Host ("    1) 新建 profile 目录 -> {0}（无旧配置可备份）" -f $profilePath)
        }
        $planCopy = @($copyFiles)
        foreach ($f in $optionalFiles) { if (Test-Path -LiteralPath (Join-Path $TemplateDir $f) -PathType Leaf) { $planCopy += $f } }
        Write-Host ("    2) 复制 {0} <- {1}" -f ($planCopy -join ', '), $TemplateDir)
        if ($SkipPnpm) {
            Write-Host '    3) 跳过 pnpm install（-SkipPnpm）'
        } else {
            $planArgs = 'install'
            if ($FrozenLockfile) { $planArgs = 'install --frozen-lockfile' }
            Write-Host ("    3) cd '{0}'; pnpm {1}" -f $profilePath, $planArgs)
        }
        Write-Host ("    4) powershell -File verify.ps1 -DshHome '{0}' -ProfileName {1}" -f $DshHome, $ProfileName)
        Write-Host ''
        Write-Host '  DRY RUN 结束：未做任何修改。' -ForegroundColor Green
        exit 0
    }

    # ---------- 2. 备份 ----------
    Write-Step '备份现有配置'

    if (Test-Path -LiteralPath $profilePath -PathType Container) {
        $existing = @()
        foreach ($file in ($profileFiles + $optionalFiles)) {
            if (Test-Path -LiteralPath (Join-Path $profilePath $file) -PathType Leaf) { $existing += $file }
        }

        if ($existing.Count -gt 0) {
            $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
            $script:BackupDir = Join-Path $profilePath ('.backup-install-' + $stamp)
            $n = 1
            while (Test-Path -LiteralPath $script:BackupDir) {
                $n += 1
                $script:BackupDir = Join-Path $profilePath ('.backup-install-' + $stamp + '-' + $n)
            }
            New-Item -ItemType Directory -Path $script:BackupDir -Force | Out-Null
            foreach ($file in $existing) {
                Copy-Item -LiteralPath (Join-Path $profilePath $file) -Destination (Join-Path $script:BackupDir $file) -Force
            }
            $rollback = Write-RollbackScript -BackupDir $script:BackupDir -ProfilePath $profilePath -Files $existing
            Write-Ok ("已备份 {0} 个文件 -> {1}" -f $existing.Count, $script:BackupDir)
            Write-Info ("回滚脚本：{0}" -f $rollback)
        } else {
            Write-Info 'profile 目录存在但没有配置文件（全新安装），跳过备份'
        }
    } else {
        Write-Info ("profile 目录不存在，将新建：{0}" -f $profilePath)
    }

    # ---------- 3. 复制模板 ----------
    Write-Step '复制 profile 模板'

    if (-not (Test-Path -LiteralPath $profilePath -PathType Container)) {
        New-Item -ItemType Directory -Path $profilePath -Force | Out-Null
        $script:ProfileCreated = $true
    }

    foreach ($file in $copyFiles) {
        Copy-Item -LiteralPath (Join-Path $TemplateDir $file) -Destination (Join-Path $profilePath $file) -Force
        Write-Ok ("{0}" -f $file)
    }
    foreach ($file in $optionalFiles) {
        $src = Join-Path $TemplateDir $file
        if (Test-Path -LiteralPath $src -PathType Leaf) {
            Copy-Item -LiteralPath $src -Destination (Join-Path $profilePath $file) -Force
            Write-Ok ("{0}（模板带）" -f $file)
        }
    }

    if (-not (Test-Path -LiteralPath (Join-Path $profilePath 'cordis.yml') -PathType Leaf)) {
        $cordis = "# dsh profile root — 空入口列表；实际树由 bundles + cordis.patch.yml 合成。`r`n[]`r`n"
        [System.IO.File]::WriteAllText((Join-Path $profilePath 'cordis.yml'), $cordis, (New-Object System.Text.UTF8Encoding($false)))
        Write-Info '已补建 cordis.yml（[]）'
    }

    # ---------- 4. pnpm install ----------
    Write-Step 'pnpm install'

    if ($SkipPnpm) {
        Write-Info '已跳过（-SkipPnpm）。请手动执行：'
        Write-Host ("        cd '{0}'; pnpm install" -f $profilePath) -ForegroundColor DarkGray
    } else {
        $pnpmArgs = @('install')
        if ($FrozenLockfile) { $pnpmArgs += '--frozen-lockfile' }
        $logPath = Join-Path ([System.IO.Path]::GetTempPath()) ('dsh-install-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '.log')
        Write-Info ("cd '{0}'" -f $profilePath)
        Write-Info ("pnpm {0}" -f ($pnpmArgs -join ' '))

        Push-Location -LiteralPath $profilePath
        try {
            $all = @(& $pnpmExe @pnpmArgs 2>&1 | ForEach-Object { $_.ToString() })
            $pnpmCode = $LASTEXITCODE
        } finally {
            Pop-Location
        }

        [System.IO.File]::WriteAllText($logPath, (($all -join "`r`n") + "`r`n"), (New-Object System.Text.UTF8Encoding($false)))
        foreach ($line in $all) { Write-Host ("        {0}" -f $line) -ForegroundColor DarkGray }

        if ($pnpmCode -ne 0) {
            $tail = @($all | Select-Object -Last 20)
            Write-Host ''
            Write-Host '  最近 20 行输出：' -ForegroundColor Yellow
            foreach ($line in $tail) { Write-Host ("        {0}" -f $line) -ForegroundColor DarkYellow }
            Fail ("pnpm install 失败（退出码 {0}）。完整日志：{1}" -f $pnpmCode, $logPath)
        }

        Write-Ok ("pnpm install 完成（日志：{0}）" -f $logPath)
        if (($all -join "`n") -match 'Ignored build scripts') {
            Write-Warn 'pnpm 跳过了部分依赖的构建脚本；若运行时报缺 .node，检查 pnpm-workspace.yaml 的 allowBuilds 并执行 pnpm approve-builds。'
        }
    }

    # ---------- 5. 验证 ----------
    Write-Step '验证'

    $verifyScript = Join-Path $PSScriptRoot 'verify.ps1'
    if (-not (Test-Path -LiteralPath $verifyScript -PathType Leaf)) {
        Fail ("找不到 verify.ps1：$verifyScript")
    }

    $hostExe = $null
    foreach ($name in @('powershell.exe', 'pwsh.exe')) {
        $candidate = Join-Path $PSHOME $name
        if (Test-Path -LiteralPath $candidate -PathType Leaf) { $hostExe = $candidate; break }
    }
    if ($null -eq $hostExe) {
        $pwshCmd = Get-Command pwsh -ErrorAction SilentlyContinue
        if ($null -ne $pwshCmd) { $hostExe = $pwshCmd.Source }
    }
    if ($null -eq $hostExe) { $hostExe = 'powershell.exe' }

    # 用独立进程调用，确保 verify 的 exit 不会结束本脚本
    $verifyArgs = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $verifyScript,
        '-DshHome', $DshHome, '-ProfileName', $ProfileName, '-ExpectedDshVersion', $ExpectedDshVersion,
        '-TimeoutSeconds', $TimeoutSeconds)
    if (-not [string]::IsNullOrWhiteSpace($DshBin)) {
        $verifyArgs += @('-DshBin', $DshBin)
    }

    & $hostExe @verifyArgs
    $verifyCode = $LASTEXITCODE
    if ($verifyCode -ne 0) {
        Fail ("验证未通过（verify.ps1 退出码 {0}）。若是两个远程插件未禁用，运行 harden.ps1 -Apply 后重试；其余见上表。" -f $verifyCode)
    }

    # ---------- 成功 ----------
    Write-Host ''
    Write-Host '  安装完成' -ForegroundColor Green
    Write-Host ("    profile : {0}" -f $profilePath)
    Write-Host ("    dsh     : {0}" -f $dshVersion)
    if ($null -ne $script:BackupDir) {
        Write-Host ("    备份    : {0}" -f $script:BackupDir)
        Write-Host ("    回滚    : powershell -NoProfile -ExecutionPolicy Bypass -File `"{0}\rollback.ps1`"" -f $script:BackupDir)
    }
    Write-Host ''
    Write-Host '  下一步：'
    Write-Host '    * 启动：运行安装根下的 start-webui.ps1（或你惯用的启动器）'
    Write-Host '    * 收紧：.\harden.ps1 -Apply（approval=ask 会阻塞无人值守 agent，确认有人在场再开）'
    Write-Host ''
    exit 0
} catch {
    Write-Host ''
    Write-Host ("  安装失败：步骤 {0}（{1}）" -f $script:Step, $script:StepName) -ForegroundColor Red
    Write-Host ("  原因：{0}" -f $_.Exception.Message) -ForegroundColor Red
    Write-Host ''
    if ($null -ne $script:BackupDir) {
        Write-Host '  回滚（推荐，恢复安装前的配置）：' -ForegroundColor Yellow
        Write-Host ("    powershell -NoProfile -ExecutionPolicy Bypass -File `"{0}\rollback.ps1`"" -f $script:BackupDir) -ForegroundColor Yellow
        Write-Host '  或手动：' -ForegroundColor Yellow
        Write-Host ("    Copy-Item -Path `"{0}\*`" -Destination `"{1}`" -Force" -f $script:BackupDir, $script:ProfilePath) -ForegroundColor Yellow
        Write-Host '  恢复后如依赖已变化，再执行：pnpm install --frozen-lockfile' -ForegroundColor Yellow
    } elseif ($script:ProfileCreated) {
        Write-Host ("  本次新建了 profile 目录 {0}；如需清理可手工删除该空目录（脚本不会自动删除）。" -f $script:ProfilePath) -ForegroundColor Yellow
    } else {
        Write-Host '  未修改 profile（失败发生在写入之前）。' -ForegroundColor Yellow
    }
    Write-Host ''
    exit 1
}
