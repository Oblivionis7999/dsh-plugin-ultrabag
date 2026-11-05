# dsh-config-pack

一份 DeepSeek Harness（DSH）WebUI 的 profile 配置，按作者本机原样导出。装好后，你拿到的插件组合、默认预设和界面布局与作者机器上一致。装不好时，把这个仓库交给你自己的 agent 去修。

> 这是个人整理的非官方配置，与 DeepSeek 官方无关，也不代表 DeepSeek 认可或背书。

## 包含什么

完整清单与每个插件的说明见 [core/menu.json](core/menu.json)（以 `core/profile-template/` 里的模板为准，menu.json 是给人和 agent 看的摘要）。

装好后每个插件在哪里、怎么用，见 [docs/usage-guide.md](docs/usage-guide.md)。

| 来源 | 内容 | 数量 |
| --- | --- | --- |
| DSH 官方（`@deepseek-ai/*`） | 核心运行时、WebUI、实验性插件（自动审阅、agent team、语音输入、worktree、思维链翻译、会话搜索、会话标题、插件市场、Ralph）、Codex / Claude Code 子智能体 | 13 个 bundle |
| `@linxin666/dsh-web-all` | Web UI 聚合包：任务板、Agents、Git 图、多语言、梁神模式、插件管理、预设中心、会话归档、用量、win_bash、技能浏览等 | 24 个 `web-ui-*` 入口 |
| 其他第三方插件 | `dsh-tui`、`dsh-chatgpt-subscription`、`dsh-annotation`、`dsh-prompt-enhance`、`dsh-codex-effort-slider`、`dsh-session-insights`、`dsh-session-stats-panel`、`dsh-whale-widget` | 8 个 bundle |
| 技能 | 由 [skills/install-skills.ps1](skills/install-skills.ps1) 从上游拉取，仓库里不放技能文件 | 46 个（默认装 40 个） |
| MCP（可选） | rea 逆向引擎、windows-mcp、KimiCU 的示例配置 | 3 条示例，见 [docs/mcp.md](docs/mcp.md) |
| 预设 | standard / ptc / minimal / cordis、梁神模式、调度模式 | 见 [docs/presets.md](docs/presets.md) |

## 前置条件

| 项 | 要求 | 作者实测 |
| --- | --- | --- |
| 系统 | Windows 10/11 x64 | Windows 11 |
| DSH | `@deepseek-ai/dsh` 0.2.1-rc.5（WebUI 版） | 0.2.1-rc.5 |
| Node.js | ≥ 24 | 24.22.1 |
| pnpm | 11.x | 11.28.9 |
| 网络 | 能访问 npm registry 和 GitHub | — |

`dsh-tui`、`win_bash`、windows-mcp、KimiCU 都只支持 Windows。macOS / Linux 用户请不要直接装这套配置。

装之前先确认你的 `DSH_HOME`：独立 WebUI 版通常是 `<安装根>\home`，`dsh web` 单机版通常是 `%USERPROFILE%\.dsh`。

## 安装

### 给人：3 步

先关掉正在运行的 DSH WebUI，然后在仓库根目录打开 PowerShell：

```powershell
# 1. 干跑：只检查环境、打印计划，不写文件
powershell -NoProfile -ExecutionPolicy Bypass -File .\core\install.ps1 -DshHome "<DSH_HOME>" -DryRun

# 2. 正式安装：先备份现有 profile，再复制模板、pnpm install、自动验证
powershell -NoProfile -ExecutionPolicy Bypass -File .\core\install.ps1 -DshHome "<DSH_HOME>"

# 3. 装技能（默认跳过 6 个未验证或版权人不明的）
powershell -NoProfile -ExecutionPolicy Bypass -File .\skills\install-skills.ps1 -DshHome "<DSH_HOME>"
```

装完启动 DSH WebUI，用 `web` profile 打开，新建一个会话。然后按 [docs/providers.md](docs/providers.md) 配好你自己的模型 provider，并把默认模型改成你自己的。

安装失败时，第 2 步会打印回滚命令；常见报错见 [docs/known-issues.md](docs/known-issues.md)。

### 给 agent：一句提示词

把仓库放到本机后，对你的 agent 说：

```text
请按 docs/agent-setup.md 安装这个仓库里的 DSH 配置，DSH_HOME 是 <你的 DSH_HOME>，失败就按文档排查并把原始报错告诉我。
```

## 默认关闭的插件

这两个插件已安装，但模板里是 `disabled: true`：

| id | 作用 | 为什么关 |
| --- | --- | --- |
| `web-ui-remote-bridge` | 让远程端连入你的 WebUI | 默认连作者个人中继，开启会用 `cloudflared` 建公网隧道 |
| `web-ui-task-board-remote` | 让配对手机查看任务板 | 依赖 remote-bridge，两者一起关 |

想用的话：在 WebUI 的插件管理面板里打开（它会写你 profile 的 `cordis.patch.yml`），或者手动把 profile `cordis.patch.yml` 里对应条目的 `disabled: true` 删掉，然后重启 DSH。开启前请先弄清楚它连的是哪个中继、谁能连进来。

`optional` 里还有几个插件需要额外条件才能真正可用（SSH 主机、GitHub token、本机浏览器等），见 menu.json 的 `needs` 字段。

## 安全提示

- **默认权限很宽。** `dsh-tui` 的 patch 在 Windows 上把 sandbox 设为 `danger-full-access`、approval 设为 `never`，也就是 agent 可以不经确认读写任意文件、执行任意命令。想收紧就运行 `core\harden.ps1 -DshHome "<DSH_HOME>" -Apply`。代价是：无人值守的 agent（子智能体、定时任务、Ralph 循环）会卡在审批上不动。
- **remote-bridge 会把 WebUI 暴露到公网。** 默认关闭；开启前确认中继地址和鉴权。
- **`dsh-chatgpt-subscription` 会读其他应用的登录凭证。** 它会读取 `~/.codex/auth.json`、`~/.minimax/auth/...` 等文件，并以 Codex CLI 的身份复用你的订阅。这处在服务条款的灰色地带。不需要就别登录它；需要的话，知道它在读什么。
- 不要把 `.credentials.yaml`、`.npmrc`、`sessions/`、`storages/`、`attachments/` 提交到任何仓库。

## 兼容性声明

本仓库只在 **DSH 0.2.1-rc.5 + [docs/compat.md](docs/compat.md) 列出的版本组合**下实测过共存（22 个 bundle 全部加载、无兼容性告警）。其他版本**未实验**，可能能用，也可能不能用。版本号没有锁死，升级风险由你自己承担，请先备份。

以下几项是写死的，原因见 compat.md：

| 项 | 版本 | 原因 |
| --- | --- | --- |
| `@linxin666/dsh-web-all` | 0.4.14 | 0.4.15 删了 `web-ui-git-graph`，加了 `web-ui-diagrams` |
| `@openai/codex`（pnpm override） | 0.166.0 | 插件精确依赖的 0.153.4 对 ChatGPT 账号报 `model_not_found` |
| `@eddyskywalker/dsh-chatgpt-subscription` | 0.55.0 | 0.58.0 未测 |

已知会出问题的升级：DSH 升到 0.2.2-rc.1 会让 6 个包的 peer 依赖不满足（`dsh-tui` 最多，36 条），详见 compat.md。

## 不含什么

- 任何凭据：API key、token、`.credentials.yaml`、ChatGPT / Codex 登录信息
- 会话、附件、用量、会话归档、任务板数据
- 作者自用的第三方中转 provider（已删除）。你需要自己加，参考 [examples/providers.example.yml](examples/providers.example.yml)
- 技能文件本体（安装脚本从上游拉取）
- MCP 服务器程序本体（只给示例配置，程序要自己装）

## 许可与致谢

本仓库只包含配置与脚本。各插件、技能、MCP 服务器归各自作者所有，许可以上游为准，汇总见 [THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md)。

本项目是个人维护的非官方配置包。"DeepSeek" 及相关名称归其权利人所有，这里只用于说明它适配的软件，不表示任何官方关联或背书。技能里出现的个人名字同理（例如 mattpocock/skills），不表示其作者认可本仓库。

感谢 DSH 官方团队，以及 `@linxin666`、`@deepseek-harness-tui`、`@eddyskywalker`、`@changfenhuang` 等插件作者和各技能、MCP 项目的作者。
