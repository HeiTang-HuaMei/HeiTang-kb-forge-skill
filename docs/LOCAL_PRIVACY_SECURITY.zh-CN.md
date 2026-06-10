# 本地隐私与安全

当前 Core package 版本：`4.1.0`
当前 stable release：`v4.0.0`
当前 release candidate line：`v4.1.0`

当前阶段：v4.1.0 Parser/OCR industrial release candidate，已完成 P2.1 hardening；stable v4.0.0 / v4.0 tag 保持不变。

HeiTang KB Forge Core 默认 local-first。

## 默认行为

- Local-first default：source documents、packages、generated documents、memory reports、indexes 和 audit reports 写入本地 workspace/output folders。
- No platform-hosted user data：Core repo 不提供 SaaS hosting、team accounts 或平台托管用户数据。
- LLM optional only：Core features 和 tests 必须在没有 LLM provider 配置时仍可使用。
- No hidden upload：除非未来显式、审查过、opt-in 的功能声明，否则命令不得上传文档或生成包。
- Tests 不需要真实 LLM/API/network：确定性本地路径和 offline fallback 是必需边界。

## Storage Boundary

默认 storage backend 是 `local_workspace`。

`local_db` 和 `byo_cloud` 这类 future-compatible 名称不是当前默认实现。只有完成实现、安全 review、测试和文档后，才可以描述为已实现能力。

## Secret Handling

Provider credentials 应通过 `api_key_env` 等环境变量名引用。Reports 不得存储 raw API keys。Live provider smoke 是 opt-in，不应在 CI 中默认运行。

## Network Boundary

部分可选 provider/platform commands 包含显式 network flags。最终审计会把 unexpected network/cloud behavior 视为 P0。文档中的 URL 或说明不是 hidden upload，但任何 runtime upload path 都必须显式、默认关闭并经过测试。

## Agent and Memory Boundary

KB-bound agents 不得访问 unauthorized KB。Child Agent private memory 默认必须隔离，只有显式启用 workflow shared memory 才能共享。默认不得注入 all-history memory。

## v4.0 Gate

如果存在 secret leakage、hidden upload、platform-hosted data overclaiming、测试依赖真实 LLM/API/network、不安全 memory boundary 或 docs/UI false claims，最终门禁不得输出 `ready_for_v4_rc`。
