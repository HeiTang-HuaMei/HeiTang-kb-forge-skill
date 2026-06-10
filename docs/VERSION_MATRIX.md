# Version Matrix

Current Core package version: `4.1.1`
Current release line: `v4.1.1`
Latest stable release: `v4.1.0`

Current stage: v4.1.1 Test Framework Governance after v4.1.0 Parser/OCR industrial hardening.

| Version | Goal | Key Capabilities | Key Commands | Key Outputs | Status | Supported by Current HEAD | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- |
| v0.1 | Initial local package proof | Markdown/TXT parsing, chunking, JSONL package basics | `build` | `chunks.jsonl`, `manifest.json` | historical | yes | Early foundation. |
| v1.6 | Contract and multimodal foundation | Contract v2, multimodal assets, OCR path, progress reports | `check-contract`, `build` | contract reports, OCR reports | historical | yes | Local only. |
| v1.7 | Governance and retrieval basics | Governance workflow, retrieval, evidence gate | `evidence-gate` | evidence reports | historical | yes | No SaaS. |
| v1.8 | Skill and Agent package generation | Skill packages, Agent package scaffolds | `generate-skill`, `generate-agent` | Skill and Agent package files | historical | yes | Mock/local LLM boundaries. |
| v1.9 | Workspace and provider registry | Workspace registry, prompt profiles, LLM audit | `workspace-init`, `provider-list` | registries and audit reports | historical | yes | Local workspace only. |
| v2.0 | Stable foundation | Studio runner, stable check, provider health, reliability | `studio-run`, `stable-check`, `provider-health` | stable check reports | historical | yes | Extension readiness is reserved. |
| v2.1 | Input and quality layer | Input hardening, quality reports, review, eval | `quality-gate`, `retrieval-eval` | quality and eval reports | historical | yes | Mock quality assist only. |
| v2.2 | Skill reverse and templates | Master Skill analysis, derived Skill generation | `analyze-skill`, `generate-derived-skill` | Skill analysis reports | historical | yes | No real platform runtime. |
| v2.3 | Batch governance | Batch jobs, package lineage, curation, update impact | `batch-run`, `package-lineage`, `curate-package` | batch and lineage reports | historical | yes | No platform distribution. |
| v2.3.1-dev | Post-v2.3 hardening | Batch and governance hardening | `batch-retry` | retry reports | historical | yes | Dev checkpoint. |
| v2.4 | Offline platform export | Platform export and mock publish boundary | `export-platform`, `mock-publish` | platform export reports | historical | yes | No real platform publishing. |
| v2.4.1-dev | Platform hardening | Export certification and compatibility checks | `certify-export`, `compatibility-matrix` | certification reports | historical | yes | Static/local checks. |
| v2.5.0-dev | Release quality gate | Release blockers, regression, release readiness | `release-readiness`, `release-blockers`, `regression-check` | release readiness reports | historical | yes | Local release quality gate. |
| v2.5.1-alpha.1 | CLI architecture convergence | CLI compatibility split, metadata convergence | `doctor` | doctor and readiness reports | historical | yes | Alpha checkpoint. |
| v2.6.0-alpha.1 | Provider governance | Provider registry, redaction, fallback, cost guard | `provider-list`, `provider-config-validate`, `provider-security-audit` | provider reports | historical | yes | Live smoke remains explicit opt-in. |
| v2.7.0-alpha.1 | Local portfolio demo | Offline demo evidence workflow | `demo-e2e` | demo evidence pack | historical | yes | No live platform runtime. |
| v2.8.0-alpha.1 | Parser reliability | Parser backend abstraction, trust gate, OCR risk | `parser-backend-list`, `parse-with-backend`, `trusted-kb-gate` | parser quality reports | historical | yes | Optional external parser adapters invoke installed runtimes when selected; default Core path remains builtin. |
| v2.9.0-alpha.1 | Knowledge Runtime Loop | Local KB index/query/answer, citations, refusal | `kb-index`, `kb-query`, `kb-answer` | KB runtime reports | superseded | yes | Still supported as a historical feature version. |
| v3.0.0-alpha.1 | Document Generation Loop | Grounded MD/DOCX/PDF/PPTX exports | `generate-documents`, `generate-md`, `generate-docx`, `generate-pdf`, `generate-pptx` | document generation reports | superseded | yes | Opt-in and local. |
| v3.1.0-alpha.1 | Knowledge-bound factory | Standalone and KB-bound Agent generation | `generate-agent`, `generate-bound-agent` | Agent package reports | superseded | yes | Stable CLI validation required. |
| v3.2.0-alpha.1 | Multi-KB / multi-Agent orchestration | Agent hierarchy, child KB boundaries, memory isolation contracts | `orchestrate-multi-kb` | hierarchy and memory reports | superseded | yes | Not a full long-term runtime database. |
| v3.3.0-alpha.1 | Skill reverse and fusion | Skill reverse/fusion safety | `reverse-fuse-skills` | fusion reports | superseded | yes | No prompt/code copying from external projects. |
| v3.4.0-alpha.1 | Workbench contracts | Navigation/action/status/asset/memory/storage contracts | `workbench-contracts` | workbench contract JSON | superseded | yes | Core contracts only; UI must validate separately. |
| v3.6.0-alpha.1 | External benchmark and gap audit | Architecture gap audit, external project benchmark, fusion plan | audit utility | root audit JSON reports | superseded | yes | Mandatory machine-readable evidence kept at root. |
| v3.7.0-alpha.1 | Query Rewrite & Retrieval Planning | Deterministic rewrite, expansion, decomposition, answering/validation plans | `rewrite-query`, `plan-retrieval`, `eval-query-rewrite` | query and retrieval plan reports | superseded | yes | No real LLM/API/network required. |
| v3.8.0-alpha.1 | Retrieval Quality & Evaluation | Multi-query recall, rerank, evidence selection, claim/source/freshness/accuracy reports | `eval-retrieval`, `rerank-results`, `select-evidence`, `verify-claims` | retrieval and accuracy reports | superseded | yes | External retrieval remains local/user-provided in v3.8. |
| v3.9.0-alpha.1 | Local Workspace Storage & Memory Lifecycle | Registries, retention, cleanup plans, local PDF token reduction | `init-workspace`, `scan-workspace`, `plan-memory-lifecycle`, `preprocess-pdf-markdown` | registry, memory, parser reports | superseded | yes | `local_workspace` is default; `local_db`/BYO cloud are future only. |
| v3.10.0-alpha.1 | Local Agent Runtime & Mother/Child Operations | Local runtime smoke, hierarchy routing, KB access boundary, memory policy reports | `run-local-agent`, `orchestrate-multi-kb` | runtime and hierarchy reports | superseded | yes | Not a cloud service or full autonomous runtime. |
| v3.11.0-alpha.1 | Golden Demo & Real Acceptance Smoke | Real sample smoke, artifact openability, compatibility, sample coverage | `run-golden-demo-acceptance` | acceptance reports | superseded | yes | Must be rerun for final release evidence. |
| v3.12.0-alpha.1 | Product Hardening & Local Release Readiness | doctor, command/package/workspace audits, privacy boundary, installer readiness, v4 gate | `product-hardening`, `doctor` | hardening and v4 gate reports | historical | yes | Latest completed alpha Core version. |
| final-pre-v4.0 | Full product truth gate | Capability proof, docs truth, security/privacy, scale, Core/UI drift, workflow acceptance | `final-pre-v4-audit` | final audit reports | completed | yes | Latest P0/P1 evidence reports `ready_for_v4_rc=true`. |
| v4.0.0-rc.1 | Local Knowledge Workbench release candidate | P1 final gate, external project registry, S/A contract inclusion, local-first release readiness | `doctor`, `release-readiness`, `final-pre-v4-audit` | rc evidence, release readiness reports | historical | yes | Candidate release accepted before stable v4.0.0. |
| v4.0.0 | Stable Local Knowledge Workbench release | Stable release after rc.1 acceptance and hardening | release-check workflow | release notes, tag, release-check CI | historical | yes | Untouched historical stable tag. |
| v4.1.0 | Parser/OCR Pluggable Backend Runtime | P2.1 release hardening for Docling, PaddleOCR, Unstructured, builtin fallback, evidence replay, failure modes, Workbench sync | `parser-backend-registry`, `parser-backend-matrix`, `parser-backend-inspect`, `parser-backend-smoke`, `parser-backend-release-evidence` | `docs/audits/p2_1_parser_ocr_backends/` | historical | yes | Historical Parser/OCR industrial release line; heavy dependencies remain optional. |
| v4.1.1 | Test Framework Governance | Validation gate manifest, changed-file impact selector, dry-run/executable validation runner, pytest markers, obsolete-test pruning register, token-efficient log policy | `python -m heitang_kb_forge.test_governance.gates` | `docs/testing/VALIDATION_GATE_MANIFEST.json`, `docs/testing/TEST_PRUNING_REGISTER.md` | current | yes | Current scalable validation and test governance release; no P2.2 feature work started. |

Unsupported or future:

- SaaS, multi-user permissions, team collaboration, platform-hosted user data, cloud sync, and BYO cloud/database are not implemented as current product defaults.
- LLM is optional assist only and no Core tests require real LLM/API/network calls.
- Historical v2.4 remains offline export / mock publish, not real platform publishing.
- Historical v2.5 remains the local release quality gate checkpoint.
