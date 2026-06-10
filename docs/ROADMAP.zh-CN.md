# 路线图

本文只描述当前 main 分支方向。历史版本计划与实现说明通过 git history 和 tags 查看。

## 当前状态

- Core pre-v4 RC readiness：最新 Core P0 证明已完成。
- P1 local Workbench gate：已通过 v4 RC readiness。
- 最新 Core P0 证明：`docs/audits/local_acceptance/pre_v4_p0_after_live_llm/`
- 最新 P1 证明：`docs/audits/p1_final_gate_rerun/`
- `ready_for_v4_rc=true`
- `P0 blockers=0`
- Pre-v4 External Project Registry 已完成。
- S/A Contract Inclusion 已完成。
- 当前 stable release：`v4.1.1`。
- 上一个 stable release tag：`v4.1.0`。
- 历史 stable release tag：`v4.0.0`。

## 当前 stable 门禁：v4.1.1 Test Framework Governance

当前 stable 产品门禁是 `v4.1.1` Test Framework Governance release：validation gate manifest、changed-file impact selector、dry-run / executable validation runner、pytest markers、obsolete-test pruning register、token-efficient logs、Core/UI validation、release-readiness、CI green、release-check workflow evidence，以及无 secret/build/raw artifact pollution。既有 `v4.0.0` 与 `v4.1.0` tag 保持不变。

## 后续门禁：P2 Productization

[P2 Productization](10_roadmap/P2_PRODUCTIZATION.zh-CN.md) 只能在 P1 有证据后开始。范围包括 packaging、release notes、publication hygiene、diagnostics polish 和 final product acceptance loops。

## 持续架构方向

HeiTang KB Forge 保持 Skill-first。UI 是 presentation layer，不是 Core product engine。OpenClaw、Claude Code、Codex compatibility 仍是 Agent-facing package surfaces。

## Parser Backend 方向

当前已完成 parser 能力包括 builtin fallback，以及 Docling、PaddleOCR、Unstructured 的 opt-in local runtime adapters。默认 parser truth 仍是 verified internal parser、bounded best-effort OCR 和 PDF token reduction。P2.1 release evidence 索引在 `docs/audits/p2_1_parser_ocr_backends/`。Unstructured 仅 `.md/.txt` 稳定；更广 PDF/DOCX/image surface 属于 future hardening。OpenDataLoader for PDF -> Markdown/JSON/RAG-ready packaging、MinerU，以及 PaddleOCR + MinerU as an OCR + document understanding pipeline 仍只是 external backend candidate / planned adapter。

本路线图不扩展新的 parser backend，只做现有 P2.1 Docling/PaddleOCR/Unstructured runtime integration 的 release closure。

## 未证明前不属于范围

- 未完成 rc.1 acceptance 与 hardening evidence 就发布 stable v4.0.0
- 没有 release-check evidence 就创建 stable v4.0.0 tag
- 没有 test governance manifest、impacted gate selection、validation 与 release hygiene 就发布 v4.1.1
- 在 v4.1.1 release hardening 中启动 P2.2
- SaaS multi-tenancy
- team permissions
- cloud sync
- platform-hosted user data
- 完整 external vector database production readiness
- 超出现有 P2.1 adapters 的新 external parser backend expansion
- Core tests 依赖真实 LLM/API/network
