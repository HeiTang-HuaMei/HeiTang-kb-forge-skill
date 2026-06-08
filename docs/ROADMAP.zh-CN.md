# 路线图

本文只描述当前 main 分支方向。历史版本计划与实现说明通过 git history 和 tags 查看。

## 当前状态

- Core pre-v4 RC readiness：最新 Core P0 证明已完成。
- 最新 Core P0 证明：`docs/audits/local_acceptance/pre_v4_p0_after_live_llm/`
- `ready_for_v4_rc=true`
- `P0 blockers=0`
- v4.0 尚未开始、未发布、未打 tag。
- UI full-operation 仍然 blocked。

## 下一门禁：P1 UI Core Parity

下一道产品门禁是 [P1 UI Core Parity](10_roadmap/P1_UI_CORE_PARITY.zh-CN.md)。它必须证明 UI 能真实操作主要 Core workflow，之后才能声明完整 Workbench。

## 后续门禁：P2 Productization

[P2 Productization](10_roadmap/P2_PRODUCTIZATION.zh-CN.md) 只能在 P1 有证据后开始。范围包括 packaging、release notes、publication hygiene、diagnostics polish 和 final product acceptance loops。

## 持续架构方向

HeiTang KB Forge 保持 Skill-first。UI 是 presentation layer，不是 Core product engine。OpenClaw、Claude Code、Codex compatibility 仍是 Agent-facing package surfaces。

## Parser Backend 方向

当前已完成 parser 能力仍然是已验证的 internal parser、bounded best-effort OCR 和 PDF token reduction。external backend candidate 与 planned adapter 状态记录在 [Parser Backend Strategy](03_core_capabilities/PARSER_BACKEND_STRATEGY.zh-CN.md)：OpenDataLoader 用于端到端 PDF -> Markdown/JSON/RAG-ready parsing，PaddleOCR 用于 OCR foundation，MinerU 用于文档结构理解与复杂版面解析，PaddleOCR + MinerU 作为 planned OCR + document understanding pipeline。

本路线图不新增 parser 代码、不新增依赖、不下载模型、不运行外部 parser。

## 未证明前不属于范围

- v4.0 release 或 tag
- 完整用户可操作 Workbench
- SaaS multi-tenancy
- team permissions
- cloud sync
- platform-hosted user data
- 完整 external vector database production readiness
- external parser backend adapter completion
- Core tests 依赖真实 LLM/API/network
