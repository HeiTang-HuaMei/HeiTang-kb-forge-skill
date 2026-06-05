# 稳定版多 Provider LLM 层

v2.0 默认保持离线 provider 行为。稳定版 provider policy 默认使用 mock provider、禁用网络访问、要求 audit log，并避免保存真实 API key。

`provider-health` 检查本地 provider registry，报告 mock 或 disabled provider 是否可用。`openai_compatible` 仍是可选增强，测试不得依赖真实 API。
