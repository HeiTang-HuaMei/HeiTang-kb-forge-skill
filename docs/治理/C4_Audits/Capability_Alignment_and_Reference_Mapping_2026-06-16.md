# Capability Alignment and Reference Mapping

Date: 2026-06-16

Status: `capability_alignment_and_reference_mapping_pending_owner_review`

Gate: `registered_first_capability_alignment_gate`

Scope: inventory and mapping only. This document does not authorize Provider Runtime implementation, Campaign 5, Campaign 6, Campaign 7, Campaign 8, Campaign 9, Core changes, UI changes, dependency changes, yellow-marker removal, commit, push, tag, or release.

## 1. Existing Core Capability Inventory

| Area | Current Core commands / modules | Current test coverage found | Current evidence status |
|---|---|---|---|
| Provider / Secret / local safety boundary | `provider-readiness`, `provider-security-audit`, `provider-list`, `provider-config-validate`, `provider-registry-export`, `provider-live-smoke`, `provider-fallback-test`, `llm-cost-guard`, `audit-redaction-check`, `llm-live-smoke`; modules under `heitang_kb_forge/llm`, `heitang_kb_forge/providers`, `heitang_kb_forge/provider_security`, `heitang_kb_forge/live/provider_smoke.py` | `tests/test_provider_readiness.py`, `tests/test_provider_registry.py`, `tests/test_provider_health.py`, `tests/test_v26_provider_security.py`, `tests/test_live_provider_smoke.py`, `tests/test_llm_provider_profiles.py`, `tests/test_llm_provider_readiness.py`, `tests/test_optional_llm_config_redaction.py`, `tests/test_secret_redaction_completion.py`, `tests/test_llm_cost*`, `tests/test_optional_llm_fallback.py` | Existing contracts, registry, redaction, cost, fallback, and smoke surfaces exist. Formal product-wide Provider Runtime remains a Gate, not accepted here. |
| External Source Verification | `external-capability-registry`, `external-capability-inspect`, `external-capability-matrix`, `verify-claims`, `check-knowledge-accuracy`; modules under `external_sources`, `external_retrieval`, `retrieval`, `audit` | `tests/test_external_source_*`, `tests/test_external_link_import_entry.py`, `tests/test_external_source_knowledge_verification.py`, `tests/test_v38_claim_verification.py`, `tests/test_v38_knowledge_accuracy.py`, `tests/test_v38_source_cross_check.py`, `tests/test_anysearch_provider.py` | Framework, generic URL ingestion, OpenCLI verification, manual evidence, unified trace, knowledge verification foundations, AnySearch provider evidence exist. Full External Source Verification Gate remains pending. |
| OCR / Parser / Chunking | `parser-backend-*`, `check-*backend`, `smoke-*backend`, `parse-with-backend`, `parse-compare`, `parser-runtime-acceptance`, `parse-quality-gate`, `preflight-documents`, `batch-import-documents`, `run-document-understanding`, `build-knowledge-base`; modules under `parsers`, `parser_backends`, `document_parsing`, `ocr`, `chunker` | `tests/test_v28_parser_backends.py`, `tests/test_full_ocr_acceptance.py`, `tests/test_ocr_*`, `tests/test_document_batch_import.py`, `tests/test_docling_backend_strengthening.py`, `tests/test_paddleocr_backend_strengthening.py`, `tests/test_unstructured_fallback_strengthening.py`, `tests/test_chunker.py`, `tests/test_semantic_chunking_quality.py` | Builtin parser and optional backend surfaces exist. Optional backends are dependency-gated and not bundled by default. |
| Knowledge Quality Gate | `quality-gate`, `parse-quality-gate`, `trusted-kb-gate`, `evidence-gate`, `eval-retrieval`, `select-evidence`, `rerank-results`, `verify-claims`, `check-knowledge-accuracy`, `verify-agent-output`; modules under `evidence_gate`, `retrieval`, `quality`, `evalset` | `tests/test_quality_gate.py`, `tests/test_knowledge_quality.py`, `tests/test_evidence_gate.py`, `tests/test_retrieval_eval.py`, `tests/test_rag_metrics_context_recall_faithfulness.py`, `tests/test_v38_*` | Local deterministic quality, retrieval, evidence, rerank, claim, and accuracy checks exist. External comparison remains gated. |
| Document Export | `generate-documents`, `generate-md`, `generate-docx`, `generate-pdf`, `generate-pptx`; modules under `document_generation` | `tests/test_v30_document_generation.py`, `tests/test_v30_document_generation_cli.py`, `tests/test_v30_document_generation_pipeline.py`, `tests/test_document_output_governance.py`, `tests/test_all_formats_build.py` | Markdown, DOCX, PDF, and PPTX command surfaces exist. Campaign 4 UI yellow marks require render validation evidence before removal. |
| Skill Governance | `generate-skill`, `book-to-skill`, `plan-skill-suite`, `build-skill-suite`, `export-skill-pack`, `validate-skill-suite`, `skill-suite-governance-report`, `validate-skill-package`, `skill-governance-report`; modules under `skill`, `skill_suite`, `master_skill`, `marketing_skill_patterns`, `engineering_governance_rules` | `tests/test_skill_*`, `tests/test_book_to_skill_*`, `tests/test_skill_suite_*`, `tests/test_skill_governance_report.py`, `tests/test_mattpocock_skills_integration_decision.py` | Real Skill generation, suite, package, governance, validation, and template-supporting surfaces exist. Advanced composition UX may still be display-only. |
| Agent Creation Package | `generate-agent`, `generate-bound-agent`, Agent package generator modules, `agent_compat`, `agent_rag`, `agent_tools`; boundary commands also include local smoke/runtime-looking tests that must not be used to claim Campaign 6 | `tests/test_agent_package_generator.py`, `tests/test_agent_build.py`, `tests/test_agent_batch.py`, `tests/test_v31_knowledge_bound_factory*.py`, `tests/test_agent_compat_*`, `tests/test_agent_provider_mapping_readiness.py` | Agent Creation Package and compatibility/package artifacts exist. Agent CRUD, save, version, and full runtime are Campaign 6 or Post-9. |
| Campaign 5 Bridge / Workbench | `workbench-contracts`, `workbench-action-inspect`, `workbench-action-dry-run`, `workbench-smoke`, `workbench-action-execution-plan`, `workbench-run-ready-action(s)`, `workbench-action-result-status`, `workbench-full-local-user-path`; modules under `workbench` | `tests/test_p1_workbench_*`, `tests/test_v34_workbench_contracts*`, UI contract tests | Bridge/action surfaces exist, but Campaign 5 status must be reconciled before treating bridge acceptance as sufficient. |
| Campaign 6+ / Packaging | Governance docs and some pre-existing agent/runtime/config/storage/package tests exist | `tests/test_campaign_4_9_replacement_plan.py`, `tests/test_plan_sequence_lock.py`, `tests/test_agent_runtime_capability_truth.py`, `tests/test_desktop_*`, `tests/test_release_*` | These tests and docs are evidence/reference only for future gates unless the owning Campaign is explicitly opened. |

## 2. Existing UI Capability Inventory

Primary UI source reviewed: `kb-forge-skill-ui/web/workbench/flutter_app/lib/main.dart`.

| UI area | Current visible entry | Current UI state | Current binding implication |
|---|---|---|---|
| Dashboard provider boundary | Configure Provider Gate / Provider Runtime marker | `disabled_boundary` | UI states that Provider Runtime Gate has not passed; no yellow removal allowed. |
| Dashboard external verification | External fact verification marker | `disabled_boundary` | UI separates web-link import from external fact verification. |
| Import and Parsing | Source, Parser, OCR, Chunking, Run, Validate | Parser/file formats mostly `enabled_real`; OCR `disabled_boundary`; chunking often `display_only` | Existing parser surfaces can be reused; OCR needs dependency/runtime/package validation before UI status change. |
| Knowledge Base | Storage and Provider Boundary; vector provider and external facts | Local KB `enabled_real`; vector provider and external facts `disabled_boundary` | Local KB/index evidence exists; vector/external providers wait for owning Gate. |
| Retrieval and Verification | Query rewriting, retrieval planning, evidence selection, rerank, local evidence validation | Local flows visible; external comparison `disabled_boundary` | Local verification can bind existing Core; external comparison requires External Source Verification Gate. |
| Document Generation | Markdown/DOCX/PDF/PPTX ownership, queue, preview, validation/export boundary | Some outputs `enabled_real`; PDF/PPTX render boundary `disabled_boundary` where validation is pending | Reuse document commands first; do not re-implement exporters. |
| Skill Factory | Book/doc to Skill, KB to Skill, Skill templates, governance report | Main Skill paths `enabled_real`; composition/advanced entries `display_only` | Reuse existing Skill commands and governance reports; advanced UX remains later unless evidence exists. |
| Agent Factory | Agent Creation Package input mapping, config preview, package preview, export boundary | Mapping/preview `display_only`; draft export boundary may expose `enabled_real` only for package draft; save/version omitted | Reuse package generator; do not enter Agent CRUD/runtime. |
| Audit and Reports | Quality, retrieval, OCR, safety, governance reports | Archive/report manifest may be `enabled_real` or `display_only` | Audit page should aggregate evidence; no unified export ownership. |
| Settings | Provider, vector DB, API key, storage, cache, diagnostics | Provider/vector/cloud/cache mostly `disabled_boundary`; API key masked `display_only`; local workspace/storage `enabled_real` | Provider/storage yellow markers can change only after accepted evidence and Owner approval. |

## 3. Registered Project Inventory

Registered-first sources reviewed:

- `kb-forge-skill/docs/audits/s_a_contract_inclusion/external_capability_registry.json`
- `kb-forge-skill/docs/audits/s_a_contract_inclusion/planned_adapter_registry.json`
- `kb-forge-skill/docs/audits/s_a_contract_inclusion/provider_required_registry.json`
- `kb-forge-skill/docs/audits/s_a_contract_inclusion/internal_capability_anchor_registry.json`
- `kb-forge-skill/docs/audits/s_a_contract_inclusion/workbench_capability_matrix.json`
- `kb-forge-skill/docs/roadmap/external_projects/external_project_registry.json`
- `kb-forge-skill/docs/治理/Campaign_4_9_总计划.md`
- `kb-forge-skill/docs/治理/Campaign_4_9_验收矩阵.md`
- `kb-forge-skill/docs/治理/Campaign_6_外部运行时参考队列.md`

| Registered project / route | Registry source | Registered status | Reuse meaning for this Gate |
|---|---|---|---|
| `anysearchskill` | `external_capability_registry.json`, `provider_required_registry.json` | `real_workflow_evidence`, `provider_adapter`, `ui_configuration_pending` | Reuse as external retrieval/provider-adapter evidence and design input; still needs UI/Core Bridge and provider acceptance. |
| `paddleocr` | `external_capability_registry.json`, `planned_adapter_registry.json` | `planned_adapter`, `optional_runtime_adapter`, dependency not bundled | Reuse only as optional OCR adapter registration; do not bundle or mark enabled without local dependency proof. |
| `docling` | same as above | `planned_adapter`, `optional_runtime_adapter` | Reuse parser adapter boundary and evidence pattern. |
| `unstructured` | same as above | `planned_adapter`, `optional_runtime_adapter` | Reuse partition/elements/chunking design pattern only if existing parser path is insufficient. |
| `opendataloader`, `marker`, `surya`, `mineru` | `planned_adapter_registry.json` | `planned_adapter` | Optional parser/OCR reference queue; not implementation authority. |
| `llamaindex` | `external_capability_registry.json` | `benchmark_mapped`, `benchmark_only` | Design pattern reference for ingestion/transform/chunk pipeline only. |
| `ragas`, `deepeval` | `external_capability_registry.json` | `benchmark_mapped` / `docs_only`, `benchmark_only` | Design pattern reference for RAG/eval metrics only. |
| `rag_anything` | `external_capability_registry.json` | `reference_schema_evidence`, `cross_modal_rag_schema_reference` | Reuse schema/evidence-trace reference only; no runtime, vector DB, LightRAG, or multimodal runtime. |
| `mattpocock_skills` | `external_capability_registry.json`, matrix report | `real_workflow_evidence`, `engineering_governance_rule_pack` | Reuse governance discipline; do not install external Skill runtime or create Agent from it. |
| `skill_prompt_generator`, `ai_marketing_skills` | `external_capability_registry.json` | `real_workflow_evidence` | Reuse local prompt asset / pattern-library evidence for Skill governance and templates. |
| `sirchmunk` | `external_capability_registry.json` | `real_workflow_evidence`, bounded direct-file-search provider candidate | Reuse local bounded direct-file-search evidence; no network/LLM/vector DB claim. |
| `n8n` | `external_capability_registry.json`, `provider_boundary_report.md` | workflow export adapter, `runtime_not_bundled`, `external_runtime_required` | Reuse only offline workflow export evidence; execution belongs to user-owned runtime and is not part of this Gate. |
| Campaign 6 reference queue | `docs/治理/Campaign_6_外部运行时参考队列.md` | `reference_only` / `needs_verification` | Use for boundaries only; no Campaign 6 or Post-9 runtime implementation here. |

## 4. Yellow Gap to Existing Capability Mapping

| Capability item | Current UI entry | Current Core commands / modules | Current test coverage | registered_project_covered | registered_project_source | Registered reuse point | External reference needed | External reference candidates | reuse_decision | Recommended action | Development prerequisites | Acceptance method |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Provider Runtime / Secret / local safety boundary | Dashboard Provider boundary; Settings Provider/API key/vector DB | `provider-readiness`, `provider-security-audit`, `provider-config-validate`, `provider-live-smoke`, `provider-fallback-test`, `llm-cost-guard`, `audit-redaction-check`; `llm/provider_*`, `providers/*`, `provider_security/*` | Provider, redaction, fallback, health, live-smoke, optional LLM tests listed in inventory | partial | `provider_required_registry.json`; `external_capability_registry.json:anysearchskill`; `Provider_Runtime_Gate_Scope_Freeze_2026-06-16.md` | AnySearch provider-adapter evidence, provider-required registry, existing provider/redaction/fallback/cost commands | yes, design only | LiteLLM-style router/fallback/retry/cost/token/budget pattern only | adapt | Adapt existing commands into accepted Provider Runtime Gate evidence; add missing schema/status/cancel/UI binding only after Owner implementation approval | Owner accepts this mapping; Campaign 5 disposition if required; explicit network/Secret consent; no dependency changes without approval | Provider test matrix, secret leak scan, opt-in live smoke, offline/invalid/unavailable/timeout/retry/fallback/cancel evidence, Owner acceptance |
| External Source Verification | Dashboard, Knowledge Base, Retrieval and Verification external fact check | `verify-claims`, `check-knowledge-accuracy`, `external-capability-*`, `external_sources/*`, `external_retrieval/anysearch.py`, retrieval/evidence commands | `test_external_source_*`, `test_v38_*`, `test_anysearch_provider.py` | partial | `external_capability_registry.json:anysearchskill,sirchmunk`; Campaign 3 Supplement 3.0 evidence in tests/docs | AnySearch, Sirchmunk, OpenCLI, manual evidence, unified trace, verification foundations | maybe | RAG verification/fact-checking design patterns only if local evidence model lacks fields | adapt | Reuse local verification and source trace; define Gate policy before live/external comparison; bridge UI only after acceptance | Owner opens External Source Verification Gate; network consent model; source trust policy | Freshness/contradiction/provenance tests, source trust policy, opt-in network evidence, unavailable behavior |
| OCR / Parser / Chunking | Import and Parsing parser/OCR/chunking | Parser backend commands, `batch-import-documents`, `run-document-understanding`, `build-knowledge-base`, parser modules | Parser backend, OCR, batch import, chunking tests listed above | yes/partial | `planned_adapter_registry.json:paddleocr,docling,unstructured,opendataloader,marker,surya,mineru`; `external_capability_registry.json` | Optional adapter registration and parser runtime acceptance patterns already exist | no for registry; maybe design only for missing ingestion orchestration | Unstructured partition/elements/chunking and LlamaIndex ingestion pipeline patterns only | adapt | Do not rebuild parser; reuse existing parser backend and OCR evidence, fill dependency/package validation and UI status binding when approved | Owner approves parser/OCR delta; optional deps installed explicitly; Windows packaging decision | Parser backend matrix, fixture OCR, local file, recovery, Windows dependency packaging tests |
| Knowledge Quality Gate | Knowledge Base quality, Retrieval and Verification metrics, Audit reports | `quality-gate`, `parse-quality-gate`, `trusted-kb-gate`, `evidence-gate`, `eval-retrieval`, `rerank-results`, `select-evidence`, `verify-claims`, `check-knowledge-accuracy` | Quality/evidence/retrieval/RAG metrics tests | partial | `external_capability_registry.json:ragas,deepeval,rag_anything`; `internal_capability_anchor_registry.json` | RAGAS/DeepEval are benchmark-only; RAG-Anything contributes schema/evidence reference only | yes, design only if metric labels need alignment | Ragas-style faithfulness/context precision/answer relevancy/factual correctness; DeepEval metric naming | adapt | Reuse existing local quality/eval; add metric schema/report mapping rather than new evaluator runtime | Owner approves Quality Gate delta; define metric names and thresholds | Local quality gate tests, retrieval eval, claim/accuracy reports, no external runtime dependency |
| Document Export | Document Generation output formats and PDF/PPTX boundary | `generate-documents`, `generate-md`, `generate-docx`, `generate-pdf`, `generate-pptx`; `document_generation/*` | v30 document generation tests, all-format tests, output governance tests | no external project needed | Existing Core commands; baseline references `generate-documents` as existing surface | Existing document generator is primary source; no external project required | no | None unless render engine validation fails later | reuse | Reuse current exporters; only add render validation/evidence and UI status binding after acceptance | Owner decides whether Campaign 4 delta or Campaign 8 review owns remaining render proof | Export round-trip, visual render checks, corrupt output tests, Windows path/encoding tests |
| Skill Governance | Skill Factory and governance report | Skill commands and `skill_suite`, `skill`, `master_skill`, governance modules | Skill/governance/template/import tests | yes | `external_capability_registry.json:mattpocock_skills,skill_prompt_generator,ai_marketing_skills`; `s_a_contract_inclusion_matrix.md` | Governance rule-pack, prompt asset library, marketing skill pattern library | no | External Skill projects are not implementation sources | reuse/adapt | Reuse existing Skill commands and governance reports; adapt UI/Bridge only for advanced entries if evidence supports it | Owner approves Skill delta or Campaign 6 dependency need | Skill import/export, suite validation, composition contract, governance report tests |
| Agent Creation Package | Agent Factory mapping/config/package/export boundary | `generate-agent`, `generate-bound-agent`, `agent_package/*`, `knowledge_bound_factory/*`, `agent_compat/*`, `agent_rag/*` | Agent package/generator/bound-agent/compat/provider mapping tests | partial | Baseline Agent Creation Package; `external_capability_registry.json:rag_anything,mattpocock_skills` as reference-only | Existing package generator and schema/evidence references | no for package; external refs only for later Agent design | None for Campaign 4 package; Campaign 6 may later use reference queue | reuse | Reuse package generator and package preview/export evidence. Do not implement Agent CRUD/save/version/runtime. | Campaign 6 explicit start for CRUD/version; Provider Gate accepted before model binding | Package export/import round-trip, manifest/schema checks, no runtime overclaim |
| Campaign 5 | Bridge/UI-Core action handoff | `workbench-*` commands and action planner/result status modules | `tests/test_p1_workbench_*`, `test_v34_workbench_contracts*` | not applicable | `Product_Capability_and_User_Journey_Baseline.md`; `Post_Campaign_4_Desktop_Productization_Master_Plan_2026-06-16.md` | Existing workbench contracts and action execution plan surfaces | no | None | adapt | Reconcile historical Campaign 5 evidence; do not redo by default | Owner opens Campaign 5 status reconciliation | One of sufficient/delta/reopen dispositions, bridge flow tests, no arbitrary shell execution |
| Campaign 6 | Agent create/edit/save/version/binding | Existing package/template artifacts only; some local agent runtime-looking modules/tests exist but are not this product flow | Agent package and runtime truth tests exist | partial/reference only | `docs/治理/Campaign_6_外部运行时参考队列.md`; baseline Campaign 6 rows | Existing package and templates inform Agent Foundation; runtime references are boundaries | no until Campaign 6 Entry | Campaign 6 reference queue only | defer | Postpone all Agent Foundation implementation until required prior gates pass | Campaign 4 accepted, Campaign 5 disposition accepted, Provider Gate accepted, Owner says start Campaign 6 | CRUD/version/binding/provider/workspace/package tests in Campaign 6 |
| Campaign 7 | Configuration engineering | Config/profile/provider/prompt/storage modules and tests exist | Config, prompt profile, storage target tests | partial | Baseline and Campaign 4-9 governance docs | Existing config surfaces can inform profile engineering | no | None | defer | Postpone; do not use Campaign 7 to backfill Provider Runtime or Campaign 6 fields | Owner accepts Campaign 6 and opens Campaign 7 | Precedence, merge, migration, secret injection, diagnostics tests |
| Campaign 8 | Full testing / review | Many full/final/release/security/performance tests exist | Full/final audit test families exist | not applicable | Campaign 4-9 acceptance matrix | Existing tests inform future full review | no | None | defer | Postpone; only test/audit/fix defects when opened | Owner accepts Campaign 7 and opens Campaign 8 | Full review, clean clone, Windows parity, no large feature backfill |
| Campaign 9 | EXE Packaging and desktop shell controls | Desktop/packaging docs/tests exist; Flutter Web controls are visual simulation | Desktop docs/lifecycle/icon tests; packaging/release tests | partial/reference only | Campaign 4 yellow desktop shell item; Campaign 4-9 plan | Existing desktop/packaging evidence informs EXE package scope | no | None | defer | Postpone real window binding and packaging until Campaign 9 | Owner accepts Campaign 8 and opens Campaign 9 | EXE/portable/installer smoke, asset/dependency/checksum inventory, clean-machine smoke |

## 5. Yellow Gap to Missing Layer Mapping

| Yellow gap | Existing layer present | Missing layer | Do not rebuild |
|---|---|---|---|
| Provider Runtime / Secret / local safety | Provider registry, config validation, readiness, security audit, live smoke, fallback, cost, redaction tests | Formal runtime contract, accepted status schema, cancellation, complete failure matrix, UI/Bridge accepted evidence | Do not rewrite provider registry, redaction, fallback, cost guard, or live-smoke harness. |
| External Source Verification | URL/import framework, OpenCLI verification, manual evidence, unified trace, AnySearch/Sirchmunk evidence | Accepted external verification gate, trust policy, opt-in network UI/Bridge, contradiction/freshness acceptance | Do not merge web-link import and external fact verification. |
| OCR / Parser / Chunking | Parser backend commands, optional adapters, OCR controls, batch import, chunking | Dependency/package proof for EXE, verified local OCR path, UI status binding for OCR readiness | Do not replace parser backend architecture. |
| Knowledge Quality Gate | Local evidence/quality/retrieval/claim metrics | Metric normalization, threshold ownership, report-to-UI accepted binding | Do not add Ragas/DeepEval as dependencies in this Gate. |
| Document Export | Core document generators | Render validation and artifact QA evidence for yellow PDF/PPTX boundaries | Do not write new document exporter before proving existing one insufficient. |
| Skill Governance | Skill generation/suite/governance commands | Advanced composition UX/Bridge only if required | Do not replace Skill Factory with external Skill project. |
| Agent Creation Package | Package generator, bound-agent generator, compatibility outputs | Full Agent CRUD/save/version/binding in Campaign 6 | Do not claim package generation is Agent Foundation or runtime. |
| Campaign 5 | Workbench contracts/action planner | Status reconciliation and any Owner-approved delta | Do not redo Campaign 5 by default. |
| Campaign 6 | Package/template artifacts | Agent Foundation product flow | Do not open Agent Runtime/Memory/Post-9. |
| Campaign 7 | Config/profile pieces | Config engineering after Campaign 6 | Do not move Provider Runtime into Campaign 7. |
| Campaign 8 | Test corpus | Full review after Campaign 7 | Do not backfill missing large features. |
| Campaign 9 | Desktop/packaging references | Real EXE packaging/window behavior | Do not release/tag before final approval. |

## 6. Mature Project Reference Mapping

External projects are design pattern references only. This Gate does not add dependencies, vendor code, prompts, SKILL files, datasets, or runtime adapters.

| Capability | Registered-first source | External reference status | Allowed use |
|---|---|---|---|
| Provider Runtime / Router | `anysearchskill`, provider registries, existing provider commands | LiteLLM only if registered evidence is insufficient for router/fallback/retry/cost/budget wording | Design pattern vocabulary only. |
| Parser / OCR / Chunking | `paddleocr`, `docling`, `unstructured`, `opendataloader`, `marker`, `surya`, `mineru` planned adapters | Unstructured / LlamaIndex style only if current pipeline lacks schema language | Design pattern for partition/elements/chunking and ingestion transforms only. |
| RAG Quality / Evaluation | Existing v38/RAG metrics; `ragas`, `deepeval`, `rag_anything` registered references | Ragas/DeepEval metric families only | Metric naming inspiration only. |
| Document Export | Existing `generate-documents` family | No external reference needed now | Reuse Core. |
| Skill Governance | `mattpocock_skills`, `skill_prompt_generator`, `ai_marketing_skills` | No new external reference needed | Governance and pattern-library evidence only. |
| Agent Package | Existing package generator; Campaign 6 reference queue | No new external reference needed for package | Keep runtime references deferred. |

## 7. Reuse / Adapt / Build / Defer Decision

| Capability | Decision | Reason |
|---|---|---|
| Provider Runtime / Secret / local safety | adapt | Substantial provider/governance surfaces exist; missing accepted runtime contract and failure/status evidence. |
| External Source Verification | adapt | Existing source verification foundations exist; missing accepted Gate and UI/Bridge policy. |
| OCR / Parser / Chunking | adapt | Parser/OCR backends and tests exist; packaging/local dependency proof and UI status binding remain. |
| Knowledge Quality Gate | adapt | Local metrics and quality gates exist; metric/report normalization and accepted thresholds remain. |
| Document Export | reuse | Existing commands cover required formats; validation evidence should come before new implementation. |
| Skill Governance | reuse/adapt | Existing Skill governance is broad; only advanced display-only UX may need adaptation. |
| Agent Creation Package | reuse | Existing package generator is the correct Campaign 4 boundary. |
| Campaign 5 | adapt | Reconcile before any delta; do not redo by default. |
| Campaign 6 | defer | Requires prior gates and explicit Owner start. |
| Campaign 7 | defer | Configuration engineering only after Campaign 6. |
| Campaign 8 | defer | Review/testing only after Campaign 7. |
| Campaign 9 | defer | EXE packaging only after Campaign 8. |

## 8. Revised Gate Implementation Order

1. Owner review of this registered-first alignment document.
2. Campaign 5 Status Reconciliation: decide whether historical bridge evidence is sufficient, delta is required, or reopen needs Owner decision.
3. Provider Runtime Gate implementation only after Owner authorization, reusing existing provider/security/fallback/cost/live-smoke surfaces first.
4. External Source Verification Gate, if Owner approves, reusing existing external source and AnySearch/Sirchmunk evidence before any new Core.
5. Parser/OCR/Chunking delta, only for dependency packaging, local execution proof, status schema, and UI binding gaps.
6. Knowledge Quality Gate normalization, reusing existing local quality/retrieval/evidence reports before external metric references.
7. Document Export validation, reusing current document commands before considering renderer changes.
8. Skill Governance adaptation, only where existing reports do not cover UI/Bridge needs.
9. Agent Creation Package export hardening, still not Agent CRUD/runtime.
10. Campaign 6+ only after the required prior gates and explicit Owner authorization.

## 9. Anti-Rebuild Rules

- Do not skip existing Core commands and rebuild a parallel runtime.
- Do not skip registered projects and go directly to famous external projects.
- Do not treat UI yellow markers as proof that Core capability is absent.
- Do not treat `provider-live-smoke`, AnySearch smoke, or mock/offline harnesses as formal product-wide runtime acceptance.
- Do not add external dependencies, vendor code, prompt bodies, SKILL files, or runtime adapters in this Gate.
- Do not move Provider Runtime into Campaign 7.
- Do not implement Campaign 6 Agent CRUD, Agent Runtime, Memory, Collaboration, A2A, Sandbox, or EXE Packaging in this Gate.
- Do not remove yellow UI markers before accepted implementation evidence and Owner approval.

## 10. Provider Runtime Gate Go / No-Go

Current implementation permission: No-Go.

Reason: this Gate produced only registered-first mapping. Provider Runtime implementation still requires Owner review and explicit authorization after this document is accepted.

Recommended next Go after Owner acceptance: conditional Go for Provider Runtime Gate planning/implementation using existing capabilities first.

First reuse targets if Owner authorizes Provider Runtime implementation:

- `provider-config-validate` for profile/schema validation.
- `provider-readiness` and workspace provider registry commands for readiness/state evidence.
- `provider-security-audit` and `audit-redaction-check` for Secret and redaction proof.
- `provider-fallback-test` and existing optional LLM fallback tests for fallback behavior.
- `llm-cost-guard` and cost/token reports for cost evidence.
- `provider-live-smoke` / `llm-live-smoke` only as opt-in live-smoke evidence, not as formal runtime by itself.
- `anysearchskill` provider-adapter registry evidence only as a registered reference for provider/external retrieval behavior.

Current blockers before implementation:

- Owner has not accepted this alignment document.
- Campaign 5 status disposition is not yet reconciled in this Gate.
- Provider Runtime accepted status schema and UI/Bridge binding contract are not frozen here.
- Cancellation evidence and full failure matrix need implementation-scope authorization.
- Network/Secret opt-in execution requires separate Owner authorization and safe credential path.

Stop status: `capability_alignment_and_reference_mapping_pending_owner_review`

Next safe action: Owner reviews this document and decides whether to authorize the next Gate. No runtime implementation should begin from this document alone.
