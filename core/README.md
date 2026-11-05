# DSH profile 安装包 · core

把作者这台机器上的 DSH `web` profile（整机镜像形态）安装到另一台 Windows 机器上，
并验证、收紧。面向两类读者：**执行安装的 agent** 和**人类**。

- 发布形态：整机镜像 —— 朋友拿到的插件组合、UI、默认模型与作者本机一致；
  不是精选元包。
- 不锁死版本：只在 **DSH `0.2.1-rc.5` + 本文列出的版本组合**下验证过；
  其他版本可用，但标为「未测试」。
- **不含**凭据、会话、附件、用量数据。
- 技能（skills）**不随包复制**，由 `install.ps1` 之后的独立步骤安装（见 §7）。

```
core/
├─ install.ps1         # 安装（5 步，失败即停，自动生成回滚脚本）
├─ verify.ps1          # 验证（渲染合成树 + PASS/FAIL 表）
├─ harden.ps1          # 收紧/还原默认策略（-Apply / -Restore，幂等）
├─ menu.json           # 插件清单：default / optional / excluded，供 agent 读取
├─ README.md           # 本文件
└─ profile-template/   # 真实模板由发布流程填充；见其中的 README
```

---

## 1. 前置条件

| 项目 | 要求 | 说明 |
| --- | --- | --- |
| 系统 | Windows 10/11 | 脚本用 PowerShell 5.1 语法写成，pwsh 7 也能跑 |
| 权限 | **不需要管理员** | 全部写入都在用户可写目录；不写注册表、不装服务 |
| Node.js | `>= v20`，验证于 `v24.22.1` | 低于 v22 会告警 |
| pnpm | 建议与模板 `packageManager` 一致（`pnpm@11.28.9`） | 未装会失败；`-SkipPnpm` 可跳过 |
| DSH | `@deepseek-ai/dsh@0.2.1-rc.5` | 其他版本只告警，`-StrictVersion` 可改为失败 |
| DSH_HOME | 独立 WebUI 版通常是 `<安装根>\home` | 其下应有 `profiles\web`；非标准布局请同时给 `-DshBin` |

判断 DSH_HOME 的最快方式：启动器里设置 `$env:DSH_HOME` 的那一行；
独立 WebUI 版就是安装根下的 `home\`。桌面版默认是 `%USERPROFILE%\.dsh`。

---

## 2. 一条命令安装

```powershell
cd "<发布包>\core"
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1 `
  -DshHome "<DSH安装根>\home" -DryRun
```

先 `-DryRun` 看计划（只读、不写文件），确认后再去掉 `-DryRun` 执行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1 `
  -DshHome "<DSH安装根>\home"
```

模板不带 `pnpm-lock.yaml`，首次安装由 pnpm 解析依赖并生成；只有模板自带 lockfile 时 `-FrozenLockfile` 才可用。

### install.ps1 的 5 步

| 步骤 | 动作 | 失败时 |
| --- | --- | --- |
| 1 | 环境检查：node / pnpm / dsh 版本、模板文件（lockfile 可选）、`link:` 依赖、是否有 dsh 进程在跑 | 打印原因并停止，未改任何文件 |
| 2 | 备份现有 profile 的 `package.json`、`pnpm-lock.yaml`、`pnpm-workspace.yaml`、`cordis.patch.yml`（有 `cordis.yml` 也一起）到 `<profile>\.backup-install-<时间戳>\`，并生成 `rollback.ps1` | — |
| 3 | 从 `profile-template\` 复制 `package.json`、`pnpm-workspace.yaml`、`cordis.patch.yml`（模板带 `pnpm-lock.yaml` / `cordis.yml` 时一并复制）到 profile | 回滚命令已打印 |
| 4 | 在 profile 目录跑 `pnpm install`（`-FrozenLockfile` 时加 `--frozen-lockfile`），日志落到 `%TEMP%\dsh-install-*.log` | 打印末尾 20 行 + 日志路径 |
| 5 | 用独立进程调用 `verify.ps1`，失败即整体失败 | 打印具体 FAIL 项与处置建议 |

### 参数

| 参数 | 默认 | 说明 |
| --- | --- | --- |
| `-DshHome` | `$env:DSH_HOME` → `%USERPROFILE%\.dsh` | DSH_HOME 目录（其下有 `profiles\`） |
| `-ProfileName` | `web` | profile 名 |
| `-DryRun` | 关 | 只检查并打印计划，**不写文件、不装依赖、不验证** |
| `-SkipPnpm` | 关 | 跳过 `pnpm install` |
| `-DshBin` | 自动探测，其次 `$env:DSH_BIN` | dsh 的 `lib\bin.js`，或 DSH 安装根 |
| `-TemplateDir` | `.\profile-template` | 模板目录 |
| `-FrozenLockfile` | 关 | 严格按 lockfile 安装；模板不带 `pnpm-lock.yaml` 时会直接失败 |
| `-ExpectedDshVersion` | `0.2.1-rc.5` | 版本基线 |
| `-StrictVersion` | 关 | 版本不符直接失败 |
| `-AllowLocalLinks` | 关 | 放行指向本机不存在目录的 `link:` 依赖（默认视为发布阻断） |
| `-TimeoutSeconds` | `120` | verify 调用 dump-config 的超时 |

退出码：`0` 成功；`1` 失败（含验证不通过）。

---

## 3. 验证

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\verify.ps1 `
  -DshHome "<DSH安装根>\home" -ProfileName web
```

它实际执行 `node <dsh>\lib\bin.js --profile web --dump-config`，把合成树落到
`%TEMP%\dsh-verify-<时间戳>\dump-config.txt`（报告里会打印该路径），然后检查：

| 检查项 | 判定 |
| --- | --- |
| `--dump-config` | 退出码必须为 0；超时按失败 |
| 白名单文件 | 默认读 `..\reference\expected-ids.json`；缺失或解析失败即 FAIL |
| 顶层 id 重复 | 必须为 **0** |
| mustExist | 白名单里的关键 id 全部存在（DSH 核心、`web-ui-task-board`、`web-ui-usage`、`web-ui-settings`、梁神/调度预设入口、`dsh-annotation`、`session-stats-panel` 等） |
| mustBeDisabled | `web-ui-remote-bridge`、`web-ui-task-board-remote` 必须是字面量 `disabled: true` |
| mustNotExist | 白名单列出的 id 不得出现（如 `preset-pdf-toc`） |
| 顶层 entry 数 | 只作信息输出（INFO），不判定；随 DSH 与插件版本变化 |
| stderr 致命模式 | 不得出现 `skipping profile bundle`、`declares no dsh.bundle`、`duplicate` |
| `link:` 依赖 | 目标目录必须存在 |
| 其他 stderr | 只记 WARN，不拦截 |

- 退出码：`0` 全 PASS；`1` 有 FAIL；`2` 无法执行（缺 node / dsh / profile）。
- **正常现象**：`--dump-config` 会把 profile 根的 `cordis.yml` 重写成标准空数组 `[]`
  （与内容等价的 `[]`），不会改 `cordis.patch.yml`。
- 白名单不含模型和 provider 条目；想加检查项，复制一份 `expected-ids.json` 改好后用 `-ExpectedIdsFile` 指过去，
  或直接用 `-RequiredIds` / `-MustBeDisabled` 在白名单之外追加。
- 输出统一为 UTF-8（脚本开头固定 `[Console]::OutputEncoding`），agent 用管道抓取不会因 cp936 糊掉。
- 自定义检查：`-ExpectedIdsFile`、`-RequiredIds`、`-MustBeDisabled`、`-ForbiddenStderr` 都是参数。

---

## 4. 收紧（harden）

默认安装后，两个远程插件已由模板设为 `disabled: true`（作者的决定）。
`harden.ps1` 用来统一收紧**运行策略**，也可用于重写上述禁用项：

```powershell
.\harden.ps1 -Apply -DshHome "<DSH_HOME>" -DryRun   # 先看要写什么
.\harden.ps1 -Apply -DshHome "<DSH_HOME>"
.\harden.ps1 -Restore -DshHome "<DSH_HOME>"         # 还原
```

写入的是 `cordis.patch.yml` 末尾一个带标记的托管块：

```yaml
# >>> dsh-install-kit:harden ...
- id: web-ui-remote-bridge
  disabled: true
- id: web-ui-task-board-remote
  disabled: true
- id: approval
  config:
    policy: ask
- id: sandbox-policy
  config:
    mode: workspace-write
# <<< dsh-install-kit:harden ...
```

- **幂等**：内容一致时不做任何事，也不产生备份。
- **不改别人的 patch**：只替换这两个标记之间的行；文件其他内容逐字节保留
  （含 LF/CRLF 风格与无 BOM）。
- 真正改动前备份为 `cordis.patch.yml.bak-harden-<时间戳>`。
- `-Restore` 只删自己那一段，恢复 bundle 默认值。

> ⚠️ Windows 上 `dsh-base` 默认是 `sandbox=danger-full-access`、`approval=never`
> （源码里的 `!!js process.platform === 'win32' ? ...` 分支）。改成
> `workspace-write` / `ask` 后，涉及审批的工具调用会**停下来等人点**，
> 无人值守的 agent 会卡住。确认有人在场再 `-Apply`。

---

## 5. menu.json（给 agent 读）

```powershell
$menu = Get-Content .\menu.json -Raw | ConvertFrom-Json
$menu.default   | Select-Object id, package, note
$menu.optional  | Where-Object { $_.needs.Count -gt 0 }
$menu.excluded  | Select-Object id, reason
```

- `default`：模板默认开启、开箱即用。
- `optional`：已安装，但缺 `needs` 里的东西（登录、外部程序、token、目录）时不可用。
- `excluded`：已安装但默认 `disabled: true`（`web-ui-remote-bridge`、
  `web-ui-task-board-remote`）或需要凭据（`dsh-chatgpt-subscription`）。
- 冲突时以 `profile-template\package.json` 的 `dsh.profile.bundles` 与
  `cordis.patch.yml` 为准；`menu.json` 只是摘要。

---

## 6. 常见失败

| 现象 | 原因 | 处置 |
| --- | --- | --- |
| `未找到 node` / `pnpm` | PATH 里没有 | 装 Node ≥ v20、`npm i -g pnpm@11.28.9`，**重开终端** |
| `DSH_HOME 不存在` | 传错目录 | 独立 WebUI 版传 `<安装根>\home`；桌面版默认 `%USERPROFILE%\.dsh` |
| `找不到 dsh 的 lib\bin.js` | 非标准安装 | `-DshBin "<安装根>\node_modules\@deepseek-ai\dsh\lib\bin.js"` |
| `模板里有 link: 依赖指向本机不存在的目录` | 模板残留本地 link（本机是 `dsh-session-stats-panel`） | 改成已发布版本，或把目录一起发布；确认无碍可 `-AllowLocalLinks` |
| `pnpm install` 退出码非 0 | 网络 / pnpm 主版本 / lockfile 漂移 | 看日志；换 pnpm 11.x；去掉 `-FrozenLockfile` 重试；再不行回滚 |
| pnpm 提示 `Ignored build scripts` | 原生依赖构建被拦 | 检查 `pnpm-workspace.yaml` 的 `allowBuilds`，或 `pnpm approve-builds` |
| verify：`stderr 致命模式` 命中 `skipping profile bundle` | 某 bundle 版本与 dsh 不兼容（常见于第三方插件 peer 范围） | 看 stderr 里的包名与要求；`dsh plugin remove` 或换成兼容版本 |
| verify：`顶层 id 重复` | 同一插件被挂两次（聚合包 + 独立包） | 从 `bundles` 或 dependencies 去掉其中一个 |
| verify：两个远程插件不是 `disabled: true` | 模板没带禁用项 | 运行 `harden.ps1 -Apply` 后重跑 verify |
| verify：`entry 数 < 下限` | 依赖没装齐 / node_modules 坏 | 重新 `pnpm install`；确认没删 node_modules |
| 验证超时 | dsh 卡在 HMR/端口 | 先停掉正在跑的 WebUI 再验证 |

---

## 7. 技能（skills）

技能目录（`DSH_HOME\skills`，约 43.8MB）**不放进仓库**，也不由 `install.ps1` 复制。
安装完 profile 后，由发布包里的技能安装脚本（另行提供）把技能铺到 `DSH_HOME\skills`；
这一步是可选的，缺技能不影响 DSH 启动。

---

## 8. 回滚

1. 停掉 DSH / WebUI。
2. 安装时每次都会生成 `<profile>\.backup-install-<时间戳>\rollback.ps1`：

   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File "<profile>\.backup-install-<时间戳>\rollback.ps1"
   ```

3. 手工等价操作：

   ```powershell
   Copy-Item -Path "<profile>\.backup-install-<时间戳>\*" -Destination "<profile>" -Force
   cd "<profile>"; pnpm install --frozen-lockfile
   ```

4. 策略收紧的回滚：`harden.ps1 -Restore`（或删掉托管块）。

脚本**不删除任何文件**，也不清理 `node_modules`；回滚只覆盖配置。
`sessions`、`storages`、`attachments`、`usage`、`dsh-session-archive` 等运行数据全程不碰。

---

## 9. 版本策略

- 不锁死 `dsh` 与插件版本；只声明「在 `0.2.1-rc.5` + 模板组合下验证过」。
- 需要写死的地方会写死并注明原因，例如模板的

  ```yaml
  overrides:
    '@openai/codex': 0.166.0
  ```

  （0.153.4 对 ChatGPT 账号返回 `model_not_found`，0.166.0 正常。）
- 版本不符时：`install.ps1` 告警；`verify.ps1` 告警；`-StrictVersion` 可升级为失败。

---

## 10. 数据与凭据边界

- 仓库内**没有**：`.credentials.yaml`、`sessions/`、`storages/`、`attachments/`、
  `usage`、`dsh-session-archive/`、`task-board/` 的实际数据、任何 token/密码。
- 模板里的 `cordis.patch.yml` 不应出现绝对用户路径（`C:\Users\...`）；
  若必须出现（如 MCP 可执行文件路径），发布前应改为可配置项或写进 README 的「需自行替换」清单。
- `install.ps1` 只写 `DSH_HOME\profiles\<name>\` 下的 4~5 个配置文件，
  唯一例外是 pnpm 自己写的 `node_modules\` 与 `.pnpm-store`。

---

## 11. 未验证项（诚实清单）

1. 未在**另一台干净 Windows** 上实跑过 `pnpm install`（本机依赖已存在）。
2. 未验证「无管理员 + 受限用户目录」下的 pnpm store 位置行为。
3. 未验证 pwsh 7 下 `Start-Process -RedirectStandardError` 与中文路径组合的边角情况。
4. `harden.ps1 -Apply` 后的 `workspace-write` / `ask` 在 Windows 上是否被真正强制执行，
   上游没给保证；本机未做行为级验证。
5. 未实跑 `pnpm install`（测试只到 `-SkipPnpm` 分支），网络/镜像/原生构建行为未知。
6. 技能目录、模型凭据、ChatGPT 订阅登录均需用户自备。
