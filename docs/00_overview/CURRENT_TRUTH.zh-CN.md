# 当前真值

当前 Core package 版本：`4.1.0`
当前 stable release：`v4.1.0`

这是面向 GitHub 读者的当前状态入口。它只描述当前 main 分支，不堆放历史版本规划。

## 门禁状态

- P2.1 Parser/OCR Pluggable Backend Runtime 已完成 v4.1.0 release hardening。
- Docling、PaddleOCR、Unstructured 是真实 opt-in 本地 runtime adapters。
- Builtin parser 保持默认 fallback。
- 最新 P2.1 evidence 目录：`docs/audits/p2_1_parser_ocr_backends/`
- 最新 live runtime proof：`docs/audits/parser_runtime_acceptance/parser_runtime_acceptance_report.json`
- Unstructured stable surface 是 `.md/.txt`；PDF/DOCX/image extras 属于 future hardening。
- External registry hygiene 保持 `needs_verification=0`。
- `v4.0.0` 保持为未改动的历史 stable tag。
- P2.2 Skill Governance 没有在本 release hardening 中启动。

`v4.1.0` 是 P2.1 release hardening 之后的当前 Parser/OCR industrial release candidate。

## 产品定位

HeiTang KB Forge 是 local-first、offline-first 的 Core Skill，用于把本地资料转换为可审计、可检索、Agent-ready 的知识包。Core 是 headless、Skill-first。UI 是 presentation layer，必须通过独立 full-operation gate 后才能声明完整 Workbench。

## 当前证据

- 最新 Core P0 证明：`docs/audits/local_acceptance/pre_v4_p0_after_live_llm/`
- 最新 P1 final gate re-run 证明：`docs/audits/p1_final_gate_rerun/`
- 最新 P2.1 parser/OCR 证明：`docs/audits/p2_1_parser_ocr_backends/`
- 人工可读最终真值：`docs/FINAL_PRODUCT_ARCHITECTURE_TRUTH.zh-CN.md`
- 能力摘要：`docs/00_overview/CAPABILITY_MATRIX.zh-CN.md`
- 文档治理：`docs/DOCUMENTATION_GOVERNANCE.zh-CN.md`

## 不能声明

- 未完成 rc.1 acceptance 与 hardening evidence 就发布 stable v4.0.0
- 完整用户可操作 Workbench
- 仅由 P1 gate 发布 stable v4.0.0
- 仅由 P1 gate 创建 stable tag 或 release
- 外部 vector database production readiness
- 默认 platform-hosted user data
- Core tests 需要真实 LLM/API/network 调用
- 保存真实用户 API key
- SaaS 多租户、团队权限或 cloud sync
- 默认打包 Docling/PaddleOCR/Unstructured heavy dependencies
- static Workbench 暗示可直接执行本地 heavy runtime
- 在 v4.1.0 中声明 Unstructured PDF/DOCX/image support 已稳定
- 在 v4.1.0 中启动 P2.2
