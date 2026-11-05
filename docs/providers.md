# 添加你自己的模型 provider

作者自用的第三方中转 provider 已经从模板里删掉。装好后，你需要在自己 profile 的 `cordis.patch.yml` 里加上你的 provider，再把默认模型指向它。

文件位置：`<DSH_HOME>\profiles\web\cordis.patch.yml`。可以直接复制 [examples/providers.example.yml](../examples/providers.example.yml) 的内容，改占位符后追加到这个文件末尾。

改之前先关掉 DSH WebUI，改完再启动。WebUI 运行中改 profile 文件会触发半途重挂。

## 两条硬规则

1. **API key 绝不写进 yml。** yml 里只写环境变量的**名字**（`apiKeyEnv: MY_PROVIDER_API_KEY`），不写值。
2. key 的值放在以下两处之一：
   - 系统或用户环境变量，例如在 PowerShell 里执行 `[Environment]::SetEnvironmentVariable('MY_PROVIDER_API_KEY', '<你的 key>', 'User')`，然后重开终端并重启 DSH；
   - DSH 的凭据库：在 WebUI 设置里按 provider 填 key，DSH 会存进 `<DSH_HOME>` 下的 `.credentials.yaml`。这个文件不要提交到任何仓库。

## 字段说明

provider 写在 `llm-pi-ai` 这一行的 `config.providers` 下面，键名就是 provider id（自己起，只用小写字母、数字、连字符）。

| 字段 | 必填 | 含义 |
| --- | --- | --- |
| `apiKeyEnv` | 是 | 存放 key 的环境变量名，例如 `MY_PROVIDER_API_KEY` |
| `api` | 是 | 接口协议。OpenAI 兼容用 `openai-completions`；Anthropic 兼容用 `anthropic-messages` |
| `baseURL` | 是 | 中转地址。OpenAI 兼容一般以 `/v1` 结尾；Anthropic 兼容一般写到根路径（以 `/` 结尾），以服务商文档为准 |
| `models` | 是 | 模型列表 |
| `models[].id` | 是 | 发给服务商的模型名，要和服务商文档一致 |
| `models[].name` | 否 | 界面上显示的名字，不写就用 id |
| `models[].contextWindow` | 否 | 上下文长度（token） |
| `models[].maxTokens` | 否 | 单次输出上限（token） |
| `models[].input` | 否 | 支持的输入类型，`text`、`image` |

`contextWindow` 和 `maxTokens` 填错不会报错，但会影响上下文压缩时机和输出截断。请按服务商给的数字填。

## 设为默认模型

`agent-default-model` 这一行决定新会话默认用哪个模型：

```yaml
- id: agent-default-model
  name: "@deepseek-ai/dsh-agent-default-model"
  config:
    provider: my-openai-relay   # 上面 providers 里的键名
    model: <MODEL_ID>           # 该 provider models 里的某个 id
```

profile 里应只有一行 `id: agent-default-model`。如果文件里已经有，就改原来那行，不要再加一行。

## 验证

1. 重启 DSH WebUI，打开 `web` profile；
2. 新建会话，在模型选择器里应能看到你的 provider 和模型；
3. 发一句话。报 401/403 多半是 key 没读到（环境变量设了但没重启 DSH，或名字拼错）；报 404 多半是 `baseURL` 或模型 id 写错。

## 不要做的事

- 不要把 key 写进 `cordis.patch.yml`、`package.json`、`.npmrc` 或任何会被提交的文件；
- 不要把带 key 的截图、日志、`.credentials.yaml` 发给别人；
- 不要为了图省事把别人的中转地址抄进来。用你自己有合同或账号的服务。
