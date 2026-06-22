# OpenCLI Source Connector Audit

Status: `opencli_source_connector_alignment_pending_owner_review`

Gate: `lazy_builder_and_semantic_layer_planning_gate`

Date: 2026-06-22

This audit records the current OpenCLI-related external source capability in HeiTang Knowledge Workbench. It is planning and evidence consolidation only.

No code, UI, runtime semantics, dependency, tag, release, or GitHub Release change is included.

## 1. Scope

Searched terms:

```text
opencli
external source
link ingestion
manual_evidence
source_trace
evidence_map
connector
fetcher
searcher
```

Inspected areas:

```text
kb-forge-skill-ui
kb-forge-skill
Flutter Workbench runtime and pages
architecture/product docs
contract registry assets
external source tests
```

Current UI repository baseline:

```text
repo: kb-forge-skill-ui
branch: feature/workbench-ui-prototype
head: 36f52db test: verify workbench industrial readiness candidate
known unrelated dirty file: docs/EXTERNAL_PROJECT_ADOPTION.zh-CN.md
```

## 2. Four-State Classification

| Area | State | Evidence | Notes |
| --- | --- | --- | --- |
| OpenCLI external source verification in core | 已真实调用 | `../kb-forge-skill/heitang_kb_forge/external_sources/opencli_adapter.py`, `../kb-forge-skill/tests/test_external_source_opencli_verification.py` | Real command-backed keyword candidate discovery, validation, confidence, source trace, and evidence map generation. |
| Generic public URL ingestion in core | 已真实调用 | `../kb-forge-skill/heitang_kb_forge/external_sources/generic_url.py`, `../kb-forge-skill/tests/test_external_source_generic_url.py` | Real public HTTP/HTML fetch and text extraction. This is not OpenCLI. |
| Manual evidence upload in core | 已真实调用 | `../kb-forge-skill/heitang_kb_forge/external_sources/manual_evidence.py`, `../kb-forge-skill/tests/test_external_source_manual_evidence.py` | Real user-supplied evidence import with secret guard, source trace, and evidence map. This is not OpenCLI. |
| Unified external source trace in core | 已真实调用 | `../kb-forge-skill/heitang_kb_forge/external_sources/unified_trace.py`, `../kb-forge-skill/tests/test_external_source_unified_trace.py` | Merges generic URL, platform preflight, OpenCLI verification, and manual evidence into unified source/evidence outputs. |
| Flutter Workbench `importWebLink` | 已真实调用 | `web/workbench/flutter_app/lib/rc6_runtime/rc6_runtime_controller_io.dart`, `web/workbench/flutter_app/lib/features/import_parsing/import_product_workflow.dart` | Saves a real local web-link source record and imports it into the workspace document flow. It does not fetch webpage body before network authorization. |
| OpenCLI direct call from Flutter runtime | 已注册但未接入 | No direct `verify_external_source_with_opencli` or OpenCLI command binding found in Workbench `Rc6RuntimeController`. | Workbench does not currently call OpenCLI from ordinary UI. |
| Campaign contract assets for external source verification | 已注册但未接入 | `web/workbench/flutter_app/assets/contracts/campaign4_remaining_capability_status_2026_06_16.json`, related tests | Registry states external source verification as `enabled_real`; current Workbench UI still gates external checking unless authorization/configuration exists. This needs naming reconciliation, not new code. |
| `opencli_bridge` multi-source ingestion mode | 已注册但未接入 | `../kb-forge-skill/heitang_kb_forge/multi_source_ingestion/ingestion.py`, `../kb-forge-skill/tests/test_opencli_bridge_import.py` | Local manifest/file bridge boundary only. It is not live OpenCLI keyword search or webpage fetch. |
| Knowledge semantic layer and inbox docs | 文档规划 | `docs/architecture/KNOWLEDGE_SEMANTIC_LAYER.md`, `docs/product/KNOWLEDGE_INBOX_VNEXT_PLAN.md` | Existing planning docs define source trace, evidence map, manual evidence, web links, and user-path governance. |
| UI external checking surface | UI 展示型/假功能 | Retrieval and knowledge-base pages show external checking as unavailable/gated until authorization/settings. | This is not fake success. It is gated/status-only and must remain user-facing as `需要设置` / `暂不可用` / `本地模式`. |

## 3. OpenCLI Current Capability Inventory

Canonical name for future planning:

```text
OpenCLI Source Connector
```

| Capability | Current status | Evidence | Boundary |
| --- | --- | --- | --- |
| Keyword search | Supported in core | `verify_external_source_with_opencli(...)` builds `opencli npm search <query> --limit <n> -f json`. | Currently limited to `npm` provider. Requires OpenCLI binary and allowed network. Not directly wired to Flutter UI. |
| URL fetch | Not OpenCLI | Generic URL ingestion supports public HTTP/HTML fetch. | Do not describe URL fetch as an OpenCLI feature. |
| Webpage body extraction | Not OpenCLI | `generic_url.py` extracts readable HTML/text into chunks. | Separate Source Fetcher capability. |
| Save source information | Supported in core | OpenCLI path writes `external_search_candidates.jsonl`, `external_source_trace.json`, `external_source_confidence.json`, and `external_evidence_map.json`. | Source information is candidate/evidence metadata, not fetched webpage body. |
| Manual evidence import | Not OpenCLI | `manual_evidence.py` writes `manual_evidence_manifest.json`, `manual_source_trace.json`, and `manual_evidence_map.json`. | Separate manual evidence path with secret/cookie/token guard. |
| Enter knowledge-base pipeline | Partially available through adjacent paths | Flutter `importWebLink` creates local `.url.md` source records that can enter document library/KB flow; generic URL produces chunks and evidence in core. | No confirmed direct OpenCLI candidates-to-Workbench-KB pipeline binding. Treat as planned alignment, not completed UI/runtime binding. |

## 4. OpenCLI Runtime Boundary

The OpenCLI core adapter is intentionally narrow:

```text
keyword query
-> public registry search candidates
-> confidence summary
-> source trace
-> evidence map
-> validation/report artifacts
```

Confirmed boundaries:

- It is read-only public source search.
- It is user-triggered.
- It does not import login cookies, browser sessions, private tokens, or credentials.
- It does not bypass paywalls, CAPTCHA, or platform restrictions.
- It does not execute arbitrary shell commands.
- It does not perform webpage body extraction.
- It does not implement manual evidence processing.
- It does not mark the Workbench UI workflow as accepted.

## 5. Workbench UI State

Ordinary Workbench UI currently exposes plain user actions:

```text
添加链接
外部来源核对
```

Observed behavior:

- `添加链接` calls `importWebLink`.
- `importWebLink` validates `http(s)` URLs.
- It writes a local source record named as a webpage link source.
- It explicitly states that body fetching requires network/provider authorization.
- Retrieval and knowledge-base pages show external checking as not enabled until authorization/settings are complete.
- No ordinary UI evidence was found that exposes `opencli` as a user-facing term.

Required naming discipline:

```text
普通 UI: 搜索资料 / 粘贴链接
审计/高级诊断/架构文档: OpenCLI Source Connector
```

## 6. Registry and Contract Reconciliation

Some contract assets record external source verification as `enabled_real`.

This should be interpreted as historical capability/contract status, not proof that the current Flutter Workbench ordinary UI directly invokes OpenCLI.

Reconciliation rule:

- Do not remove or downgrade existing runtime methods.
- Do not create a new search/download module.
- Do not claim OpenCLI is the URL fetcher.
- Do not claim current Workbench UI has OpenCLI search fully connected.
- Align future naming under `OpenCLI Source Connector`.

## 7. Risks

| Risk | Impact | Required handling |
| --- | --- | --- |
| Mixing OpenCLI keyword search with URL fetch | Overclaims OpenCLI capability. | Keep Source Searcher and Source Fetcher separate. |
| Showing OpenCLI as an ordinary UI term | Reintroduces technical UI leakage. | UI uses `搜索资料` and `粘贴链接`. |
| Treating registry `enabled_real` as direct UI binding | Can create false acceptance. | Report direct Flutter binding separately from core capability. |
| Adding a new resource searcher/downloader | Duplicates existing work. | Reuse OpenCLI Source Connector plus Generic URL Fetcher. |
| Letting candidates bypass trace/evidence outputs | Breaks auditability. | All results must enter Source Trace / Evidence Map. |

## 8. Audit Conclusion

OpenCLI exists today as a real core external source verification/search capability, but it is not a general resource downloader and is not directly exposed as an ordinary Flutter UI action.

The correct convergence is:

```text
OpenCLI Source Connector = Source Searcher provider for keyword candidate discovery
Generic URL Fetcher = Source Fetcher for public URL body extraction
Manual Evidence Importer = user-supplied evidence path
All paths -> Source Trace / Evidence Map -> document library / knowledge pipeline where configured
```

Final status:

```text
opencli_source_connector_alignment_pending_owner_review
```
