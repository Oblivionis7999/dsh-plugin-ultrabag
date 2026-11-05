# Third-Party Notices / 第三方组件声明

> 本仓库根目录的 `LICENSE`（MIT）只覆盖本仓库自己的文件：配置模板、脚本和文档。安装脚本下载的第三方插件、技能和工具，许可归各自作者，见下表和 `licenses/` 目录。

本仓库只包含 DSH profile 配置模板、安装脚本和文档，**不包含任何第三方代码、二进制或技能内容**。下列组件由安装脚本在用户机器上从各自上游获取（npm 包由 pnpm / npm 安装，技能由脚本从上游仓库拉取，MCP 工具由用户自行安装），各组件的版权与许可归其原作者所有，以各自上游发布的许可为准。本文件仅列出来源与许可，便于使用者履行署名义务；它不改变任何组件的许可，也不表示本仓库整体采用其中任何一种许可。

- 核对日期：2026-11-05。"版本（实测）"取自本机已安装包的 `package.json`；安装脚本实际装到的版本可能更新。
- "许可"一列**以包内 LICENSE 正文为准**。`package.json#license` 声明与正文不一致时，写明"声明 X，正文 Y"。
- 许可原文见 [`licenses/`](licenses/)。内容逐字相同的许可文本只存一份，版权行在下表中逐项保留。
- 名称与商标（DeepSeek、Matt Pocock、Live2D、Minecraft 等）不在任何许可的授权范围内，本仓库不借此暗示任何背书。

---

## 1. 官方 DSH 包（`@deepseek-ai/*`）

上游仓库均为 [deepseek-ai/deepseek-harness](https://github.com/deepseek-ai/deepseek-harness)。15 个包的 LICENSE 逐字节相同 → [`licenses/deepseek-ai-deepseek-harness.LICENSE.txt`](licenses/deepseek-ai-deepseek-harness.LICENSE.txt)。

| 组件 | 版本（实测） | 上游仓库 | 许可 | 版权行原文 |
|---|---|---|---|---|
| @deepseek-ai/dsh | 0.2.1-rc.5 | deepseek-ai/deepseek-harness | MIT | Copyright (c) 2026 DeepSeek |
| @deepseek-ai/dsh-base | 0.2.1-rc.5 | 同上 | MIT | Copyright (c) 2026 DeepSeek |
| @deepseek-ai/dsh-web-app | 0.2.1-rc.5 | 同上 | MIT | Copyright (c) 2026 DeepSeek |
| @deepseek-ai/dsh-mcp-client | 0.2.1-rc.5 | 同上 | MIT | Copyright (c) 2026 DeepSeek |
| @deepseek-ai/dsh-experimental-auto-review | 0.2.1-rc.5 | 同上 | MIT | Copyright (c) 2026 DeepSeek |
| @deepseek-ai/dsh-experimental-agent-team-profile | 0.2.1-rc.5 | 同上 | MIT | Copyright (c) 2026 DeepSeek |
| @deepseek-ai/dsh-experimental-voice-input-bundle | 0.2.1-rc.5 | 同上 | MIT | Copyright (c) 2026 DeepSeek |
| @deepseek-ai/dsh-experimental-tool-worktree | 0.2.1-rc.5 | 同上 | MIT | Copyright (c) 2026 DeepSeek |
| @deepseek-ai/dsh-experimental-cot-translation-bundle | 0.2.1-rc.5 | 同上 | MIT | Copyright (c) 2026 DeepSeek |
| @deepseek-ai/dsh-experimental-session-search | 0.2.1-rc.5 | 同上 | MIT | Copyright (c) 2026 DeepSeek |
| @deepseek-ai/dsh-experimental-session-titles-bundle | 0.2.1-rc.5 | 同上 | MIT | Copyright (c) 2026 DeepSeek |
| @deepseek-ai/dsh-experimental-plugin-market-bundle | 0.2.1-rc.5 | 同上 | MIT | Copyright (c) 2026 DeepSeek |
| @deepseek-ai/dsh-experimental-ralph-bundle | 0.2.1-rc.5 | 同上 | MIT | Copyright (c) 2026 DeepSeek |
| @deepseek-ai/dsh-subagent-codex | 0.2.1-rc.5 | 同上 | MIT | Copyright (c) 2026 DeepSeek |
| @deepseek-ai/dsh-subagent-claude-code | 0.2.1-rc.5 | 同上 | MIT | Copyright (c) 2026 DeepSeek |

---

## 2. 第三方 npm 插件

| 组件 | 版本（实测） | 上游仓库 | 许可 | 版权行原文 | 许可原文 |
|---|---|---|---|---|---|
| @changfenhuang/dsh-annotation | 1.4.11 | [omdsh-dev/dsh-annotation](https://github.com/omdsh-dev/dsh-annotation) | MIT | Copyright (c) 2026 omdsh-dev | [dsh-annotation.LICENSE.txt](licenses/dsh-annotation.LICENSE.txt) |
| @deepseek-harness-tui/dsh-tui | 0.18.0 | [ccch1mneyyy/dsh-TUI](https://github.com/ccch1mneyyy/dsh-TUI) | MIT | Copyright (c) 2026, chimney (ccch1mneyyy) | [dsh-tui.LICENSE.txt](licenses/dsh-tui.LICENSE.txt) |
| @eddyskywalker/dsh-chatgpt-subscription | 0.55.0 | [Aa728848/dsh-chatgpt-subscription](https://github.com/Aa728848/dsh-chatgpt-subscription) | MIT | Copyright (c) 2026 DSH ChatGPT Subscription contributors | [dsh-chatgpt-subscription.LICENSE.txt](licenses/dsh-chatgpt-subscription.LICENSE.txt) |
| dsh-codex-effort-slider | 1.1.4 | [Microqian2th/dsh-codex-effort-slider](https://github.com/Microqian2th/dsh-codex-effort-slider) | MIT | Copyright (c) 2026 dsh-codex-effort-slider contributors | [dsh-codex-effort-slider.LICENSE.txt](licenses/dsh-codex-effort-slider.LICENSE.txt) |
| dsh-prompt-enhance | 0.3.4 | [rongxingda/dsh-prompt-enhance](https://github.com/rongxingda/dsh-prompt-enhance) | Apache-2.0 | 包内 LICENSE 为 Apache-2.0 标准全文，无具体版权行；版权归 rongxingda/dsh-prompt-enhance 作者 | [dsh-prompt-enhance.LICENSE.txt](licenses/dsh-prompt-enhance.LICENSE.txt) |
| dsh-session-insights | 0.7.0 | [GreenLv/dsh-session-insights](https://github.com/GreenLv/dsh-session-insights) | MIT | Copyright (c) 2026 Gerui Lv | [dsh-session-insights.LICENSE.txt](licenses/dsh-session-insights.LICENSE.txt) |
| dsh-session-stats-panel | 2.2.2 | [Oblivionis7999/dsh-session-stats-panel](https://github.com/Oblivionis7999/dsh-session-stats-panel) | MIT | Copyright (c) 2026 织风裁月 (Oblivionis7999) | [dsh-session-stats-panel.LICENSE.txt](licenses/dsh-session-stats-panel.LICENSE.txt) |
| dsh-whale-widget | 0.4.2 | [MeteorNOX/DeepSeek-Balance-Whale-Widget](https://github.com/MeteorNOX/DeepSeek-Balance-Whale-Widget) | MIT（**仅代码**；见下方说明） | Copyright (c) 2026 MeteorNOX | [dsh-whale-widget.LICENSE.txt](licenses/dsh-whale-widget.LICENSE.txt)、[dsh-whale-widget.PROVENANCE.md](licenses/dsh-whale-widget.PROVENANCE.md) |
| dsh-working-activity（由 dsh-tui 依赖间接安装） | 0.5.1 | [ccch1mneyyy/working-activity](https://github.com/ccch1mneyyy/working-activity) | 包内正文 BSD-3-Clause（package.json 也声明 BSD-3-Clause；GitHub 仓库标注 MIT，**两者不一致**） | Copyright (c) 2026, chimney (ccch1mneyyy) | [dsh-working-activity.LICENSE.txt](licenses/dsh-working-activity.LICENSE.txt) |

说明：

- **dsh-whale-widget**：MIT 只覆盖代码（`lib/`、`cordis.patch.yml`、`package.json`、文档与维护脚本）。`assets/**` 下的图片、动图、音效和 `icon.png` **不在 MIT 范围内**。上游的说法是这些素材按 as-is 随插件提供，仅供运行该插件使用，不授予再许可。详见其 PROVENANCE.md（已原样复制到 `licenses/`）。
- **dsh-working-activity**：已发布的 npm 包与 GitHub 仓库的许可不一致。本表以包内正文 BSD-3-Clause 为准，待上游澄清。
- **dsh-session-stats-panel**：本机是通过本地 `link:` 安装的，安装脚本应改从 npm 获取。版本与许可均取自本机副本。

---

## 3. `@linxin666/*` 子包（聚合包 `@linxin666/dsh-web-all`，上游属主 zhu1090093659）

这 24 个子包**混用两种许可**，不能统一按单一许可声明。包内 Apache-2.0 正文是 Apache 2.0 标准全文，没有具体版权行，版权归上游作者 zhu1090093659 所有。

- Apache-2.0 正文（逐字相同）→ [`licenses/linxin666-dsh-web.Apache-2.0.LICENSE.txt`](licenses/linxin666-dsh-web.Apache-2.0.LICENSE.txt)
- BSD-3-Clause 正文（5 个包逐字相同）→ [`licenses/linxin666-zhu1090093659.BSD-3-Clause.LICENSE.txt`](licenses/linxin666-zhu1090093659.BSD-3-Clause.LICENSE.txt)

| 组件 | 版本（实测） | 上游仓库 | 许可（以包内正文为准） | 版权行原文 |
|---|---|---|---|---|
| @linxin666/dsh-web-all | 0.4.14 | [zhu1090093659/dsh-web](https://github.com/zhu1090093659/dsh-web) | Apache-2.0 | 无（Apache 全文，无版权行） |
| @linxin666/dsh-agents | 0.4.14 | zhu1090093659/dsh-web | **包内无 LICENSE 文件**；package.json 声明 Apache-2.0 | 无 |
| @linxin666/dsh-client-ui-browser-view | 0.4.14 | 包内未声明（推定 zhu1090093659/dsh-web） | **package.json 声明 BSD-3-Clause，包内正文 Apache-2.0** | 无 |
| @linxin666/dsh-client-ui-community-plugins | 0.4.14 | [zhu1090093659/dsh-community-plugins](https://github.com/zhu1090093659/dsh-community-plugins) | BSD-3-Clause | Copyright (c) 2026, zhu1090093659 |
| @linxin666/dsh-client-ui-git-graph | 0.4.14 | zhu1090093659/dsh-web | Apache-2.0 | 无 |
| @linxin666/dsh-client-ui-market | 0.4.14 | zhu1090093659/dsh-web | **package.json 声明 BSD-3-Clause，包内正文 Apache-2.0** | 无 |
| @linxin666/dsh-client-ui-message-edit | 0.4.14 | zhu1090093659/dsh-web | Apache-2.0 | 无 |
| @linxin666/dsh-client-ui-plugin-manager | 0.4.14 | 包内未声明 | BSD-3-Clause | Copyright (c) 2026, zhu1090093659 |
| @linxin666/dsh-client-ui-preset-center | 0.4.14 | [zhu1090093659/dsh-presets](https://github.com/zhu1090093659/dsh-presets) | BSD-3-Clause | Copyright (c) 2026, zhu1090093659 |
| @linxin666/dsh-client-ui-skill-explorer | 0.4.14 | zhu1090093659/dsh-web | BSD-3-Clause | Copyright (c) 2026, zhu1090093659 |
| @linxin666/dsh-client-ui-skin-center | 0.4.14 | [zhu1090093659/dsh-skins](https://github.com/zhu1090093659/dsh-skins) | **package.json 声明 Apache-2.0，包内正文 BSD-3-Clause** | Copyright (c) 2026, zhu1090093659 |
| @linxin666/dsh-client-ui-task-board | 0.4.14 | zhu1090093659/dsh-web | Apache-2.0 | 无 |
| @linxin666/dsh-client-ui-task-board-github | 0.4.14 | zhu1090093659/dsh-web | Apache-2.0 | 无 |
| @linxin666/dsh-client-ui-task-board-team | 0.4.14 | 包内未声明 | **package.json 声明 BSD-3-Clause，包内正文 Apache-2.0** | 无 |
| @linxin666/dsh-client-ui-web-ui-settings | 0.4.14 | zhu1090093659/dsh-web | Apache-2.0 | 无 |
| @linxin666/dsh-i18n | 0.4.14 | 包内未声明 | Apache-2.0 | 无 |
| @linxin666/dsh-liangshen | 0.4.14 | zhu1090093659/dsh-web | Apache-2.0 | 无 |
| @linxin666/dsh-pet | 0.4.14 | [zhu1090093659/dsh-pet](https://github.com/zhu1090093659/dsh-pet) | Apache-2.0（见下方说明） | 无 |
| @linxin666/dsh-remote-bridge | 0.4.14 | zhu1090093659/dsh-web | Apache-2.0 | 无 |
| @linxin666/dsh-session-archive | 0.4.14 | 包内未声明 | Apache-2.0 | 无 |
| @linxin666/dsh-ssh | 0.4.14 | zhu1090093659/dsh-web | Apache-2.0 | 无 |
| @linxin666/dsh-task-board-remote | 0.4.14 | zhu1090093659/dsh-web | Apache-2.0 | 无 |
| @linxin666/dsh-usage | 0.4.14 | zhu1090093659/dsh-web | Apache-2.0 | 无 |
| @linxin666/dsh-win-bash | 0.4.14 | zhu1090093659/dsh-web | Apache-2.0（仅插件自身代码；见下方说明） | 无 |

说明：

- **dsh-win-bash**：该 npm 包在 `runtime/win32-x64/` 下**随包分发** Git for Windows `v2.56.0.windows.2`（MinGit 以及完整 Git 包中的 `sleep.exe` / `seq.exe`）的精简二进制。其中包括 bash、msys2-runtime、coreutils、sed、grep、gawk 等，许可为 **GPL-2.0 / GPL-3.0-or-later**；libiconv、gettext、mpfr、gmp 等为 **LGPL-2.1 / LGPL-3.0**；其余还有 GCC Runtime Library Exception、ncurses（MIT-style）、PCRE、zlib、expat、OpenSSL（Apache-2.0）、SQLite（Public domain）等。这些许可原文由上游放在包内 `runtime/win32-x64/licenses/`，来源与 SHA256 见包内 `PROVENANCE.md`。本仓库不分发这些二进制，也不复制它们的许可文本；它们随 npm 包一起安装。如需对应源代码，请按 GPL 要求向 Git for Windows / MSYS2 上游获取。
- **dsh-pet**：插件随包附带 MIT 许可的 pixi.js 与 untitled-pixi-live2d-engine 运行栈，但**不打包也不下载 Live2D Cubism Core**，因为 Cubism Core 是专有许可，禁止再分发。要启用 Live2D 宠物，用户须自行从 Live2D 官方获取 Cubism SDK for Web 并接受其许可。本仓库同样不提供 Cubism Core。
- **dsh-agents** 包内缺 LICENSE 文件。本表按 package.json 声明和同仓库其他子包记为 Apache-2.0，但这一点尚未由包内正文确认。

---

## 4. 技能来源

技能由安装脚本按 `skills/skills.manifest.json` 从下列上游拉取，本仓库不 vendor 任何技能内容。许可原文取自各仓库 `main` 分支的 `LICENSE`（raw.githubusercontent.com，2026-11-05）。

| 组件 | 版本（实测） | 上游仓库 | 许可 | 版权行原文 | 许可原文 |
|---|---|---|---|---|---|
| mattpocock/skills（code-review、tdd、grilling 等） | `main` 分支 | [mattpocock/skills](https://github.com/mattpocock/skills) | MIT | Copyright (c) 2026 Matt Pocock | [mattpocock-skills.LICENSE.txt](licenses/mattpocock-skills.LICENSE.txt) |
| morluto/rea（rea-* 与 reverse-engineer-anything 技能） | `main` 分支 / npm `rea-agents` 6.8.0 | [morluto/rea](https://github.com/morluto/rea) | MIT | Copyright (c) 2026 morluto | [morluto-rea.LICENSE.txt](licenses/morluto-rea.LICENSE.txt) |
| hugohe3/ppt-master（ppt-master 技能） | `main` 分支 | [hugohe3/ppt-master](https://github.com/hugohe3/ppt-master) | MIT | Copyright (c) 2025-2026 Hugo He | [hugohe3-ppt-master.LICENSE.txt](licenses/hugohe3-ppt-master.LICENSE.txt) |
| diagram-design | — | 未找到上游 | SKILL.md 中声明 MIT，但没有 LICENSE 文件，版权人未知 | 未知 | **无**。安装脚本默认不安装 |

---

## 5. MCP 服务器与外部工具

这些工具在本仓库中只以配置示例和安装文档的形式出现，二进制与代码均由用户自行安装。

| 组件 | 版本（实测） | 上游仓库 | 许可 | 版权行原文 | 许可原文 |
|---|---|---|---|---|---|
| rea-agents（REA MCP 服务器，`npm i -g rea-agents`） | 6.8.0 | [morluto/rea](https://github.com/morluto/rea) | MIT（包内 LICENSE 与仓库 LICENSE 逐字相同） | Copyright (c) 2026 morluto | [morluto-rea.LICENSE.txt](licenses/morluto-rea.LICENSE.txt)。该包另带 `THIRD_PARTY_NOTICES.md` 和 `licenses/`，随 npm 包分发 |
| windows-mcp（PyPI，`uv tool install windows-mcp`） | 0.8.8 | [CursorTouch/Windows-MCP](https://github.com/CursorTouch/Windows-MCP) | MIT | Copyright (c) 2025 JEOMON GEORGE | [windows-mcp.LICENSE.txt](licenses/windows-mcp.LICENSE.txt)（取自本机 `windows_mcp-0.8.8.dist-info/licenses/LICENSE.md`） |
| KimiCU（`kimi-cu.exe`） | — | — | 未获得可再分发许可 | — | **无**。本仓库不提供 KimiCU，也不附其许可；文档中仅提及"可选，自行安装" |
