# 给安装 agent 的执行手册（agent-setup）

> 目标读者：拿到这个仓库、准备替人安装的 AI agent。
> 你不需要理解所有插件，按顺序执行、按菜单判断即可。
> 人类可以读，但这是写给 agent 的操作序列。

---

## 0. 先确认三件事（缺一不可）

| 项 | 要求 |
| --- | --- |
| 操作系统 | **Windows 10/11 x64**。这套配置里的 `dsh-tui`、`dsh-win-bash`、两个 MCP 都是 Windows 专用；macOS/Linux 请停在这里并告知用户 |
| Node.js | **≥ 24**（作者验证：`24.22.1`） |
| pnpm | **11.x**（作者验证：`11.28.9`） |

```powershell
node --version
pnpm --version
```

---

## 1. 读菜单，不要自己发明

```powershell
Get-Content .\core\menu.json -Raw | ConvertFrom-Json
```

- `default`：默认开启，不要动。
- `optional`：**已安装但默认关闭**，只在用户明确要时打开；每条有 `needs`，缺依赖就告诉用户"缺什么"，不要硬开。
- `excluded`：**不提供**（作者本机已禁用），除用户点名外不要碰。

> 特别注意：`@linxin666/dsh-remote-bridge` 会建公网隧道、`@eddyskywalker/dsh-chatgpt-subscription` 会读其他应用的登录凭证。除非用户明确要求并理解后果，否则保持关闭。

---

## 2. 安装顺序（严格按序）

```powershell
# 2.1 先干跑：只检查，不写文件
.\core\install.ps1 -DshHome "<DSH_HOME>" -DryRun

# 2.2 正式安装（会备份现有 profile 到 .backup-install-<时间戳>）
.\core\install.ps1 -DshHome "<DSH_HOME>"

# 2.3 验证
.\core\verify.ps1 -DshHome "<DSH_HOME>"

# 2.4 安装技能（46 个，默认跳过 6 个未验证/无版权人）
.\skills\install-skills.ps1 -DshHome "<DSH_HOME>" -DryRun
.\skills\install-skills.ps1 -DshHome "<DSH_HOME>"

# 2.5 收紧（默认就关掉两个远程插件；如用户要全开，跳过）
.\core\harden.ps1 -DshHome "<DSH_HOME>" -Apply
```

`<DSH_HOME>`：独立 WebUI 版通常是 `<安装根>\home`；`dsh web` 单机版通常是 `$env:USERPROFILE\.dsh`。**不确定就问用户，不要猜。**

---

## 3. 每一步失败了怎么办

| 现象 | 原因 | 处理 |
| --- | --- | --- |
| `'pnpm' is not recognized` | 没装或不在 PATH | 装 pnpm 11，重开终端 |
| `ERR_PNPM_UNEXPECTED_STORE` | 这台机器有多个 pnpm store（v10/v11） | `pnpm store prune` 或统一 `storeDir`，重试 |
| `cpu-features` 编译失败 | 缺 MSVC/编译器 | **忽略**：它是 ssh2 的可选依赖，会静默降级，不影响功能 |
| `skipping profile bundle` | 某插件声明的 DSH 版本不满足 | 看 stderr 里的包名；不要强改 `engines.dsh` 掩盖 |
| `duplicate exact route` | 同一插件被挂载两次 | 检查是否既在 `bundles` 又被 patch insert；二选一 |
| `patch: entry "tool-ralph" not found` | TUI 的良性无效补丁 | **忽略**，基线本来就有 |
| 启动后界面空白/少面板 | profile 没被选中 | 确认 `--profile <name>` 与目录名一致 |

---

## 4. 验证通过的判据

1. `verify.ps1` 输出全 PASS（WARN 可接受）；
2. 浏览器打开 GUI，会话页能新建会话；
3. 侧栏能看到任务板、用量、会话统计、技能中心；
4. 设置页有「Web UI」分组；
5. `harden.ps1 -Apply` 后，远程桥和任务板远程两个面板不出现。

---

## 5. 禁止事项

- **不要**把 `.credentials.yaml`、`.npmrc`、`sessions/`、`storages/`、`attachments/` 提交到任何仓库；
- **不要**用 `rm -rf` / `Remove-Item -Recurse` 删 profile，用脚本自带的备份与回滚；
- **不要**为了"让它跑起来"改 `engines.dsh` 或 `peerDependencies`——那只会把错误推迟；
- **不要**默认开启 `excluded` 里的插件；
- **不要**在 WebGUI 运行中改 profile 文件（HMR 会半途重挂）。

---

## 6. 完成后的汇报模板

```
安装完成：DSH <版本> / Node <版本> / pnpm <版本>
profile：<DSH_HOME>\profiles\<name>
entry：<verify 输出条数>，重复 id：0
技能：<n>/46（跳过：<列表>）
收紧：remote-bridge=off，task-board-remote=off
未解决：<逐条，含原始报错>
```
