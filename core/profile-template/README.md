# profile-template（占位）

> **这个目录是占位，真实模板由发布流程的另一个 agent 填充。**
> 本文件不包含、也不应该包含真实的 patch 内容（441 行的 YAML 不在这里维护）。

## 真实模板必须包含的 4 个文件

| 文件 | 作用 | 来源 |
| --- | --- | --- |
| `package.json` | profile 的依赖 + `dsh.profile.bundles`（有序 bundle 名单） | 从作者 profile 导出后做可移植化处理 |
| `pnpm-lock.yaml` | 精确依赖图；`-FrozenLockfile` 依赖它 | 作者 profile 的 lockfile |
| `pnpm-workspace.yaml` | `nodeLinker: hoisted`、`allowBuilds`、`overrides` | 作者 profile |
| `cordis.patch.yml` | profile 自己的 patch 层（作者的用户级覆盖） | 作者 profile |

可选：`cordis.yml`。若提供，`install.ps1` 会一并复制；不提供时脚本补一个 `[]`。

## 填充方必须遵守的规则

1. **只用标准 YAML**：不要引入 `!!js` 之类的 DSH 自定义标签（本发布包的脚本与模板都不使用它们）。
   例外：从上游 bundle 继承来的表达式会出现在 `--dump-config` 产物里，那是运行时合成结果，不是模板文件。
2. **禁止绝对用户路径**：不能出现 `C:\Users\<某人>\...`。必须与机器相关的项
   （MCP 可执行文件、浏览器路径、工具目录）应改成占位符 + README 说明，
   或干脆不进模板。
3. **禁止凭据**：`token`、`apiKey`、`.credentials.yaml` 一律不出现在模板里。
4. **禁止 `link:` 指向发布包外部**：本机 profile 里有
   `"dsh-session-stats-panel": "link:<本机目录>"`，
   朋友的机器没有该目录。发布前必须改成已发布版本（例如 `^2.2.2`），
   或把该包一起放进发布包并改成相对路径。`install.ps1` 会检查这一点并直接失败。
5. **两个远程插件必须默认禁用**（作者决定）：
   `cordis.patch.yml` 里应有
   ```yaml
   - id: web-ui-remote-bridge
     disabled: true
   - id: web-ui-task-board-remote
     disabled: true
   ```
   若模板漏了，`verify.ps1` 会 FAIL，可按提示运行 `harden.ps1 -Apply` 补齐。
6. **版本写死要注明原因**：例如 `overrides.'@openai/codex': 0.166.0`
   （0.153.4 对 ChatGPT 账号返回 `model_not_found`）。
7. **id 不得重复**：同一插件既在某个聚合包里又出现在 `bundles`/dependencies，
   会让合成树出现重复顶层 id，启动可能硬失败。

## 填充后自检

```powershell
# 1) 四件套齐全
Get-ChildItem .\profile-template | Select-Object Name, Length

# 2) package.json 可解析且 bundles 非空
(Get-Content .\profile-template\package.json -Raw | ConvertFrom-Json).dsh.profile.bundles.Count

# 3) 没有绝对用户路径、没有 link: 指向外部
Select-String -Path .\profile-template\* -Pattern 'C:\\Users\\|link:[A-Za-z]:/' -SimpleMatch:$false

# 4) 用真实 DSH 合成一次（不写安装目录）
.\install.ps1 -DshHome "<临时 DSH_HOME>" -DryRun
```

## 为什么不在仓库里放真实 YAML

- 441 行的 patch 属于「作者本机的用户级覆盖」，会随插件升级频繁变化；
- 放进仓库会产生两份真相（仓库一份、profile 一份），冲突时难以判断；
- 正确做法是：由发布流程从作者 profile 导出 → 去除不可移植项 → 生成模板 → 由
  `install.ps1` 铺到目标机器，再用 `verify.ps1` 以合成树为准做验收。
