# 技能安装包（install-only）

这里**不包含技能本身**，只有一份清单、一个安装脚本和这份说明。

技能由脚本从各自的上游仓库拉取，装到本机 `$env:DSH_HOME\skills\<name>`。

---

## 1. 为什么不在仓库里放技能

46 个技能合计 **45,931,268 字节（43.80 MiB）/ 13,472 个文件**。分布极不均匀：

| 技能 | 体积 | 占比 |
| --- | ---: | ---: |
| `ppt-master` | 38.2 MB / 13,055 文件 | 87.1% |
| `diagram-design` | 5.2 MB / 290 文件 | 11.8% |
| 其余 44 个 | 合计约 0.5 MB | 1.1% |

把 43.8 MB 塞进仓库的代价：

- 每次 `clone` / `fetch` 都要为 13k 个文件买单，而其中 99.9% 的字节来自两个技能；
- 13,055 个文件对文件监听、索引、杀毒扫描都是负担；
- 内容会与上游**静默分叉**——仓库里的副本会过期，而 MIT 要求保留版权声明，过期副本更容易把归属和版本搞错；
- 这些内容本来就是公开的 MIT 项目，重新分发一份副本没有收益，只有同步成本。

**所以：只放"怎么装"，不放"装什么"。** 仓库体积保持在 KB 级。

---

## 2. 上游清单

| 来源 | 技能数 | 仓库 | 许可 | 版权人 |
| --- | ---: | --- | --- | --- |
| `mattpocock/skills` | 39 | <https://github.com/mattpocock/skills> | MIT | Copyright (c) 2026 Matt Pocock |
| `morluto/rea`（npm `rea-agents@6.8.0`） | 5 | <https://github.com/morluto/rea> | MIT | morluto（以仓库 LICENSE 原文为准） |
| `hugohe3/ppt-master` | 1 | <https://github.com/hugohe3/ppt-master> | MIT | Copyright (c) 2025-2026 Hugo He |
| **未知** | 1 | — | 仅 frontmatter 自称 MIT | **未知** |

### 2.1 mattpocock 系的三个子集

脚本不写死路径，而是在克隆下来的树里按目录名 + frontmatter `name` 双重索引定位。上游布局是：

- 正式技能：`skills/<name>/SKILL.md`
- Beta 技能：`skills/in-progress/<name>/SKILL.md`

Beta 的 7 个（`claude-handoff`、`loop-me`、`setup-ts-deep-modules`、`software-factory`、`writing-beats`、`writing-fragments`、`writing-shape`）在上游主 README 里没有，只出现在 `skills/in-progress/README.md`——**这是官方 Beta 通道，不是来源可疑**。

### 2.2 `ppt-master` 的特殊性

它是唯一自带 `LICENSE` 的技能，也是最脆弱的：

- `SKILL.md` frontmatter 把 `copyright` / `license` / `official_repository` 三行**逐字钉死**；
- `scripts/attribution_guard.py` 校验这三行、`LICENSE` 的 SHA-256，以及 `LICENSE` / `SPONSORS.md` / `SPONSORS_CN.md` 三个文件是否存在；
- 校验失败直接中止技能加载。

**所以：不要格式化它的 YAML，不要删那三个文件。** 脚本只做整目录复制，不碰内容。

另外 `templates/icons/` 下 1,696 个 SVG 图标（CHUNK Icons 641 个、Tabler Icons 1,055 个）**不在 MIT 覆盖范围内**，各自的商标与许可见 `templates/icons/THIRD_PARTY_NOTICES.md`。

### 2.3 `pr` 的第三方内容

`pr/CREDITS.md` 说明：其 Summary 段落的视觉菜单来自 Dex Horthy 的 `show-me`（HumanLayer，MIT），**近乎逐字复制**。这是第三个独立版权人。

**再分发时不能删 `pr/CREDITS.md`。**

---

## 3. 许可归属

四个来源全部 MIT，可自由使用、修改、再分发、商用。MIT 唯一的硬性义务是保留版权声明与许可文本。

| 版权人 | 覆盖范围 | 声明位置 |
| --- | --- | --- |
| Copyright (c) 2026 Matt Pocock | 39 个技能 | 上游 `LICENSE` |
| morluto（REA） | 5 个技能 | 上游仓库 `LICENSE` |
| Copyright (c) 2025-2026 Hugo He | `ppt-master` | 技能自带 `LICENSE` |
| Copyright (c) 2026 HumanLayer | `pr` 内嵌内容 | `pr/CREDITS.md` |
| **未知** | `diagram-design` | **无** |

### 3.1 `diagram-design`：版权人未知，默认不装

- frontmatter 声明 `license: MIT`、`metadata.version: "2.6"`；
- **目录内没有 LICENSE 文件**，没有 copyright 行，没有 `official_repository` 字段；
- 第三方镜像以 `cathrynlavery` 署名，但无法定位到可核验的原始仓库；
- 5.2 MB / 290 文件，含 6 个 Python 脚本。

MIT 要求"保留版权声明"，而这里**连版权人是谁都不知道**，无法履行该义务。因此：

> **状态 `skip`，脚本永不安装，并打印原因。** 在补齐版权人之前，这份内容不应再分发。

### 3.2 商标提醒

`ask-matt`、`setup-matt-pocock-skills` 直接使用 "Matt Pocock" 的名字。MIT **不授予商标权**。对外描述时请用中性措辞（例如 "community snapshot of mattpocock/skills"），不要暗示官方背书。

---

## 4. 安装

### 4.1 前置条件

| 依赖 | 用途 | 缺失时 |
| --- | --- | --- |
| PowerShell 5.1+ | 运行脚本 | 必须 |
| `git` | 克隆上游 | 自动回退到 zip 下载 |
| `npm` + `tar` | `rea-agents` 的首选取法 | 自动回退到 git |
| 联网 | 拉取上游 | 必须 |

脚本只用 Windows 自带组件和上述 CLI，**不装任何东西**。

### 4.2 最小用法

```powershell
# 先看计划，不联网、不写盘
.\install-skills.ps1 -DshHome $env:DSH_HOME -DryRun

# 装默认集合（40 个 known-good）
.\install-skills.ps1 -DshHome $env:DSH_HOME
```

`-DshHome` 省略时读取环境变量 `DSH_HOME`；两者都没有则报错退出。

### 4.3 参数

| 参数 | 作用 |
| --- | --- |
| `-DshHome <path>` | DSH 主目录，技能装到 `<path>\skills\<name>` |
| `-Only a,b,c` | 只装这些技能；未知名字会在动手前中止 |
| `-DryRun` | 只打印计划，不联网、不写盘 |
| `-Force` | 已存在的技能先备份为 `<name>.bak-<yyyyMMdd-HHmmss>` 再替换 |
| `-SkipUnverified` | 默认 `$true`，跳过未验证上游 |
| `-IncludeUnverified` | 等价于 `-SkipUnverified:$false`，**推荐用这个**（见下） |
| `-Manifest <path>` | 指定清单，默认取脚本同目录的 `skills.manifest.json` |
| `-CacheDir <path>` | 上游检出缓存目录，默认在系统临时目录下 |

> **为什么有两个开关**：`-Switch:$false` 这种写法只有在 PowerShell 内部调用时才解析；如果用 `powershell.exe -File install-skills.ps1 ...` 启动，冒号语法不会被识别，会报参数绑定错误。`-IncludeUnverified` 在两种调用方式下都能用，所以文档一律推荐它。

### 4.4 只装一部分

```powershell
# 只要三个
.\install-skills.ps1 -Only tdd,code-review,pr

# 只要轻量的（跳过 38 MB 的 ppt-master）
.\install-skills.ps1 -Only code-review,codebase-design,tdd,grilling

# 想连未验证的 5 个一起装
.\install-skills.ps1 -IncludeUnverified
```

### 4.5 默认会跳过什么

默认（`-SkipUnverified` 为真）**只装 40 个 known-good**，跳过 6 个：

| 技能 | 原因 |
| --- | --- |
| `diagram-design` | 版权人未知，无上游，`status: skip`，**任何参数下都不装** |
| `chief-of-staff` | 不在上游权威清单里，仅凭内部引用推定 |
| `git-guardrails-claude-code` | 同上，仅凭风格推定 |
| `migrate-to-shoehorn` | 同上，仅凭生态关联推定 |
| `scaffold-exercises` | 同上 |
| `setup-pre-commit` | 同上 |

后 5 个是"推定 mattpocock、待上游确认"，`status: unverified`。它们大概率能装成功（脚本会去上游找），但**默认不装**，因为无法证明其归属。确认无误后再加 `-IncludeUnverified`。

---

## 5. 已存在怎么办

**默认不覆盖。** 目标目录已存在时，脚本原样保留并打印 `already installed - left untouched`。

只有显式 `-Force` 才会替换，且顺序是：

1. 现有目录重命名为 `<name>.bak-<时间戳>`（同秒冲突自动加 `-1`、`-2`）；
2. 再从上游复制新的；
3. 校验新目录。

**备份不会被自动删除**，确认无误后自行清理。

如果目标位置是个 junction / 符号链接，脚本会照常移动它（移动链接不碰目标内容）并给出提示。

---

## 6. 安装后校验

脚本对**每一个**装好的目录做三项检查：

| 检查 | 失败表现 |
| --- | --- |
| 目录里有 `SKILL.md` | `FAILED: SKILL.md missing` |
| frontmatter 闭合且含 `name` | `FAILED: frontmatter` |
| `name` 与 `description` 非空 | `FAILED: name/description` |

有失败项时退出码为 `1`；全部成功为 `0`；参数错误为 `2`。

### 6.1 YAML 的 `: ` 坑

这是写技能时最常见、也最隐蔽的一个错误：

```yaml
# 错误：YAML 只保留冒号前的内容，"second sentence" 整段丢失
description: First sentence: second sentence
```

解析器不会报错，`description` 会静默变成 `First sentence`，技能的描述就这样被截断了。

正确写法——**整个值加双引号**：

```yaml
description: "First sentence: second sentence"
```

同理，未加引号的 ` #` 会被当成注释开头，后面全部丢弃。

脚本在检测到未加引号的 `: ` 或 ` #` 时会打印 `YAML PITFALL:` 提示，并给出加引号的示例。

---

## 7. 卸载

**原则：只删你自己装的那些，且先备份。**

### 7.1 先确认哪些是脚本装的

脚本装出来的目录与清单里的 46 个名字一一对应，且都不带 `.bak-` 后缀。带 `.bak-` 的是历史备份，不要动。

### 7.2 备份后删除

```powershell
$skills = Join-Path $env:DSH_HOME 'skills'
$stamp  = Get-Date -Format 'yyyyMMdd-HHmmss'

# 以单个技能为例：先备份，再删
$name = 'tdd'
Copy-Item -LiteralPath (Join-Path $skills $name) -Destination (Join-Path $skills "$name.bak-$stamp") -Recurse
Remove-Item -LiteralPath (Join-Path $skills $name) -Recurse -Force
```

### 7.3 批量卸载

```powershell
$skills = Join-Path $env:DSH_HOME 'skills'
$stamp  = Get-Date -Format 'yyyyMMdd-HHmmss'
$names  = @('tdd','code-review','pr','wizard')

foreach ($n in $names) {
    $src = Join-Path $skills $n
    if (-not (Test-Path -LiteralPath $src)) { continue }
    if ((Get-Item -LiteralPath $src -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) {
        Write-Warning "$n is a link; remove it with Remove-Item, its target is left alone"
        continue
    }
    Copy-Item -LiteralPath $src -Destination (Join-Path $skills "$n.bak-$stamp") -Recurse
    Remove-Item -LiteralPath $src -Recurse -Force
}
```

### 7.4 回滚

把 `.bak-<时间戳>` 改名回原名即可：

```powershell
Move-Item -LiteralPath (Join-Path $skills 'tdd.bak-20261105-120000') -Destination (Join-Path $skills 'tdd')
```

### 7.5 不要做的事

- **不要**整个删掉 `skills` 目录——里面可能有你手工放进去的技能；
- **不要**删 `ppt-master` 里的 `LICENSE` / `SPONSORS.md` / `SPONSORS_CN.md`，那会让技能直接罢工；
- **不要**删 `pr/CREDITS.md`，那是 HumanLayer 的署名；
- **不要**在没有备份的情况下对已存在的技能用 `-Force`（虽然脚本会备份，但多一层保险不亏）。

---

## 8. 关于 `.agents\skills` 的 junction

有些环境会把 `~/.agents/skills/<name>` 做成指向 `<DSH_HOME>\skills\<name>` 的 junction，让别的 agent 也能发现同一个技能。

- junction 指向的是**路径**，不是内容，所以重装后它仍然解析到新内容，**不需要重建**；
- 只有当技能换了位置，才需要删除链接后重建（`New-Item -ItemType Junction`）；
- 脚本在结束时若发现 `%USERPROFILE%\.agents\skills` 下有 reparse point，会**只读列出**它们的指向，不做任何修改。

注意：`~/.agents/skills` 本身通常是**真实目录**（不是链接），只有它下面的个别子项是 junction。按"整个目录是链接"处理会漏拷。

---

## 9. 文件说明

| 文件 | 作用 |
| --- | --- |
| `install-skills.ps1` | 安装器。纯 ASCII，避免中文在 Windows PowerShell 5.1 下的编码问题 |
| `skills.manifest.json` | 46 个技能的清单：名字 / 来源 / 许可 / 体积 / 隐藏 / 脚本 / 状态 |
| `README.md` | 本文件 |

### 9.1 清单字段

| 字段 | 含义 |
| --- | --- |
| `name` | 技能目录名 |
| `source` | 上游来源标识，对应 `sources` 里的键 |
| `license` | 许可标识 |
| `size` / `sizeBytes` | 人类可读体积 / 精确字节数（安装后按实际复制结果复核） |
| `hidden` | frontmatter 是否含 `disable-model-invocation: true`（24 个为真，必须原样保留） |
| `hasScripts` | 是否带可执行资产（`scripts/` 目录，或根目录下的 `*.sh`，如 `wizard/template.sh`） |
| `status` | `known-good` / `unverified` / `skip` |
| `notes` / `statusReason` | 附加说明 |

### 9.2 关于 `hidden`

24 个技能带 `disable-model-invocation: true`，含义是**模型不能自动调用，只能由用户显式触发**。

脚本不修改 frontmatter，只在安装后读取该字段并与清单比对；不一致会打印 `hidden flag mismatch`。这是上游打包器的指纹，动了它等于改变技能的可调用性。
