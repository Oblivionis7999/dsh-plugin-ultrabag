# 预设（agent preset）

新建会话时，可以在预设选择器里选一个预设。预设决定这次会话的系统提示词、可用工具和工作方式。本配置里能选到的预设如下。

| 预设 | 来源包 | 说明 |
| --- | --- | --- |
| standard | `@deepseek-ai/dsh-web-app`（DSH 自带） | 常规编码 agent，工具以原生形式提供 |
| ptc | `@deepseek-ai/dsh-web-app`（DSH 自带） | 程序化工具调用：工具通过代码运行时调用，适合工具多、调用次数多的任务 |
| minimal | `@deepseek-ai/dsh-web-app`（DSH 自带） | 精简提示词和工具集 |
| cordis | `@deepseek-ai/dsh-web-app`（DSH 自带） | DSH 内置的 cordis 预设 |
| 梁神模式 | `@linxin666/dsh-liangshen`（`@linxin666/dsh-web-all` 的子包，入口 `web-ui-liangshen`） | 以 minimal 为底，极简 persona 加固定工作纪律；默认 ptc 呈现，`mcp__*` 这类大工具族先折叠，需要时用 `tool_activate` 加载。新建会话页的模型选择器左边有一个拨杆可以开关它 |
| 调度模式 | `@eddyskywalker/dsh-chatgpt-subscription` | 基于 ptc 的调度 agent：先判断任务复杂度，复杂任务先澄清需求，再由主代理规划、派发子代理、审查和验收 |

每个预设的具体内容以对应包里的定义文件为准：DSH 自带的四个在 `@deepseek-ai/dsh-web-app` 的 `presets/` 目录，梁神模式在 `@linxin666/dsh-liangshen` 的 `presets/liangshen/`，调度模式在 `@eddyskywalker/dsh-chatgpt-subscription` 的 `presets/dispatch/`。

## 依赖关系：别删这两个包

梁神模式和调度模式不是写在 profile 里的，而是由插件在启动时自己声明给 DSH 的。插件没装或被禁用，预设就会从选择器里消失。

| 预设 | 需要保留 | 别做的事 |
| --- | --- | --- |
| 梁神模式 | `@linxin666/dsh-web-all`（bundle）及其中的 `web-ui-liangshen` 条目 | 不要从 `dsh.profile.bundles` 里删掉 `@linxin666/dsh-web-all`；不要在 patch 里禁用 `web-ui-liangshen` |
| 调度模式 | `@eddyskywalker/dsh-chatgpt-subscription`（bundle） | 不要删掉这个依赖或 bundle，即使你不用 ChatGPT 订阅 |

关于调度模式要多说一句：它和 ChatGPT 订阅 provider 在同一个包里。只想要调度模式、不想用订阅功能的话，保留这个包，但**不要登录**它的 ChatGPT 订阅即可。这个包会读取其他应用的登录凭证，详见 README 的安全提示。

## 常见问题

- **选择器里找不到梁神模式或调度模式**：确认对应包在 profile 的 `dsh.profile.bundles` 里，插件管理面板里没有被禁用，然后完全重启 DSH WebUI，新建一个空会话再看。
- **拨杆提示「未找到梁神模式预设」**：说明 `web-ui-liangshen` 这一行没启用，到插件管理面板打开它。
- **改了预设想恢复**：在 Web 编辑器里保存的预设修改会写进你 profile 的 `cordis.patch.yml`。删掉对应的覆盖条目再重启，就会回到包自带的定义。
- **升级后预设变了**：预设定义随包版本变化。本仓库只对 [compat.md](compat.md) 列出的版本负责。
