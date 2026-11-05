# 兼容性

本仓库只对一个版本组合负责：**DSH 0.2.1-rc.5**，加上下表列出的插件与依赖版本。在这个组合下，22 个 bundle 全部加载，DSH 的兼容性检查对每个包返回 0 条未满足项，插件管理日志里没有 incompatible 记录。

"实测共存"指包能加载、patch 能合成、检查通过。它不等于每个面板的每个按钮都逐个点过。

其他版本组合**未实验**。版本号没有锁死，你可以升级，但出问题需要自己处理，升级前请备份 profile。

## 实测环境

| 项 | 版本 |
| --- | --- |
| DSH（`@deepseek-ai/dsh`） | 0.2.1-rc.5 |
| Node.js | 24.22.1 |
| pnpm | 11.28.9 |
| 系统 | Windows 11 x64 |

## 22 个 bundle

### 官方包（13 个）

这 13 个包随 DSH 本体安装，版本由 DSH 决定，profile 里没法单独升级。它们之间用精确版本互相锁定。

| 包 | 实测版本 | DSH 版本声明 |
| --- | --- | --- |
| `@deepseek-ai/dsh-base` | 0.2.1-rc.5 | 无 |
| `@deepseek-ai/dsh-web-app` | 0.2.1-rc.5 | peer 精确 0.2.1-rc.5 |
| `@deepseek-ai/dsh-experimental-auto-review` | 0.2.1-rc.5 | peer ×7，精确 0.2.1-rc.5 |
| `@deepseek-ai/dsh-experimental-agent-team-profile` | 0.2.1-rc.5 | 无 |
| `@deepseek-ai/dsh-experimental-voice-input-bundle` | 0.2.1-rc.5 | 无 |
| `@deepseek-ai/dsh-experimental-tool-worktree` | 0.2.1-rc.5 | peer ×2，精确 0.2.1-rc.5 |
| `@deepseek-ai/dsh-experimental-cot-translation-bundle` | 0.2.1-rc.5 | 无 |
| `@deepseek-ai/dsh-experimental-session-search` | 0.2.1-rc.5 | 无 |
| `@deepseek-ai/dsh-experimental-session-titles-bundle` | 0.2.1-rc.5 | 无 |
| `@deepseek-ai/dsh-experimental-plugin-market-bundle` | 0.2.1-rc.5 | 无 |
| `@deepseek-ai/dsh-subagent-codex` | 0.2.1-rc.5 | peer ×5，精确 0.2.1-rc.5 |
| `@deepseek-ai/dsh-subagent-claude-code` | 0.2.1-rc.5 | peer ×5，精确 0.2.1-rc.5 |
| `@deepseek-ai/dsh-experimental-ralph-bundle` | 0.2.1-rc.5 | 无 |

### 第三方包（9 个）

| 包 | 实测版本 | DSH 版本声明 | npm 上更新的版本 |
| --- | --- | --- | --- |
| `@linxin666/dsh-web-all` | 0.4.14 | peer `>=0.2.1-rc.3` | 0.4.15（未测，见下文） |
| `@deepseek-harness-tui/dsh-tui` | 0.18.0 | peer ×36，精确 0.2.1-rc.5 | — |
| `@eddyskywalker/dsh-chatgpt-subscription` | 0.55.0 | peer ×18，`^0.2.1-rc.3` | 0.58.0（未测） |
| `@changfenhuang/dsh-annotation` | 1.4.11 | 无 | — |
| `dsh-codex-effort-slider` | 1.1.4 | 无 | — |
| `dsh-prompt-enhance` | 0.3.4 | peer `dsh-llm >=0.1.1-rc.2` | — |
| `dsh-session-insights` | 0.7.0 | 顶层 `engines.dsh >=0.2.1-rc.2` | — |
| `dsh-session-stats-panel` | 2.2.2 | peer `>=0.2.1-rc.5` | — |
| `dsh-whale-widget` | 0.4.2 | 无 | — |

"无"表示包没有声明对 DSH 版本的要求。DSH 对这类包总是放行，这说明"没检查"，不说明"兼容"。

## profile 的 11 个直接依赖

profile 的 `package.json` 里直接写了下面 11 个依赖，其余 bundle 由 DSH 本体或这些包间接提供。

| 依赖 | 写法 | 说明 |
| --- | --- | --- |
| `@linxin666/dsh-web-all` | `0.4.14` | 写死 |
| `@eddyskywalker/dsh-chatgpt-subscription` | `0.55.0` | 暂时写死 |
| `@deepseek-ai/dsh-subagent-codex` | `0.2.1-rc.5` | 跟随 DSH 版本 |
| `@deepseek-ai/dsh-subagent-claude-code` | `0.2.1-rc.5` | 跟随 DSH 版本 |
| `@deepseek-harness-tui/dsh-tui` | `^0.18.0` | 升级前先看 changelog，它与 DSH 版本耦合最深 |
| `@changfenhuang/dsh-annotation` | `^1.4.11` | |
| `dsh-codex-effort-slider` | `^1.1.4` | |
| `dsh-prompt-enhance` | `^0.3.4` | |
| `dsh-session-insights` | `^0.7.0` | |
| `dsh-session-stats-panel` | `2.2.2` | 作者本机是本地 `link:` 开发件；发布模板应使用 npm 版本 |
| `dsh-whale-widget` | `^0.4.2` | |

另有一条 pnpm override：`@openai/codex` → `0.166.0`，写在 profile 的 `pnpm-workspace.yaml` 里。

规则很简单：碰 DSH 内部接口的写死，纯 UI 插件用 `^`。

## 写死项及原因

| 项 | 版本 | 原因 |
| --- | --- | --- |
| `@linxin666/dsh-web-all` | 0.4.14 | 0.4.14 与 0.4.15 的 24 个 `web-ui-*` 入口只差一处：0.4.15 删了 `web-ui-git-graph`，加了 `web-ui-diagrams`。写成 `^0.4.14` 会让 Git 图面板悄悄消失、多出一个没配过的面板 |
| `@openai/codex`（override） | 0.166.0 | `dsh-subagent-codex@0.2.1-rc.5` 精确依赖 `@openai/codex@0.153.4`，这个版本对 ChatGPT 账号返回 `model_not_found`，Codex 子智能体不可用。0.166.0 正常。删掉 override 会立刻复现问题 |
| `@eddyskywalker/dsh-chatgpt-subscription` | 0.55.0 | 0.58.0 未测；它的 peer 声明还停在 `^0.2.1-rc.3`，跨版本风险比其他插件高 |
| 13 个官方包 | 0.2.1-rc.5 | 版本由 DSH 本体决定，彼此用精确版本互相锁定 |

关于 `@openai/codex` override 还要知道两点：

- 它绕过了上游的精确依赖。如果新版 `codex exec` 的参数或输出格式变了，故障会表现为"子智能体没有输出"，而不是报错。
- override 写在 `pnpm-workspace.yaml`，换成 npm 或 yarn 安装会直接失效，且没有提示。

## 已知会出问题的升级

### DSH 0.2.1-rc.5 → 0.2.2-rc.1

按 DSH 自己的检查逻辑复算，有 6 个包会判定不兼容：

| 包 | 不满足的 peer 数 |
| --- | --- |
| `@deepseek-harness-tui/dsh-tui` | 36 |
| `@deepseek-ai/dsh-experimental-auto-review` | 7 |
| `@deepseek-ai/dsh-subagent-codex` | 5 |
| `@deepseek-ai/dsh-subagent-claude-code` | 5 |
| `@deepseek-ai/dsh-experimental-tool-worktree` | 2 |
| `@deepseek-ai/dsh-web-app` | 1 |

这 6 个包都把 peer 写成了精确的 `0.2.1-rc.5`，所以 DSH 升级后必须同步升级它们。DSH 会提示用 `dsh plugin allow-version` 或插件管理器做版本豁免，但豁免只是让它加载，不代表它能正常工作。

`dsh-chatgpt-subscription@0.55.0` 在 0.2.2-rc.1 上不会报警，因为 `^0.2.1-rc.3` 在包含预发布版本的判定下刚好覆盖 0.2.2-rc.1。这是范围写法的副作用，不是作者测过 0.2.2。到 0.3.0 它会整体判定失败。

### `@linxin666/dsh-web-all` 0.4.14 → 0.4.15

Git 图面板消失，Diagrams 面板出现。当前 profile patch 没有引用任何 `web-ui-*` 条目，所以不会出现悬空 patch，但界面会变。

### 查 npm 最新版时的坑

官方 `@deepseek-ai/dsh-*` 包的 `dist-tags.latest` 都是过时的（例如 `0.0.1-rc.1`）。`npm view <包> version` 会给出错误答案。要看真实最高版本，请列出全部版本后按 semver 取最高（含预发布）。

## DSH 怎么判断插件是否兼容

DSH 在加载插件前，只读插件 `package.json` 的两处信息，不执行插件代码：

| 优先级 | 读什么 | 行为 |
| --- | --- | --- |
| 1 | 顶层 `engines.dsh` | 只要存在就只看它，`peerDependencies` 全部忽略 |
| 2 | 没有 `engines.dsh` 时，所有 `@deepseek-ai/dsh` 和 `@deepseek-ai/dsh-*` 的 peer | 每一条都要被当前 DSH 版本满足，有一条不满足就判为不兼容 |
| — | `dsh.engines.dsh` | 永远不读 |

由此得出的几点：

- **`dsh.engines.dsh` 不生效。** 例如 `dsh-prompt-enhance` 在 `dsh.engines.dsh` 里写了 `<0.3.0` 上界，但 DSH 不读它，0.3.x 上照样放行。
- **加 `engines.dsh` 是放宽，不是收紧。** 一个靠 36 条 peer 卡版本的包，一旦写了顶层 `engines.dsh`，这 36 条检查就全部被跳过。所以不要为了让插件装上而去给它加 `engines.dsh`。
- **预发布版本参与范围判定。** `>=0.2.1-rc.5` 会放行 0.2.2-rc.1。如果想只放行测过的小版本，写 `>=0.2.1-rc.5 <0.2.2`。
- **空字符串或 `workspace:` 形式的 `engines.dsh` 会被判为不兼容**，不是"无要求"。peer 里的 `workspace:^`、`workspace:~`、`workspace:*` 则视为当前运行时版本。
- **豁免**写在 profile 目录下的 `compatibility.json`。本仓库不带这个文件，也不依赖任何豁免。
