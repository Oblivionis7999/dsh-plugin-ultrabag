# 使用指南：装好以后，东西在哪、怎么用

这套配置除了 DSH 本身，还装了一堆“外挂”：插件、预设、技能、MCP。这份指南一个个讲：它能帮你干什么、在界面哪里点、要准备什么、默认开没开。

不用从头读到尾。先看下面「先看这里」，其余的用到哪个再翻哪个。

界面上的按钮名按 DSH 0.2.1-rc.5 写的（具体版本见 [compat.md](compat.md)）。你的版本不一样，按钮位置可能也不一样。有几处我没查到确切位置，就写了“入口以实际界面为准”，你在界面里找找就行。

## 目录

- [先看这里：通用操作](#common)
- [一、界面增强](#ui)
  - [小鲸鱼记账挂件 dsh-whale-widget](#whale-widget)
  - [推理等级滑条 dsh-codex-effort-slider](#effort-slider)
  - [提示词增强 dsh-prompt-enhance](#prompt-enhance)
  - [选中批注 dsh-annotation](#annotation)
  - [Web 扩展设置 web-ui-settings](#web-ui-settings)
  - [兼容层 web-ui-compat](#web-ui-compat)
  - [编辑并重发 web-ui-message-edit](#web-ui-message-edit)
  - [俄语语言包 web-ui-i18n](#web-ui-i18n)
  - [实时浏览器视图 web-ui-browser-view](#web-ui-browser-view)
  - [桌面宠物 web-ui-pet](#web-ui-pet)
  - [皮肤中心 web-ui-skin-center](#web-ui-skin-center)
  - [语音输入 voice-input](#voice-input)
  - [思考过程翻译 cot-translation](#cot-translation)
- [二、会话与统计](#sessions)
  - [会话统计 dsh-session-stats-panel](#session-stats-panel)
  - [会话复盘 dsh-session-insights](#session-insights)
  - [使用统计 web-ui-usage](#web-ui-usage)
  - [会话归档 web-ui-session-archive](#web-ui-session-archive)
  - [会话搜索 session-search](#session-search)
  - [随对话更新的标题 session-titles](#session-titles)
- [三、任务与协作](#tasks)
  - [任务看板 web-ui-task-board](#web-ui-task-board)
  - [GitHub Issues 同步 web-ui-task-board-github](#web-ui-task-board-github)
  - [团队协作 web-ui-task-board-team](#web-ui-task-board-team)
  - [Agent 小队 web-ui-agents](#web-ui-agents)
  - [智能体团队 agent-team-profile](#agent-team)
  - [自动审查 auto-review](#auto-review)
  - [远程桥接 web-ui-remote-bridge（默认关）](#web-ui-remote-bridge)
  - [任务看板远程面 web-ui-task-board-remote（默认关）](#web-ui-task-board-remote)
- [四、模型与订阅](#models)
  - [ChatGPT 订阅 dsh-chatgpt-subscription](#chatgpt-subscription)
- [五、子智能体](#subagents)
  - [Codex 子智能体 subagent-codex](#subagent-codex)
  - [Claude Code 子智能体 subagent-claude-code](#subagent-claude-code)
  - [Ralph 循环 ralph](#ralph)
- [六、开发工具与插件管理](#devtools)
  - [终端界面 dsh-tui](#dsh-tui)
  - [Git 分支与提交图 web-ui-git-graph](#web-ui-git-graph)
  - [Git 工作树 tool-worktree](#tool-worktree)
  - [Windows 私有 bash web-ui-win-bash](#web-ui-win-bash)
  - [SSH 远程 web-ui-ssh](#web-ui-ssh)
  - [技能中心 web-ui-skill-explorer](#web-ui-skill-explorer)
  - [插件管理增强 web-ui-plugin-manager](#web-ui-plugin-manager)
  - [创意工坊 web-ui-market](#web-ui-market)
  - [社区插件索引 web-ui-community-plugins](#web-ui-community-plugins)
  - [预设中心 web-ui-preset-center](#web-ui-preset-center)
  - [官方自定义插件市场 plugin-market](#plugin-market)
- [七、预设](#presets)
- [八、技能](#skills)
- [九、MCP（可选）](#mcp)
- [附：默认状态总表](#summary-table)

---

<a id="common"></a>
## 先看这里

### 装完第一次打开，先做这三件事

1. **配一个能用的模型。** 这套配置不带任何模型账号。点左下角的设置，找到模型或服务商那一栏，填上你自己的 API key（就是服务商给你的那串密码）。想接自己的中转站，照 [providers.md](providers.md) 写。
2. **发一句话试试。** 新建一个会话，随便问一句。能回话，说明模型通了。
3. **看一眼左侧栏。** 任务看板、使用统计、技能中心这些面板都在这儿。哪个用不上，后面教你怎么关。

### 最常用的五个功能

| 功能 | 能帮你干什么 |
| --- | --- |
| [任务看板](#web-ui-task-board) | 把要做的事写成卡片，让 AI 一张张去做 |
| [会话统计](#session-stats-panel) | 看这次对话花了多少 token、多少钱 |
| [编辑并重发](#web-ui-message-edit) | 话说错了，改完重新发，不用新开会话 |
| [提示词增强](#prompt-enhance) | 你随便写一句，它帮你改成 AI 更听得懂的说法 |
| [技能](#skills) | 现成的“做事方法”，比如写测试、做 PPT，聊天时提一句它就会用上 |

### 插件怎么开、怎么关

左侧栏点「插件」，打开插件页。下文说的“插件页”都是这里。

- **整包开关**：比如 `dsh-prompt-enhance` 和各个官方实验包。在插件页找到它，拨一下开关就行。
- **单个小插件**：名字是 `web-ui-` 开头的那些，都装在 `@linxin666/dsh-web-all` 这个大包里。在插件页点开这个大包，下面会列出一排小插件，单独拨。

拨完会自动记进你的配置文件 `cordis.patch.yml`。会改文件的人也可以手改：在对应条目下面加一行 `disabled: true` 就是关，删掉这行就是开。手改之前先把 WebUI 关掉，改完再打开。

**要不要重启？** 装包、卸包、手改配置文件，都要把 WebUI 整个关掉重开，再刷新浏览器。插件里的普通设置项改了马上生效，不用重启。

### 安全提醒，请一定看

这套配置默认给了 AI 最大权限，而且不弹确认框。意思是它想读写哪个文件、跑什么命令，都不会先问你。

想让它每次动手前先问你，就运行 `core\harden.ps1 -Apply`。改了之后有个副作用：子智能体、定时任务、Ralph 这类你不在旁边盯着的 AI，会卡在“等你点同意”那一步。详细说明见 [known-issues.md](known-issues.md) 第 7 条。

---

<a id="ui"></a>
## 一、界面增强

<a id="whale-widget"></a>
### 小鲸鱼记账挂件 `dsh-whale-widget`

右下角那只小鲸鱼，帮你盯着钱：DeepSeek 账户还剩多少、今天花了多少、刚才这一轮花了多少。

- 余额每 60 秒自己刷新一次，想马上看就点一下鲸鱼。
- 每轮对话结束，鲸鱼旁边会冒个泡泡，写着这一轮花了多少。
- 点开鲸鱼的菜单，可以换角色、调大小。音效和各种提示在「音效与提示 → 全局设置」里调，自己的图片和音频在「资源管理」里换。
- 菜单按钮被藏起来了的话：电脑上右键鲸鱼，手机上按住鲸鱼 1.5 秒左右。

**要准备的**：想看余额，得先在 DSH 里填好 DeepSeek 的 API key，或者登录 DSH 账号。都没有的话余额出不来，但“每轮花了多少”还是会按用量估算出来。它会联网查余额，也会联网检查自己有没有新版。

**默认开着。** 不想要就去插件页关掉 `dsh-whale-widget`，然后重启。

鲸鱼的图片和音效版权归原作者，只能跟着插件一起用，别单独拿去发。

<a id="effort-slider"></a>
### 推理等级滑条 `dsh-codex-effort-slider`

让你拖一下就能调 AI “想多深”。

点输入框里的模型按钮，弹出的菜单里有一行「推理等级」，这个插件把它变成一根彩色滑条。按住往左往右拖，停在哪档就是哪档。在滑条上点右键能打开设置：动画、刻度点、复制诊断信息、恢复默认，都在这儿。

当前模型不支持推理等级的话，这一行本来就不会出现，跟插件没关系。

**默认开着。** 关掉：插件页关 `dsh-codex-effort-slider`，重启。

<a id="prompt-enhance"></a>
### 提示词增强 `dsh-prompt-enhance`

你随手写一句，它帮你改成 AI 更容易听懂的说法。改完先给你看对比，用不用你说了算。

1. 在输入框里把想说的话写好，写得乱一点也没事。
2. 点发送键旁边的「增强」小按钮，或者按 `Ctrl+Alt+E`。
3. 屏幕上左边是你写的，右边是改过的。觉得好就接受，原来那句会被换掉；不满意可以撤销。

另外还有个用法：在输入框打 `/enhance`，后面跟一段话，它只帮你改写这段话，不会算进对话记录里。

每改一次要调用一次模型，所以会花一点钱。默认用你当前聊天的那个模型，想换成别的，去「设置 → 插件配置」找 `prompt-enhance`。快捷键也在那儿改。

**默认开着。** 关掉：插件页关 `dsh-prompt-enhance`，重启。

<a id="annotation"></a>
### 选中批注 `@changfenhuang/dsh-annotation`

AI 回了一大段，你只对其中几句有意见？用它圈出来写批注，AI 会一条条回答你。

1. 在 AI 的回复里，用鼠标把那句话选中。
2. 弹出一个小框，写上你的意见。原文那里会出现一个编号，并被标亮。
3. 想批几处就批几处，最后按回车，这些批注会跟你的消息一起发出去。

侧边栏里预览工作区文件的时候也能这样批。

**默认开着。** 关掉：插件页关 `@changfenhuang/dsh-annotation`，重启。

<a id="web-ui-settings"></a>
### Web 扩展设置 `web-ui-settings`

`web-ui-` 开头的那一大家子插件，设置都收在这里。

打开「设置」，左边会多出一栏「Web 扩展」，下面有「Web 插件」「皮肤」「宠物」「创意工坊」「使用统计」这些标签。想改哪个插件的设置，就进「Web 插件」找它那张卡片。

**默认开着，别关。** 任务看板、使用统计、SSH 这些插件的设置都挂在它下面，关了就找不到了。

<a id="web-ui-compat"></a>
### 兼容层 `web-ui-compat`

后台的小零件，你不用管。它给页面加了一些接口，别的插件和皮肤要靠它才能正常显示。

**默认开着，别关。** 关了以后，有些插件的页面布局可能会乱。万一真要关：插件页点开 `@linxin666/dsh-web-all`，在下面的列表里找 `web-ui-compat`。

<a id="web-ui-message-edit"></a>
### 编辑并重发 `web-ui-message-edit`

发出去的话写错了，不用重开会话，改完再发一次就行。

1. 找到你那条消息，在那一轮的最后有个「编辑并重发」，点它。
2. 改好文字，确认。AI 会接着改过的这句重新回答。原来那一版不会丢，还留在旧分支里（分支就是同一段对话的另一个版本）。

只有纯文字的消息才能这样改。带图片、带文件的消息，还有 AI 干活时你插进去的话，都没有这个按钮，免得附件被悄悄弄丢。

**默认开着。** 关掉：插件页点开 `@linxin666/dsh-web-all`，在下面关 `web-ui-message-edit`。

<a id="web-ui-i18n"></a>
### 俄语语言包 `web-ui-i18n`

给 `web-ui-` 这一家插件补上俄语。中文和英文插件本来就带，它只多了一个俄语。

只有你把界面语言切到俄语才用得上。这套配置默认是中文，所以多半用不到。

**默认开着，不用俄语可以放心关**：插件页点开 `@linxin666/dsh-web-all`，在下面关 `web-ui-i18n`。

<a id="web-ui-browser-view"></a>
### 实时浏览器视图 `web-ui-browser-view`

让 AI 自己开浏览器、点网页，你在旁边看着它操作。

1. 直接跟 AI 说，比如：“打开 http://localhost:3000，看看首页有没有报错。”
2. 右边栏会多出一个浏览器标签，AI 点哪里、输入什么，你都能实时看到。
3. 它截的图会贴在对话里，以后翻记录还能看到。

**要准备的**：电脑上装了 Chrome 或 Edge；右边栏要展开，收起来就看不到那个标签。

**默认开着，而且开的是“接管”模式。** 接管的意思是：AI 用的是你自己正开着的那个浏览器。

> 注意：接管模式下，这台电脑上每个 DSH 会话都能看到、点击、输入你浏览器里**所有**的标签页，包括你已经登录的网站（邮箱、网银等）。
> 想让 AI 只用一个干净的临时浏览器，去「设置 → Web 扩展」找「真实浏览器」卡片，把接管关掉。

整个不想要：插件页点开 `@linxin666/dsh-web-all`，在下面关 `web-ui-browser-view`。

AI 用来操作浏览器的工具都以 `browser_` 开头，比如 `browser_navigate`（打开网址）、`browser_click`（点击）、`browser_type`（输入）、`browser_screenshot`（截图）。你不用记，直接用大白话说要干什么就行。

<a id="web-ui-pet"></a>
### 桌面宠物 `web-ui-pet`（默认关）

页面上养一只会动的小宠物。AI 在思考、在干活，它会做不同的动作。可以给它起名、摸它、喂它。

1. 去插件页点开 `@linxin666/dsh-web-all`，在下面打开 `web-ui-pet`，重启。
2. 进「设置 → Web 扩展 → 宠物」挑一只。
3. 鼠标移到宠物身上，会弹出小面板，能改名、喂食，也能把它藏起来。

<a id="web-ui-skin-center"></a>
### 皮肤中心 `web-ui-skin-center`（默认关）

给界面换个样子。可以先试穿看看效果，满意了再换上，不用重启。

打开方法：插件页点开 `@linxin666/dsh-web-all`，在下面打开 `web-ui-skin-center`，重启。然后进「设置 → Web 扩展 → 皮肤」，点一个皮肤试穿，喜欢就点应用。

它自己只带一套默认皮肤，别的皮肤要去创意工坊（dsh-market.com）下载。

<a id="voice-input"></a>
### 语音输入 `voice-input`（官方实验包）

不想打字就说话，它帮你转成文字。转写在你自己电脑上做，声音不上传。

1. 去插件页，看「语音输入」（带蓝色声波图标）有没有打开。
2. 第一次用的时候会弹窗问你要不要装模型，点「前往安装」，再点「下载并准备」，等它下完。
3. 在输入框附近找到麦克风按钮（具体位置以实际界面为准），点一下开始说话。浏览器会问你能不能用麦克风，点允许。

第一次要联网下载语音模型，下完之前用不了。

**默认开着。** 关掉：插件页关「语音输入」。

<a id="cot-translation"></a>
### 思考过程翻译 `cot-translation`（官方实验包）

有些模型“想事情”的过程是英文的。这个插件把它翻成中文（或者你想要的别的语言）。

1. 插件页「官方」那一组里找到「思考过程翻译」，点开详情。
2. 选一个翻译服务，再选目标语言。`auto` 就是跟界面语言一样，也可以填 `zh`（中文）、`en`（英文）、`ja`（日文）。保存。
3. 回到对话，点开 AI 的思考过程，翻译会自己开始。用「查看原文」「查看译文」来回切。翻译失败的话原文还在，可以点重试。

翻译服务可以选 Google、Bing（不用登录，但不保证一直能用），也可以选一个付费模型来翻。都要联网。

**默认开着。** 关掉：插件页关「思考过程翻译」。

> 注意：AI 的思考过程会发给你选的翻译服务，里面可能有你的代码和聊天细节。介意的话别开，或者选一个你信得过的模型来翻。

---
<a id="sessions"></a>
## 二、会话与统计

<a id="session-stats-panel"></a>
### 会话统计 `dsh-session-stats-panel`

看每个会话用了多少 token（AI 按字数计费的单位）、大概花了多少钱。

左侧栏点「会话统计」，中间就会出现统计页。它在侧栏里排第几行不一定，找一找就有。

价格表是插件自带的，所有计算都在你电脑上做，不联网。

**默认开着。** 关掉：插件页关 `dsh-session-stats-panel`，重启。

<a id="session-insights"></a>
### 会话复盘 `dsh-session-insights`

把你过去一段时间的聊天整理成一份报告：常做哪些事、哪里卡过、花了多少。

1. 在输入框打 `/session-insights --days 30 --locale zh-CN`，发送。`--days 30` 就是看最近 30 天。
2. AI 会分批翻你的会话记录，最后生成一份网页报告，放在 DSH 数据目录下的 `insights\runs\` 文件夹里。

几个常用的附加选项：

- 只要数字统计、不要 AI 分析：加 `--deterministic`。这样不花 token。
- 只看某个项目：加 `--project <项目文件夹>`。
- 控制报告里保留多少聊天原文：用 `--privacy`。

做分析会花当前模型的 token。

**默认开着。** 关掉：插件页关 `dsh-session-insights`，重启。生成过的报告不会自己删，想清理就跟 AI 说“帮我清理会话复盘报告”，它删之前会先问你。

<a id="web-ui-usage"></a>
### 使用统计 `web-ui-usage`

一个地方看所有模型服务商的账：每家还剩多少余额、套餐还剩多少额度、今天用了多少 token。

- 左侧栏「设置」上面有张小卡片，写着今天大概花了多少。
- 想看细的，进「设置 → Web 扩展 → 使用统计」。这里能按服务商、按模型分开看，还有最近 30 天的走势图。

想查某家的余额，得先在 DSH 里填好那家的 API key，而且要联网。只看 token 用量的话，什么都不用填。

**默认开着。** 有些服务商你不用，可以在使用统计页里把它的余额查询关掉，省得白白联网。整个关掉：插件页点开 `@linxin666/dsh-web-all`，在下面关 `web-ui-usage`。

<a id="web-ui-session-archive"></a>
### 会话归档 `web-ui-session-archive`

会话多了，左边列表太长。用它把旧会话收起来，要用时再拿出来。

1. 打开「设置 → 已归档会话」。
2. 勾上要收的会话，点归档；想拿回来，勾上点恢复。
3. 同一页还能设自动归档规则，比如多久没动过的会话自动收起来。

**默认开着，自动归档也是开的。** 只想停掉自动归档，在这一页关掉就行。整个不要：插件页点开 `@linxin666/dsh-web-all`，在下面关 `web-ui-session-archive`。

> 注意：页面上有个“物理删除”，那是把会话文件真删掉，删了找不回来。

<a id="session-search"></a>
### 会话搜索 `session-search`（官方实验包）

让 AI 能翻你以前的聊天记录。

直接跟它说就行，比如：“找一下我上周弄登录页的那次会话。”它会自己去搜。左边栏原来的搜索框还在，跟这个不冲突。

**默认开着。** 关掉：插件页「官方」那一组里关「会话搜索」。

<a id="session-titles"></a>
### 随对话更新的标题 `session-titles`（官方实验包）

自动给会话起名字，聊着聊着话题变了，名字也会跟着变。你自己改过、固定过的标题不会被它覆盖。

开着就行，不用操作。每起一次名会花一点点模型调用。

**默认开着。** 关掉：插件页关「随对话更新的标题」。

---

<a id="tasks"></a>
## 三、任务与协作

<a id="web-ui-task-board"></a>
### 任务看板 `web-ui-task-board`

把要做的事写成一张张卡片，点一下，AI 就开个新会话去做。还能定时，比如每天早上 9 点自动跑一遍。

1. 左侧栏点「任务看板」，中间会出现一列列的卡片。
2. 新建一张卡片，写个标题，再写清楚要 AI 干什么。
3. 点开卡片，右边可以选在哪个文件夹干活、用哪个预设、给多大权限、用哪个模型。
4. 点运行，AI 就开始做。想定时就给卡片设个计划时间。

懒得自己建卡的话，直接跟 AI 说“帮我建几张卡片，把这件事拆开”，它会帮你建。

看板开着的时候，官方原来的「自动化任务」入口会被藏起来，定时任务统一在看板里管。看板的设置在「设置 → Web 扩展 → Web 插件」，找任务看板那张卡片。

每跑一张卡片都会花模型额度。

**默认开着。** 关掉：插件页点开 `@linxin666/dsh-web-all`，在下面关 `web-ui-task-board`。关掉后官方的「自动化任务」会回来。

> 注意：这套配置默认给了 AI 最大权限，定时卡片会在你不在电脑前的时候自己跑。设定时之前，先确认那张卡片的权限和要它做的事没问题。

<a id="web-ui-task-board-github"></a>
### GitHub Issues 同步 `web-ui-task-board-github`

把 GitHub 仓库里的 Issue（别人提的问题或需求）自动变成看板卡片。AI 改完代码，还能帮你开 PR（提交修改的申请）。

1. 进「设置 → Web 扩展 → Web 插件」，找到任务看板卡片，里面有「GitHub Issues 同步」。
2. 填上你的 GitHub token（GitHub 网站上生成的一串访问密码），点连接测试。
3. 添加要同步的仓库，填 `用户名/仓库名`，或者直接粘贴仓库网址。
4. 设一个标签，或者设成“指派给我的”。符合条件的 Issue 会自己出现在看板上。

要能访问 GitHub。

**默认开着，但你不填 token 它什么都不做。** 关掉：在那个区块里关掉同步，或者插件页点开 `@linxin666/dsh-web-all`，在下面关 `web-ui-task-board-github`。

> 注意：token 请填在设置卡片里，它会存进 DSH 的密码库。别在聊天里把 token 发给 AI，发了就会一直留在聊天记录里。也千万别把 token 写进任何代码仓库。

<a id="web-ui-task-board-team"></a>
### 团队协作 `web-ui-task-board-team`

给有团队服务器的人用的：把你电脑上的 AI 小队接进团队，领团队的任务、在任务下面留言。

一个人用的话，这一节可以跳过。

要用的话：打开任务看板设置，找到「团队协作」，填上团队服务器地址、团队 id 和 Host Token，再选好要接进去的小队成员（成员在下一节的「Agent 小队」里建）。

**默认开着，但不填就什么都不做。** 关掉：插件页点开 `@linxin666/dsh-web-all`，在下面关 `web-ui-task-board-team`。

<a id="web-ui-agents"></a>
### Agent 小队 `web-ui-agents`

提前组好一支 AI 小队，每个成员有自己的分工，以后一键就能派出去干活。

1. 打开小队页（在侧栏还是在看板里，以实际界面为准）。
2. 新建一个小队，往里加成员。每个成员选好预设、权限、模型，再写一段话说明他负责什么。
3. 可以只派一个成员去干活；也可以点「整队运行」，给一个总目标，由队长（Lead）把活分给大家。

也可以直接跟 AI 说“帮我组一个三人小队，一个写代码、一个测试、一个写文档”，它会帮你建。

每个成员干活都花模型额度，人越多花得越多。

**默认开着。** 关掉：插件页点开 `@linxin666/dsh-web-all`，在下面关 `web-ui-agents`。

<a id="agent-team"></a>
### 智能体团队 `agent-team-profile`（官方实验包）

官方版的“AI 带队友干活”：主 AI 当队长，临时叫几个队友出来，分活、发消息、共用一个任务清单。

跟它说就行，比如：“用 Agent Teams 把这个任务分给两个队友，做完了汇总给我。”会话里会出现成员列表，点队友的名字能看他在干什么（具体位置以实际界面为准）。

每个队友都花模型额度。

**默认开着。** 关掉：插件页关「智能体团队」。

> 注意：开着它的时候，普通的子智能体工具（`subagent`、`subagent_fork`）会被换成队友工具。你要是更习惯用普通子智能体，就把它关了。

<a id="auto-review"></a>
### 自动审查 `auto-review`（官方实验包）

一种折中的权限模式：AI 每次动手前，先自己判断这一步危不危险。不危险的直接做，危险的停下来问你。

1. 在输入框找到权限菜单（或者打 `/permission`），选带 `EXP` 标记的「自动审查」，确认提示。
2. 之后 AI 每做一步都会先过一遍判断。被拦下的操作会写明原因，你点同意或拒绝。

每一步都多问一次模型，所以会慢一点、多花一点 token。

**这个包是开着的，但只是多了一个可选模式。** 你不去选，默认权限还是最大权限。关掉：插件页关 `@deepseek-ai/dsh-experimental-auto-review`。

<a id="web-ui-remote-bridge"></a>
### 远程桥接 `web-ui-remote-bridge`（默认关）

让你用手机连上电脑上的 DSH，在手机上看会话、点同意。

打开之后，左侧栏底部会多一个二维码图标（「配对 iPhone」）。点开会出现一个配对码，30 秒内有效，用配套的手机 App 扫一下就配上了。

想打开：先运行 `core\harden.ps1 -Restore`，再去插件页点开 `@linxin666/dsh-web-all`，在下面打开 `web-ui-remote-bridge`，重启。

> 注意：它默认连的是插件作者自己的中转服务器，还会下载一个叫 `cloudflared` 的程序，把你电脑上的 DSH 开个口子放到公网上。打开之前，先弄清楚它连的是谁的服务器、谁能连进来。

<a id="web-ui-task-board-remote"></a>
### 任务看板远程面 `web-ui-task-board-remote`（默认关）

配好远程桥接以后，让手机也能看、能操作任务看板。

它自己没有界面，靠远程桥接才能用。先把上面的远程桥接打开并配好对，再打开它。打开方法跟远程桥接一样。

这两个最好一起开、一起关。

---
<a id="models"></a>
## 四、模型与订阅

<a id="chatgpt-subscription"></a>
### ChatGPT 订阅 `@eddyskywalker/dsh-chatgpt-subscription`

你买了 ChatGPT 会员（Plus、Pro 这些），可以直接拿来给 DSH 用，不用另外买 API。这个包里还带了别的几家编程订阅，以及「调度模式」预设。

1. 打开「设置 → 订阅服务 → ChatGPT」。
2. 在账号那张卡片上点「登录」，浏览器会弹出来让你授权。以前在这台电脑上登过 Codex 命令行工具的，可以点旁边的「导入本机 Codex CLI 登录」，省得再登一遍。
3. 回到聊天，点模型按钮，选「Codex（ChatGPT 订阅）」下面的模型。有些线路会在输入框右边显示还剩多少额度。

要有一个还在有效期的 ChatGPT 会员，登录时要能开浏览器、能联网。

**这个包是开着的，但你不登录就用不了，也不会动你任何东西。** 不用的话，不登录就行。**别把这个包删掉**，删了「调度模式」预设也会跟着没了（见[预设](#presets)）。

> 注意：这个包会去读别的软件存的登录信息（比如 Codex、MiniMax 的登录文件），然后假装成官方 Codex 工具去用你的会员。这种用法是否违反 OpenAI 的服务条款，说不太清。不需要就别登录。需要的话，先弄明白它读了哪些东西。

想接自己买的 API key，不用这个插件，照 [providers.md](providers.md) 配。

---

<a id="subagents"></a>
## 五、子智能体

子智能体，就是主 AI 叫出来帮它干一块活的另一个 AI。干完了把结果交回来。

<a id="subagent-codex"></a>
### Codex 子智能体 `subagent-codex`（官方）

让 DSH 的 AI 把一部分活外包给 Codex（OpenAI 的编程工具）。Codex 在你同一个项目文件夹里干，干完把结果带回来。

直接说就行，比如：“把这个模块的单元测试交给 Codex 子智能体去写。”

**要准备的**：电脑上装好 `codex` 命令行工具，并且已经登录。没装的话，AI 一调用就会报错。

**默认开着。** 关掉：在插件页找到 Codex 子智能体（界面上可能显示英文名 Codex subagent），关掉。

> 注意：它默认不会停下来问你，可以直接改你项目里的文件。

<a id="subagent-claude-code"></a>
### Claude Code 子智能体 `subagent-claude-code`（官方）

跟上面一样，只是外包给 Claude Code（Anthropic 的编程工具）。

比如说：“请 Claude Code 子智能体帮我审一下这次改动。”

**要准备的**：电脑上装好 `claude` 命令行工具，并且已经登录。

**默认开着。** 关掉：在插件页找到 Claude Code 子智能体（可能显示英文名 Claude Code subagent），关掉。

> 注意：它默认也不会停下来问你。

<a id="ralph"></a>
### Ralph 循环 `ralph`（官方实验包）

适合“一直干到做完为止”的活，比如把所有测试修到通过。

它的做法是：派一个全新的 AI 去干，干一轮停下；再派一个新的接着干……每一轮的 AI 都不记得前面聊过什么，只靠项目文件夹里留下的文件知道做到哪了。

你得明确说要用它，AI 不会自己用。比如：“用 Ralph 循环把这个目录里所有测试修到通过，最多 10 轮。”**记得写上最多几轮**，每一轮都花钱，轮数多了花得不少。

**默认开着。** 关掉：插件页「官方」那一组里关「Ralph 循环」。

启动的时候日志里可能会有一行 `patch: entry "tool-ralph" not found`，不用管，见 [known-issues.md](known-issues.md) 第 5 条。

---

<a id="devtools"></a>
## 六、开发工具与插件管理

<a id="dsh-tui"></a>
### 终端界面 `@deepseek-harness-tui/dsh-tui`

DSH 的命令行版本，在黑窗口（终端）里用，不用开浏览器。另外它还悄悄改了网页版的几个默认设置，下面会说。

想用命令行版：

1. 打开终端，输入 `dsh-tui`（短一点也可以输 `dst`）回车。第一次会自己做初始化，要用到 pnpm。
2. 接着上次的会话聊：`dsh-tui --resume`，后面可以跟会话 id。
3. 检查环境有没有问题：`dsh-tui doctor`。更新：`dsh-tui update`。
4. 在命令行版里输 `/settings` 可以改它自己的设置。

网页版里没有它的入口。

**它对网页版的影响（默认开着）**：在 Windows 上把 AI 的权限开到最大、不弹确认框；换掉默认的 AI 人设提示词；顺便装上一个显示“AI 正在干什么”的状态栏插件 `dsh-working-activity`。

**怎么关**：插件页关 `@deepseek-harness-tui/dsh-tui`，重启。关掉后网页版的权限会变回 DSH 原本更严的默认值，那些你不盯着的任务（定时卡片、子智能体）可能开始卡在“等你点同意”。

这套配置“权限最大”就是从它来的，详见 [known-issues.md](known-issues.md) 第 7 条。

<a id="web-ui-git-graph"></a>
### Git 分支与提交图 `web-ui-git-graph`

给写代码的人用：开新会话前，先切到你要的 git 分支；还能看一张提交历史图。

1. 新建一个会话，选好项目文件夹。
2. 输入框上面、预设选择器的右边，有个小按钮显示当前分支。点它，可以搜分支、切分支，也能新建一个。
3. 弹出来的框最下面有「Git 图谱」，点开就是提交历史图。旁边还有新建 worktree 的入口（worktree 是同一个仓库的另一个工作文件夹，几件事可以分开改，互不干扰）。

这个分支按钮**只在空白会话里出现**，聊过几句以后就没了。

**要准备的**：电脑上装了 git，项目文件夹是个 git 仓库。

**默认开着。** 关掉：插件页点开 `@linxin666/dsh-web-all`，在下面关 `web-ui-git-graph`。

这套配置把 `@linxin666/dsh-web-all` 固定在 0.4.14 版。升到 0.4.15 这个插件会被删掉，所以别随手升级。

<a id="tool-worktree"></a>
### Git 工作树 `tool-worktree`（官方实验包）

让 AI 自己新开一个 worktree（同一个仓库的另一个工作文件夹）去改东西，好几件事可以并排做，互不打架。

跟它说：“新开一个 worktree 做这个改动。”它会建好并切过去。做完它会切回原来的文件夹，新建的 worktree 和分支都还留着，不会删。

**要准备的**：装了 git，当前项目是 git 仓库。

**默认开着。** 关掉：插件页「官方」里关「Git 工作树」。已经建好的 worktree 不会因此被删。

<a id="web-ui-win-bash"></a>
### Windows 私有 bash `web-ui-win-bash`

让 AI 在 Windows 上也能用 Linux 风格的命令（bash）。每个会话有自己的一个 bash 窗口，前后命令接得上。

你不用做什么，AI 跑命令时会自己用它。

它只在 Windows 上起作用。它开着的时候，AI 的 PowerShell 工具会被收起来；它只在权限最大的会话里干活，权限调小了它会拒绝。

**默认开着。** 关掉：插件页点开 `@linxin666/dsh-web-all`，在下面关 `web-ui-win-bash`。关掉后 PowerShell 工具会回来。

<a id="web-ui-ssh"></a>
### SSH 远程 `web-ui-ssh`

连你的远程服务器：开终端、传文件、转发端口。AI 也能直接去服务器上执行命令。

1. 左侧栏点「SSH」。
2. 点添加，填服务器地址和登录信息；电脑上已经有 `~/.ssh/config` 的话，可以直接导入。
3. 在面板里开一个终端，或者用 SFTP（传文件的功能）上传下载。
4. 想让 AI 在服务器上干活，直接说：“去某某服务器上看看磁盘还剩多少。”

**要准备的**：一台能连上的服务器，以及账号密码或密钥。没添加服务器的话，面板是空的，不影响别的。

安装时如果看到 `cpu-features` 编译失败，不用管，见 [known-issues.md](known-issues.md) 第 4 条。

**默认开着**（这个插件本来出厂是关的，这套配置帮你打开了）。关掉：插件页点开 `@linxin666/dsh-web-all`，在下面关 `web-ui-ssh`。设置在「设置 → Web 扩展 → Web 插件」的 SSH 卡片里。

> 注意：添加了服务器以后，按这套配置的默认权限，AI 可以不问你就在服务器上执行命令。

<a id="web-ui-skill-explorer"></a>
### 技能中心 `web-ui-skill-explorer`

管理你的技能：看有哪些、搜一搜、开关、新建、删除。技能是什么见下面的[技能](#skills)一节。

1. 左侧栏点「技能中心」。
2. 在「技能」标签下，能看到装了哪些技能，按来源分好了组。顶上的搜索框可以按名字或说明找。
3. 每一行有个开关。关掉以后，AI 就不会自己用这个技能，你点名它才会用。
4. 想自己写一个，可以新建，也可以复制一个现成的改。删掉的技能会先进回收站，后悔了还能找回来。

技能要先用 `skills\install-skills.ps1` 装好，这里才有东西。

**默认开着**（出厂是关的，这套配置打开了）。关掉：插件页点开 `@linxin666/dsh-web-all`，在下面关 `web-ui-skill-explorer`。

<a id="web-ui-plugin-manager"></a>
### 插件管理增强 `web-ui-plugin-manager`

让插件页能检查更新、一键升级、一键重启。

1. 左侧栏点「插件」，在「已安装」标题旁边有一排按钮，点检查更新。
2. 有新版本的插件会标出来，点开详情，照提示升级。
3. 升级完，照页面提示点重启。

检查更新要联网。

**默认开着。** 它还把官方设置里的「内置插件」那块挪到了插件页最下面。关掉：插件页点开 `@linxin666/dsh-web-all`，在下面关 `web-ui-plugin-manager`。

> 注意：这套配置有几个插件故意固定了版本，升级前请先看 [compat.md](compat.md)。比如 `@linxin666/dsh-web-all` 升到 0.4.15 会把 Git 图删掉。

<a id="web-ui-market"></a>
### 创意工坊 `web-ui-market`

一个插件商店，能下皮肤、宠物、别人做的插件和预设。东西来自 dsh-market.com，那是第三方网站，不是 DSH 官方的。

1. 打开「设置 → Web 扩展 → 创意工坊」。里面分成编辑推荐、皮肤、宠物、插件、预设五类。
2. 看中哪个点安装。皮肤和宠物装好后，关掉卡片再打开就能用；插件装好后交给插件页管理。

要联网，能打开 dsh-market.com。

**默认开着。** 卡片上有个总开关，关了就只剩那个开关。整个不要：插件页点开 `@linxin666/dsh-web-all`，在下面关 `web-ui-market`。

> 注意：这里的插件和预设是别人做的，装之前看看作者是谁、里面有什么。

<a id="web-ui-community-plugins"></a>
### 社区插件索引 `web-ui-community-plugins`

创意工坊里「插件」那一栏的清单就是它提供的。它只是一份名单，自己没有界面，也不联网，你不用管。

**默认开着。** 关掉以后创意工坊的「插件」那一栏会变空。关法：插件页点开 `@linxin666/dsh-web-all`，在下面关 `web-ui-community-plugins`。

<a id="web-ui-preset-center"></a>
### 预设中心 `web-ui-preset-center`

管理你从创意工坊下的预设（别人做好的 AI 工作方式）：装、启用、停用、卸载。

1. 打开「设置 → Web 扩展 → 创意工坊」，进「预设」那一类，下一个。
2. 点启用，它才会出现在新建会话时的预设列表里。如果预设里带了会在你电脑上跑的代码，会再弹一次框让你确认。
3. **每次重启 DSH 以后，下载的预设都会变回未启用**，要一个个重新点启用。

要能打开 dsh-market.com。

**默认开着。** 关掉：插件页点开 `@linxin666/dsh-web-all`，在下面关 `web-ui-preset-center`。

> 注意：别人做的预设可能带代码，点启用前看清确认框里写了什么。

<a id="plugin-market"></a>
### 官方自定义插件市场 `plugin-market`（官方实验包）

官方的插件市场。你可以加别的插件源（插件清单的网址），从里面装插件。

1. 左侧栏点「插件」，在「实验性插件」旁边点「更多」，找到「自定义插件市场」，打开它。
2. 插件页会多出「已安装」和「发现」两个标签。点「发现」，加一个插件源。
3. 列表里看中哪个就装哪个。

要联网，还得有一个能用的插件源。

**默认开着。** 关掉：插件页关「自定义插件市场」，「发现」那个标签会一起消失。

> 注意：只加你信得过的插件源。

---
<a id="presets"></a>
## 七、预设

预设就是一套现成的“AI 工作方式”：它怎么说话、能用哪些工具、按什么步骤干活。新建会话时，在输入框附近的预设选择器里挑一个。更细的说明见 [presets.md](presets.md)。

| 预设 | 来源 | 适合做什么 | 怎么选 |
| --- | --- | --- | --- |
| standard | DSH 自带 | 常规编码，工具以原生方式调用 | 预设选择器 |
| ptc | DSH 自带 | 工具多、调用多的任务，工具通过代码运行时调用 | 预设选择器 |
| minimal | DSH 自带 | 精简提示词和工具集 | 预设选择器 |
| cordis | DSH 自带 | DSH 内置的 cordis 预设 | 预设选择器 |
| 梁神模式 | `web-ui-liangshen` | 极简人格加固定工作纪律，默认 ptc 呈现；`mcp__*` 这类大工具族先折叠，需要时用 `tool_activate` 加载 | 预设选择器，或新建会话页模型选择器左边的拨杆 |
| 调度模式 | `dsh-chatgpt-subscription` | 先判断任务复杂度，复杂任务先澄清需求，再规划、派发子 agent、审查和验收 | 预设选择器 |

<a id="web-ui-liangshen"></a>
### 梁神模式拨杆 `web-ui-liangshen`

新建会话页上有个老虎机样式的小拨杆，拨一下，这次会话就用「梁神模式」，还会放个中奖特效。

1. 新建一个会话。
2. 在输入框那一行、模型按钮的左边，找到这个拨杆。点一下或者拖一下。
3. 不想用拨杆，也可以直接在预设选择器里选「梁神模式」。

**默认开着。** 关掉：插件页点开 `@linxin666/dsh-web-all`，在下面关 `web-ui-liangshen`。关了以后预设和拨杆都会消失，拨杆那里会显示「未找到梁神模式预设」。

> 注意：这两个预设是跟着插件来的。梁神模式要靠 `@linxin666/dsh-web-all` 里的 `web-ui-liangshen`；调度模式要靠 `@eddyskywalker/dsh-chatgpt-subscription`。把插件删了或关了，预设就从列表里没了。
> 只想用调度模式、不想用 ChatGPT 会员的话，把那个包留着，不登录就行。

---

<a id="skills"></a>
## 八、技能

技能是一份写给 AI 看的“做事方法”，告诉它某类事该按什么步骤做，比如怎么写测试、怎么查 bug、怎么做 PPT。

一共 46 个，都不在这个仓库里，要运行 `skills\install-skills.ps1` 从原作者那里下载。默认装 40 个，详细说明见 [skills/README.md](../skills/README.md)。

### 怎么触发

| 方式 | 怎么做 | 适用 |
| --- | --- | --- |
| 斜杠调用 | 在输入框输入 `/`，从建议里选技能，或直接输入 `/技能名` | 所有技能；标为“仅手动”的技能**只能**这样调用 |
| 自然语言 | 在对话里说出技能名，或描述一件和技能说明相符的事，例如“帮我诊断这个 bug” | 没有标为“仅手动”的技能，agent 会自己匹配 |
| 技能中心 | 侧栏「技能中心」里查看说明、开关模型调用 | 管理用，见[技能中心](#web-ui-skill-explorer) |

下面的表里，“仅手动”写着“是”的技能，AI 不会自己用，只能你打 `/技能名` 叫它。这是原作者这么定的，别去改。

“状态”那一列：“默认装”就是脚本默认会装；“未验证”要在运行脚本时加上 `-IncludeUnverified` 才装；“不装”是脚本怎么都不装的。

### 来自 mattpocock/skills（39 个）

| 技能 | 干什么用 | 仅手动 | 状态 |
| --- | --- | --- | --- |
| `ask-matt` | 问“我现在该用哪个技能或流程”，在这一组技能里帮你路由 | 是 | 默认装 |
| `chief-of-staff` | 在一个会话里协调多个子 agent 推进一个长期目标 | 是 | 未验证 |
| `claude-handoff` | 把当前对话交给一个后台 Claude Code agent 立即接着做（需要 claude CLI） | 是 | 默认装 |
| `code-review` | 从某个提交、分支或 tag 起审查改动，分“是否符合代码规范”和“是否符合需求”两路并行审 | 否 | 默认装 |
| `codebase-design` | 一套设计“深模块”的共用词汇，用来讨论接口、接缝和可测试性 | 否 | 默认装 |
| `diagnosing-bugs` | 难缠 bug 和性能退化的诊断流程 | 否 | 默认装 |
| `domain-modeling` | 梳理项目领域模型，编写 GLOSSARY.md 和 ADR | 否 | 默认装 |
| `git-guardrails-claude-code` | 给 Claude Code 装钩子，拦截 push、reset --hard 等危险 git 命令 | 否 | 未验证 |
| `grill-me` | 对一个计划或设计连续追问，把它问清楚 | 是 | 默认装 |
| `grill-with-docs` | 同上，并在追问过程中顺手写 ADR 和术语表 | 是 | 默认装 |
| `grilling` | 对计划、决定或想法做压力测试式追问 | 否 | 默认装 |
| `handoff` | 把当前对话压缩成交接文档，给下一个 agent 接手 | 是 | 默认装 |
| `implement` | 根据需求文档或任务单实现一块工作 | 是 | 默认装 |
| `implement-spec` | 实现 `/to-spec` 和 `/to-tickets` 产出的内容 | 是 | 默认装 |
| `improve-codebase-architecture` | 扫描代码库找可改进的结构，出一份 HTML 报告，再就你选中的一项追问 | 是 | 默认装 |
| `loop-me` | 就你想在本工作区搭的工作流追问需求（Beta） | 是 | 默认装 |
| `migrate-to-shoehorn` | 把测试里的 `as` 类型断言迁移到 @total-typescript/shoehorn | 否 | 未验证 |
| `pr` | 写 PR 描述 | 否 | 默认装 |
| `prototype` | 做一个一次性原型来回答设计问题，比如验证状态模型或界面 | 否 | 默认装 |
| `research` | 查高可信的一手资料，把结论写成仓库里的 Markdown 文件 | 否 | 默认装 |
| `retro` | 对一次编码会话做复盘 | 是 | 默认装 |
| `scaffold-exercises` | 生成练习题目录结构（题目、答案、讲解） | 否 | 未验证 |
| `setup-matt-pocock-skills` | 首次使用这组工程技能前，配置仓库的 issue 跟踪、标签和文档布局 | 是 | 默认装 |
| `setup-pre-commit` | 配置 Husky pre-commit：lint-staged、类型检查、测试 | 否 | 未验证 |
| `setup-ts-deep-modules` | 给 TypeScript 仓库接入 dependency-cruiser，约束每个包只能从入口访问（Beta） | 是 | 默认装 |
| `software-factory` | 设计“软件工厂”（它跑的任务和接入的服务）的共用语言（Beta） | 是 | 默认装 |
| `tdd` | 测试驱动开发，红-绿-重构 | 否 | 默认装 |
| `teach` | 在本工作区里教你一个新技能或概念 | 是 | 默认装 |
| `to-questionnaire` | 把你答不全的决定变成一份问卷，交给别人填 | 是 | 默认装 |
| `to-spec` | 把当前对话整理成需求文档并发布到 issue 跟踪 | 是 | 默认装 |
| `to-tickets` | 把计划或需求拆成一组带依赖关系的任务单 | 是 | 默认装 |
| `triage` | 按状态机分拣 issue 和外部 PR，写出 agent 可直接执行的说明 | 是 | 默认装 |
| `wait-what` | “刚才那段没看懂，换个说法再讲一遍” | 是 | 默认装 |
| `wayfinder` | 规划一个大到单个会话装不下的工作，拆成决策单逐个解决 | 是 | 默认装 |
| `wizard` | 生成一个交互式 bash 向导，带人完成只有人能做的步骤（需要 bash） | 否 | 默认装 |
| `writing-beats` | 写作：把素材组织成一段段推进的节拍（Beta） | 是 | 默认装 |
| `writing-for-agents` | 编写给 agent 看的文档，例如技能、AGENTS.md | 否 | 默认装 |
| `writing-fragments` | 写作：先挖出零散的素材片段，不急着成形（Beta） | 是 | 默认装 |
| `writing-shape` | 写作：把素材逐段打磨成文章（Beta） | 是 | 默认装 |

`ask-matt` 和 `setup-matt-pocock-skills` 用了上游作者的名字，这不代表他认可本仓库。

### 来自 REA（morluto/rea，5 个）

这组是配合下面的 [rea MCP](#mcp) 用的。你没装 rea 的话，基本用不上。

| 技能 | 干什么用 | 仅手动 | 状态 |
| --- | --- | --- | --- |
| `reverse-engineer-anything` | 用 REA 逆向原生程序、.NET、Electron/JS、固件、网页等，也能给网页应用生成 agent 环境 | 否 | 默认装 |
| `rea-analysis-optimization` | 优化 REA 分析流程的上下文、速度和内存占用 | 否 | 默认装 |
| `rea-changelog-update` | 从 git 历史生成或改写 REA 的发版说明 | 否 | 默认装 |
| `rea-ci-tests-audit` | 审计 REA 的 CI 和测试套件 | 否 | 默认装 |
| `rea-tool-design` | 设计或修改 REA 的工具和接口 | 否 | 默认装 |

### 来自 hugohe3/ppt-master（1 个）

| 技能 | 干什么用 | 仅手动 | 状态 |
| --- | --- | --- | --- |
| `ppt-master` | 生成可编辑的 PPTX，重建、美化或套模板，给已有演示加旁白和动画 | 否 | 默认装 |

这个技能有 38 MB，下载要等一会儿。别去改它的 SKILL.md 格式，也别删它的 LICENSE 和 SPONSORS 文件，删了它就不干活了。

### 来源不明（1 个）

| 技能 | 干什么用 | 仅手动 | 状态 |
| --- | --- | --- | --- |
| `diagram-design` | 生成各种架构图、流程图、时序图、数据图表 | 否 | 不装（版权人不明） |

---

<a id="mcp"></a>
## 九、MCP（可选）

MCP（让 AI 去操作电脑上其他软件的接口）。装了它，AI 就能做更多事，比如帮你截屏、点鼠标，或者拆开一个 exe 看里面写了什么。

下面三个都是可选的，一个不装也完全不影响正常聊天。每个都要你自己先把程序装好，这个仓库只给了一份示例配置。怎么装见 [mcp.md](mcp.md)。

| 服务器 | 是什么 | 装好后在哪里 | 前提 | 默认状态 |
| --- | --- | --- | --- | --- |
| `rea` | 逆向工程：二进制、APK、.NET、Electron/JS、WASM、固件、网页 | agent 工具 `mcp__rea__*` | `npm i -g rea-agents`；部分功能还要 JDK、Ghidra、adb 等外部工具 | 未配置 |
| `win`（windows-mcp） | Windows 桌面操作：截图、读 UI 树、键鼠、窗口、文件、进程 | agent 工具 `mcp__win__*` | `uv tool install windows-mcp` | 未配置 |
| `kimi`（KimiCU） | 基于无障碍树的精确桌面控制，支持多显示器和 Electron | agent 工具 `mcp__kimi__*` | 自行从 Kimi 官方获取程序（无公开许可，本仓库不提供） | 未配置 |

**怎么用**：配好、重启以后，直接跟 AI 说你要干什么就行。比如“截个屏看看桌面上开着什么”“分析一下这个 exe 有哪些导出函数”。它自己会去找对应的工具（名字以 `mcp__` 开头）。用梁神模式的时候，这些工具一开始是收起来的，AI 需要时会自己展开。

**怎么开、怎么关**：

- 开：把示例里对应的那一段，复制到 DSH 数据目录**最外层**的 `cordis.patch.yml` 里（注意，不是 profile 文件夹里那个），把 `<...>` 换成你电脑上的真实路径，重启。
- 关：把那一整段删掉，重启。
- 程序没装成功就别留着那段配置，不然每次启动都会多一条“连不上”的报错。

> 注意：
> - `win` 和 `kimi` 能直接动你的鼠标、键盘和窗口。AI 干活的时候，屏幕上的东西它都可能看到、点到。这两个功能差不多，装一个就够了。
> - 示例配置里，`win` 故意去掉了 `PowerShell` 和 `Registry` 两个工具，免得 AI 多一条能跑任意命令、改注册表的路。
> - 按这套配置的默认权限，AI 用这些工具时也不会先问你。

---

<a id="summary-table"></a>
## 附：默认状态总表

一张表看全部插件默认开没开、去哪关。“开”就是装好就能用；括号里写了“需要什么”的，是开着但你得先准备好那样东西；“关”是装了但默认没打开。

| 插件 | 分组 | 默认 | 开关位置 |
| --- | --- | --- | --- |
| `dsh-whale-widget` | 界面增强 | 开 | 插件页 |
| `dsh-codex-effort-slider` | 界面增强 | 开 | 插件页 |
| `dsh-prompt-enhance` | 界面增强 | 开 | 插件页 |
| `@changfenhuang/dsh-annotation` | 界面增强 | 开 | 插件页 |
| `web-ui-settings` | 界面增强 | 开 | dsh-web-all 子插件列表 |
| `web-ui-compat` | 界面增强 | 开 | dsh-web-all 子插件列表 |
| `web-ui-message-edit` | 界面增强 | 开 | dsh-web-all 子插件列表 |
| `web-ui-i18n` | 界面增强 | 开 | dsh-web-all 子插件列表 |
| `web-ui-browser-view` | 界面增强 | 开（接管真实浏览器） | dsh-web-all 子插件列表 |
| `web-ui-pet` | 界面增强 | 关 | dsh-web-all 子插件列表 |
| `web-ui-skin-center` | 界面增强 | 关 | dsh-web-all 子插件列表 |
| `voice-input` | 界面增强 | 开（首次需下载模型） | 插件页 |
| `cot-translation` | 界面增强 | 开 | 插件页 |
| `dsh-session-stats-panel` | 会话与统计 | 开 | 插件页 |
| `dsh-session-insights` | 会话与统计 | 开 | 插件页 |
| `web-ui-usage` | 会话与统计 | 开 | dsh-web-all 子插件列表 |
| `web-ui-session-archive` | 会话与统计 | 开（自动归档开） | dsh-web-all 子插件列表 |
| `session-search` | 会话与统计 | 开 | 插件页 |
| `session-titles` | 会话与统计 | 开 | 插件页 |
| `web-ui-task-board` | 任务与协作 | 开 | dsh-web-all 子插件列表 |
| `web-ui-task-board-github` | 任务与协作 | 开（需 GitHub token） | dsh-web-all 子插件列表 |
| `web-ui-task-board-team` | 任务与协作 | 开（需团队 hub） | dsh-web-all 子插件列表 |
| `web-ui-agents` | 任务与协作 | 开 | dsh-web-all 子插件列表 |
| `agent-team-profile` | 任务与协作 | 开 | 插件页 |
| `auto-review` | 任务与协作 | 开（可选权限模式） | 插件页 |
| `web-ui-remote-bridge` | 任务与协作 | 关 | `harden.ps1 -Restore` 后在 dsh-web-all 子插件列表 |
| `web-ui-task-board-remote` | 任务与协作 | 关 | 同上 |
| `dsh-chatgpt-subscription` | 模型与订阅 | 开（需登录） | 插件页；不登录即不用 |
| `subagent-codex` | 子智能体 | 开（需 codex CLI） | 插件页 |
| `subagent-claude-code` | 子智能体 | 开（需 claude CLI） | 插件页 |
| `ralph` | 子智能体 | 开 | 插件页 |
| `dsh-tui` | 开发工具 | 开（改了权限默认值） | 插件页 |
| `web-ui-git-graph` | 开发工具 | 开 | dsh-web-all 子插件列表 |
| `tool-worktree` | 开发工具 | 开 | 插件页 |
| `web-ui-win-bash` | 开发工具 | 开（仅 Windows） | dsh-web-all 子插件列表 |
| `web-ui-ssh` | 开发工具 | 开（需 SSH 主机） | dsh-web-all 子插件列表 |
| `web-ui-skill-explorer` | 开发工具 | 开 | dsh-web-all 子插件列表 |
| `web-ui-plugin-manager` | 开发工具 | 开 | dsh-web-all 子插件列表 |
| `web-ui-market` | 开发工具 | 开 | dsh-web-all 子插件列表 |
| `web-ui-community-plugins` | 开发工具 | 开 | dsh-web-all 子插件列表 |
| `web-ui-preset-center` | 开发工具 | 开 | dsh-web-all 子插件列表 |
| `plugin-market` | 开发工具 | 开 | 插件页 |
| `web-ui-liangshen` | 预设 | 开 | dsh-web-all 子插件列表 |
| rea / win / kimi | MCP | 未配置 | DSH_HOME 根目录的 `cordis.patch.yml` |
