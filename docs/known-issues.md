# 已知问题（known-issues）

> 按"会不会挡安装"排序。每条都标明：现象、原因、处理、是否影响功能。

## 会挡安装

### 1. PowerShell 5.1 读 UTF-8 脚本乱码
- **现象**：跑 `.ps1` 报"缺少闭合的 `)` / `}`"，或中文全变问号。
- **原因**：Windows PowerShell 5.1 默认按 ANSI（GBK）读无 BOM 的 UTF-8 文件。
- **处理**：仓库内所有 `.ps1` 均存为 **UTF-8 with BOM**；若你自己改过脚本，保存时保留 BOM，或用 `pwsh` 7 执行。
- **影响**：不挡功能，挡脚本。

### 2. `ERR_PNPM_UNEXPECTED_STORE`
- **现象**：`pnpm install` 直接失败，提示 store 不一致。
- **原因**：机器上同时存在 pnpm v10 与 v11 的 store（作者本机踩过两次）。
- **处理**：统一 pnpm 版本；或 `pnpm config set store-dir <统一目录>` 后重试。
- **影响**：不挡功能，挡安装。

### 3. `'pnpm' is not recognized`
- **现象**：命令找不到。
- **原因**：pnpm 没装或没进 PATH（作者本机踩过一次）。
- **处理**：`corepack enable` 或 `npm i -g pnpm@11`，重开终端。

## 不挡安装，但会让人误会

### 4. `cpu-features` 编译失败
- **现象**：安装日志里一大段 `Unable to detect compiler type`。
- **原因**：缺 MSVC；`cpu-features` 是 `ssh2` 的 **optionalDependencies**，`try { require(...) } catch {}` 静默降级。
- **处理**：**忽略**。只损失 CPU 指令级加速，SSH 功能与安全性不变。
- **影响**：无。

### 5. `patch: entry "tool-ralph" not found`
- **现象**：启动 stderr 一行告警。
- **原因**：`dsh-tui@0.18.0` 自带的 patch 想禁用一个当时不存在的行；ralph 的 `tool-ralph` 是 group 内嵌行，顶层 patch 够不到。
- **处理**：**忽略**。基线本来就有，判"是否新增"而不是"是否为空"。
- **影响**：无。

### 6. pnpm 11 的"发布冷静期"
- **现象**：刚发布的包装不上，报 `minimumReleaseAge`。
- **原因**：pnpm 11 默认延迟安装新发布版本。
- **处理**：在 `pnpm-workspace.yaml` 的 `minimumReleaseAgeExclude` 里加该 scope。
- **影响**：不挡功能，挡安装新包。

## 安全 / 行为类（装完必须知道）

### 7. 默认权限是 `danger-full-access` + 审批 `never`
- **原因**：`dsh-tui` 的 patch 在 Windows 上把 `sandbox-policy` 钉成 `danger-full-access`、`approval` 钉成 `never`（终端信任模型）。
- **处理**：介意就跑 `core\harden.ps1 -Apply` 收紧；要全开就保持。
- **影响**：这是安全姿态，不是 bug。

### 8. 两个远程插件默认关闭
- `remote-bridge`：默认连作者个人中继，开启会拉 `cloudflared` 建公网隧道；
- `task-board-remote`：给配对手机看任务板，依赖上面那个。
- **处理**：`harden.ps1 -Restore` 可恢复作者默认（=关闭）。

### 9. `chatgpt-subscription` 会读其他应用的凭证
- 它会读 `~/.codex/auth.json`、`~/.minimax/auth/...` 等，并用 `codex_cli_rs` 身份复用订阅。
- **处理**：不用就别开；开了要清楚这是 ToS 灰区。

### 10. 版本漂移
- `@linxin666/dsh-web-all` 已钉 **0.4.14**：0.4.15 **删除了 `web-ui-git-graph`、新增 `web-ui-diagrams`**，升级会让 Git 图面板消失、多出没配过的面板。
- DSH 升到 `0.2.2-rc.1` 会让 6 个包 peer 不满足（`dsh-tui` 最硬，36 条）。
- **处理**：升级前看 `docs/compat.md`；本仓库只对 **DSH 0.2.1-rc.5** 负责。
