# Source Acquisition Layer OpenCLI Alignment

Status: `opencli_source_connector_alignment_pending_owner_review`

Gate: `lazy_builder_and_semantic_layer_planning_gate`

Date: 2026-06-22

This document defines how existing OpenCLI-related capability should be named and aligned in the future Source Acquisition Layer. It is a planning document only.

No code, UI, runtime semantics, dependency, tag, release, or GitHub Release change is included.

## 1. Decision

Do not create an independent resource search/downloader module.

Use the existing canonical name:

```text
OpenCLI Source Connector
```

The OpenCLI Source Connector is one Source Searcher provider. It is not the whole source acquisition layer.

## 2. Layer Model

Source Acquisition Layer:

```text
用户输入
-> 搜索资料 / 粘贴链接 / 手动证据
-> Source Searcher / Source Fetcher / Manual Evidence Importer
-> Source Trace
-> Evidence Map
-> 文档库
-> 知识库 / 检索 / 文档 / Skill / Agent / 成果中心
```

Provider-level planning:

| Layer role | Planned component | Current evidence | Boundary |
| --- | --- | --- | --- |
| Source Searcher | OpenCLI Source Connector | `../kb-forge-skill/heitang_kb_forge/external_sources/opencli_adapter.py` | Keyword candidate discovery only. |
| Source Fetcher | Generic URL Fetcher | `../kb-forge-skill/heitang_kb_forge/external_sources/generic_url.py` | Public HTTP/HTML fetch and body extraction. |
| Manual Evidence Importer | Manual Evidence Importer | `../kb-forge-skill/heitang_kb_forge/external_sources/manual_evidence.py` | User-supplied evidence with secret guard. |
| Trace merger | Unified Source Trace / Evidence Map | `../kb-forge-skill/heitang_kb_forge/external_sources/unified_trace.py` | Normalizes evidence outputs from allowed paths. |

## 3. OpenCLI Source Connector Responsibilities

The OpenCLI Source Connector may own:

- Keyword query normalization.
- Public candidate search through the existing OpenCLI adapter.
- Candidate metadata normalization.
- Candidate confidence summary.
- Source trace output.
- Evidence map output.
- Clear unavailable/degraded reports when OpenCLI, network, or query inputs are unavailable.

It must not own:

- Public webpage body extraction.
- Authenticated browsing.
- Cookie/session import.
- Paywall or CAPTCHA bypass.
- Arbitrary crawling.
- Manual evidence processing.
- Workbench UI account/login flows.
- A new provider/runtime/gateway hierarchy.

## 4. Required Output Contract

Every successful or degraded OpenCLI Source Connector run must produce or preserve traceable artifacts:

```text
external_search_candidates.jsonl
external_source_trace.json
external_source_confidence.json
external_evidence_map.json
opencli_external_verification_validation_report.json
```

Every downstream use must retain:

```text
source_id
evidence_id
source_url or source reference
retrieved_at
provider/source path
confidence or unavailable reason
workspace boundary
```

No OpenCLI result may enter document, Skill, Agent, or report output without Source Trace / Evidence Map linkage.

## 5. UI Naming Alignment

Ordinary UI must not expose `opencli`.

Allowed ordinary UI labels:

```text
搜索资料
粘贴链接
需要设置
暂不可用
本地模式
授权后可用
```

Implementation-facing or audit-only label:

```text
OpenCLI Source Connector
```

Mapping:

| User-facing action | Internal alignment | Current status |
| --- | --- | --- |
| 搜索资料 | Source Searcher -> OpenCLI Source Connector | Planned alignment; not direct Flutter UI binding today. |
| 粘贴链接 | Source Fetcher or current local link source record import | Current Workbench saves local link records; public body fetch belongs to Generic URL Fetcher when authorized/configured. |
| 手动证据 | Manual Evidence Importer | Core capability exists; not an OpenCLI feature. |
| 外部核对 | Source Trace / Evidence Map comparison path | Gated in ordinary Workbench UI until configuration/authorization is complete. |

## 6. Source Trace and Evidence Map Rule

All source acquisition paths must converge here:

```text
Source Searcher result
Source Fetcher content
Manual Evidence block
-> Source Trace
-> Evidence Map
```

Minimum alignment requirements:

- Search results without fetched body can still be evidence candidates.
- Fetched URL body must carry source trace back to the original URL.
- Manual evidence must be marked as manual and must not masquerade as public fetch/OpenCLI output.
- Unsupported or unconfigured acquisition paths must produce a plain gated state, not a success state.

## 7. Knowledge Pipeline Handoff

The target handoff is:

```text
Source Trace / Evidence Map
-> 文档库 source record
-> 解析/切分
-> 知识库
-> 检索验证
-> 文档 / Skill / Agent / 成果中心
```

Current reality:

- Workbench `importWebLink` can create a local source record and run the document import path.
- Core generic URL ingestion can produce chunks from public HTML.
- Core OpenCLI can produce candidate evidence and trace artifacts.
- A direct OpenCLI candidate-to-Workbench-KB pipeline binding was not confirmed in this audit.

Therefore, future acceptance must verify the handoff explicitly before claiming full Workbench runtime integration.

## 8. Configuration and Gating

Source acquisition must follow existing product gating:

| Condition | User-facing state | Internal handling |
| --- | --- | --- |
| No network authorization | `需要设置` or `授权后可用` | Do not call network search/fetch. |
| OpenCLI binary unavailable | `暂不可用` | Record unavailable reason; do not show success. |
| Unsupported URL or source type | `暂不可用` | Preserve user input and repair suggestion if safe. |
| Manual evidence contains secrets | `暂不可用` or blocked explanation | Do not persist secret-like content. |
| Fetch/search succeeds | Normal result | Preserve Source Trace / Evidence Map. |

No ordinary UI state may expose raw technical errors such as provider/gateway/model route names.

## 9. Relationship to Existing Planning Docs

This alignment extends the existing planning direction without replacing it:

- `docs/architecture/KNOWLEDGE_SEMANTIC_LAYER.md`
- `docs/product/KNOWLEDGE_INBOX_VNEXT_PLAN.md`
- `docs/product/USER_PATH_FIRST_UI_GOVERNANCE.md`
- `docs/dev/HEITANG_LAZY_BUILDER_GATE.md`

The Source Acquisition Layer should remain a thin intake layer before the document library, not a separate product center.

## 10. Non-Goals

This plan does not:

- Implement code.
- Change UI.
- Add dependencies.
- Add a new provider/runtime/gateway architecture.
- Add SQL DataAgent.
- Make OpenCLI a URL body extractor.
- Make external tools such as Plaud, Obsidian, Weflow, Notion, or Feishu mandatory.
- Mark the feature as runtime-ready in the Workbench UI.
- Replace `full_product_regression_before_packaging_gate`.

## 11. Owner Review Questions

Before implementation, Owner should confirm:

1. Should `搜索资料` remain hidden until OpenCLI Source Connector has a direct Workbench runtime binding?
2. Should `粘贴链接` continue saving local source records when network authorization is absent?
3. What is the minimum evidence needed to accept OpenCLI candidate results into a knowledge-base build?
4. Should OpenCLI results require a follow-up URL fetch before being used as evidence, or can candidate metadata alone support low-confidence evidence?

## 12. Final State

This gate only aligns architecture and naming.

Final status:

```text
opencli_source_connector_alignment_pending_owner_review
```
