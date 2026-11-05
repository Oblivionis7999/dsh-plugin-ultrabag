# 合成树自检：DSH 配置白名单

这个目录放的是自检工具：一份白名单 `expected-ids.json` 和对比脚本 `compare.ps1`。检查对象是 DSH 把所有
bundle 和 patch 叠加完之后得到的"最终入口树"。

## 这是什么东西（给非技术读者）

DSH 启动前会把很多个配置包（bundle）一层层叠起来，再让补丁（patch）在上面增删改，最后算出一张
"到底装了哪些功能、哪几个是关着的"的清单。`--dump-config` 干的事，就是**不启动服务**、只把这张
算完的清单原样打印出来。

所以它是一张**成品照片**，不是配方。拿白名单对照这张照片，就能看出"漏装了 / 被关掉了 / 多装了不该有的"。

## 怎么生成你自己那份

在 DSH 安装目录（能看到 `node_modules/@deepseek-ai/dsh` 的那一级）执行：

```powershell
# Windows PowerShell
node --expose-internals node_modules/@deepseek-ai/dsh/lib/bin.js --profile web --dump-config > my-dump.txt 2> my-dump.err
```

```bash
# Git Bash / WSL
node --expose-internals node_modules/@deepseek-ai/dsh/lib/bin.js --profile web --dump-config > my-dump.txt 2> my-dump.err
```

> ⚠️ **两点必须知道**
> 1. `--dump-config` 会重写 profile 根目录的 `cordis.yml`，把它变成空数组 `[]`。这是正常行为，不是损坏；
>    但如果你那份 `cordis.yml` 里手写了东西，先备份。
> 2. `--dump-config` **故意不求值** `!!js ...` 表达式，原样打印。所以两边看到的 `!!js` 是同一段文本，
>    不代表实际运行时它们算出了什么。

生成的 `my-dump.txt` 有两千多行，一眼看不懂是正常的。用下面的脚本自检。

## 仓库里有什么、没有什么

- **有**：`expected-ids.json`，一份白名单。只列“装好这套配置后必须存在 / 必须关闭 / 不应出现”的关键 id，
  不含模型和 provider 条目。`core\verify.ps1` 和本目录的 `compare.ps1` 都读它。
- **没有**：完整的合成树 dump。全树里有作者本机路径和个人订阅的模型清单，不随仓库发布；
  条目总数也会随 DSH 和插件版本变化，不适合当判定标准。

## 怎么自检

```powershell
# 默认：对照同目录 expected-ids.json，报告缺失 / 未禁用 / 不应存在 / 重复 id
.\compare.ps1 -Mine .\my-dump.txt

# 指定别的白名单
.\compare.ps1 -Mine .\my-dump.txt -Expected .\my-expected.json
```

退出码 `0` 表示白名单全部通过，`1` 表示有问题。

## 两份 dump 全树对比（可选）

手上有另一份 dump（比如另一台机器、升级前导出的）时，可以做 id 级全树对比：

```powershell
# 新增 / 缺失 / disabled 变化
.\compare.ps1 -Mine .\my-dump.txt -Full -Reference .\other-dump.txt

# 连“位置变化”一起看（bundle insert 顺序也会影响组合结果）
.\compare.ps1 -Mine .\my-dump.txt -Full -Reference .\other-dump.txt -IncludeOrder
```

脚本不打印整行 diff，只报告**条目级**结论，因为两千行文本 diff 里绝大多数是路径和版本噪音。
条目总数不同只作提示，以 id 级差异为准。

## 全树对比时哪些差异是**正常**的

| 差异 | 为什么正常 |
| --- | --- |
| 路径不同 | 每台机器的安装根、用户目录不一样。这类差异全部忽略。 |
| `# == ... patched by ...` 注释头 | 只是注明“这一块被哪个补丁改过”，其中的安装根不同不影响任何行为。 |
| 一边多出来的 `- id:` | 自己在 `cordis.patch.yml` 里加的东西。列出来看看是不是想要的。 |
| `rea-mcp` / `windows-mcp` / `kimi-cu-mcp` 等 MCP 条目 | 装了对应本地 MCP 服务才会有。**这是环境差异，不是配置错误。** |
| `disabled: !!js ...` 两边文字一致 | 说明条件表达式相同，实际开关取决于运行时上下文，比对到此为止。 |
| 模型列表条目数不同 | 各人挂的模型和订阅不同。 |
| 同一个 bundle 下条目增删 | 先确认**两边 DSH 版本一致**。版本不同时，bundle 内容本来就会变，先对齐版本再比。 |

## 哪些差异**需要警惕**

- **`disabled` 从 `on` 变成 `off`**：某个功能被关掉了，而你没印象关过，大概率是补丁互相覆盖。
- **白名单里的条目你这里没有**：某个 bundle 没装上，或者被 `dsh.profile.bundles` 漏掉了。
- **同一个 id 出现两次**：同一插件被双挂载，这是最危险的一种，通常直接导致启动失败
  （典型报错 `webserver: duplicate exact route`）。

## 白名单本身

- 验证于 DSH `0.2.1-rc.5`，profile `web`（见 `expected-ids.json` 的 `verifiedWith`）。
- 梁神模式、调度模式没有独立的 `preset-*` 顶层 id，白名单里用声明它们的插件入口
  `web-ui-liangshen`、`dsh-chatgpt-subscription` 代替。
- 想加自己的检查项，复制一份改，再用 `-Expected` 指过去；`core\verify.ps1` 对应参数是 `-ExpectedIdsFile`。
