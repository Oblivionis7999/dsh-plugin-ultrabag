# MCP 服务器（可选）

作者本机接了三条 MCP 服务器。它们都不是 DSH 本体或本仓库插件的一部分：DSH 侧只用官方的 `@deepseek-ai/dsh-mcp-client` 插件，三条服务器是它的三个配置实例，各自启动一个外部程序。

本仓库**不打包**这些程序，只给示例配置 [examples/home-cordis.patch.example.yml](../examples/home-cordis.patch.example.yml)。不装任何一条，DSH 和本配置都能正常用。

## 怎么加

1. 先把你要用的那条 MCP 的程序装好（见下文各节）；
2. 关闭 DSH WebUI；
3. 把示例里对应的段落复制到 `<DSH_HOME>\cordis.patch.yml`。注意是 **DSH_HOME 根目录**那份，不是 profile 里的那份；根目录这份对所有 profile 生效。文件不存在就新建；
4. 把所有 `<...>` 占位符换成你本机的真实路径；
5. 重启 DSH WebUI。新会话的工具列表里应出现 `mcp__rea__*`、`mcp__win__*` 或 `mcp__kimi__*`。

**某条装不上或不想要，就把示例里那一整段删掉。** 留着一条路径不存在的配置，只会让 DSH 启动时多一条连接失败的告警。

## 三条服务器

| serverName | 用途 | 来源 | 许可 | 本仓库是否提供程序 |
| --- | --- | --- | --- | --- |
| `rea` | 逆向工程：原生二进制、APK、.NET、Electron/JS、WASM、固件、网页等 | npm `rea-agents`，[github.com/morluto/rea](https://github.com/morluto/rea) | MIT | 否，自己 `npm i -g` |
| `win` | Windows 桌面操作：截图、UI 树、键鼠、窗口、文件、进程 | PyPI `windows-mcp`，[github.com/CursorTouch/Windows-MCP](https://github.com/CursorTouch/Windows-MCP) | MIT | 否，自己 `uv tool install` |
| `kimi` | 基于无障碍树的精确桌面控制，兼容多显示器和 Electron | Kimi 官方发布的 KimiCU 程序 | **无公开许可** | 否，请自行从 Kimi 官方获取 |

作者实测版本：rea-agents 6.8.0、windows-mcp 0.8.8、KimiCU 0.3.13。其他版本未测。

### rea

```powershell
npm i -g rea-agents
npm root -g          # 示例里 <NPM_GLOBAL_ROOT> 就填这个输出
```

`command` 填 `node.exe` 的完整路径，`args` 第一项填 `<npm root -g 的输出>\rea-agents\scripts\rea.mjs`。

rea 本体约 280 MB。它的很多功能还要靠外部工具，每个工具对应 `env` 里的一行：

| 环境变量 | 外部工具 |
| --- | --- |
| `JAVA_HOME` | JDK 21（Ghidra、JADX、apktool 需要） |
| `GHIDRA_INSTALL_DIR` | Ghidra |
| `REA_JADX_MCP_JAR` | jadx-headless-mcp 的 jar |
| `REA_APKTOOL_COMMAND` | apktool |
| `REA_WABT_BIN_DIRECTORY` | WABT 的 bin 目录 |
| `REA_ADB_PATH` | Android platform-tools 里的 adb |
| `REA_BROWSER_EXECUTABLE` | Chrome 或 Edge |
| `TMP` / `TEMP` | 一个短路径的临时目录，避免长路径和权限问题 |

用不到的工具不用装，把对应的行删掉即可，rea 的其余功能照常可用。rea 不需要任何 key。

rea 配套的 5 个技能（例如 `reverse-engineer-anything`）由 [skills/install-skills.ps1](../skills/install-skills.ps1) 安装，不需要另外处理。

### win

```powershell
uv tool install windows-mcp
uv tool dir --bin    # 示例里 <UV_TOOL_BIN_DIR> 就填这个输出
```

示例里的 `--exclude-tools PowerShell,Registry` 是作者有意加的：DSH 已经有自己的 shell 工具，这里不再给 agent 第二条执行任意命令或改注册表的通道。想要这两个工具可以去掉这个参数，但要清楚扩大了什么。

### kimi（KimiCU）

KimiCU 是闭源程序，作者没找到允许再分发的许可，所以本仓库不提供下载链接或安装包。需要的话，请自行从 Kimi 官方渠道获取并安装，然后把示例里的 `command` 指向安装目录下的 `kimi-cu.exe`。

KimiCU 和 win 的功能有重叠。只想要一个桌面控制工具的话，二选一即可。

## 安全提示

- `win` 和 `kimi` 能直接操作你的鼠标、键盘和窗口。agent 运行时，屏幕上的一切都可能被看到、被点到；
- 本配置默认权限是 `danger-full-access` + 审批 `never`（见 README 的安全提示），MCP 工具调用同样不会弹审批；
- 示例配置里不应出现任何 key 或 token。三条服务器本身都不需要 key。
