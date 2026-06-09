# 版本矩阵

当前 Core package 版本：`4.0.0rc1`
当前 release candidate：`v4.0.0-rc.1`

当前阶段：v4.0.0-rc.1 release candidate preparation。stable v4.0.0 等待 rc.1 acceptance 与 hardening。

| Version | Goal | Key Capabilities | Key Commands | Key Outputs | Status | Supported by Current HEAD | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- |
| v0.1 | 初始本地知识包证明 | Markdown/TXT parsing、chunking、JSONL package basics | `build` | `chunks.jsonl`, `manifest.json` | historical | yes | 早期基础。 |
| v1.6 | Contract 与 multimodal 基础 | Contract v2、multimodal assets、OCR path、progress reports | `check-contract`, `build` | contract reports, OCR reports | historical | yes | local only。 |
| v1.7 | Governance 与 retrieval 基础 | Governance workflow、retrieval、evidence gate | `evidence-gate` | evidence reports | historical | yes | no SaaS。 |
| v1.8 | Skill 与 Agent package generation | Skill packages、Agent package scaffolds | `generate-skill`, `generate-agent` | Skill and Agent package files | historical | yes | mock/local LLM 边界。 |
| v1.9 | Workspace 与 provider registry | Workspace registry、prompt profiles、LLM audit | `workspace-init`, `provider-list` | registries and audit reports | historical | yes | local workspace only。 |
| v2.0 | Stable foundation | Studio runner、stable check、provider health、reliability | `studio-run`, `stable-check`, `provider-health` | stable check reports | historical | yes | extension readiness reserved。 |
| v2.1 | Input and quality layer | Input hardening、quality reports、review、eval | `quality-gate`, `retrieval-eval` | quality and eval reports | historical | yes | mock quality assist only。 |
| v2.2 | Skill reverse and templates | Master Skill analysis、derived Skill generation | `analyze-skill`, `generate-derived-skill` | Skill analysis reports | historical | yes | no real platform runtime。 |
| v2.3 | Batch governance | Batch jobs、package lineage、curation、update impact | `batch-run`, `package-lineage`, `curate-package` | batch and lineage reports | historical | yes | no platform distribution。 |
| v2.3.1-dev | Post-v2.3 hardening | Batch and governance hardening | `batch-retry` | retry reports | historical | yes | dev checkpoint。 |
| v2.4 | Offline platform export | Platform export and mock publish boundary | `export-platform`, `mock-publish` | platform export reports | historical | yes | no real platform publishing。 |
| v2.4.1-dev | Platform hardening | Export certification and compatibility checks | `certify-export`, `compatibility-matrix` | certification reports | historical | yes | static/local checks。 |
| v2.5.0-dev | Release quality gate | Release blockers、regression、release readiness | `release-readiness`, `release-blockers`, `regression-check` | release readiness reports | historical | yes | local release quality gate。 |
| v2.5.1-alpha.1 | CLI architecture convergence | CLI compatibility split、metadata convergence | `doctor` | doctor and readiness reports | historical | yes | alpha checkpoint。 |
| v2.6.0-alpha.1 | Provider governance | Provider registry、redaction、fallback、cost guard | `provider-list`, `provider-config-validate`, `provider-security-audit` | provider reports | historical | yes | live smoke 必须显式 opt-in。 |
| v2.7.0-alpha.1 | Local portfolio demo | Offline demo evidence workflow | `demo-e2e` | demo evidence pack | historical | yes | no live platform runtime。 |
| v2.8.0-alpha.1 | Parser reliability | Parser backend abstraction、trust gate、OCR risk | `parser-backend-list`, `parse-with-backend`, `trusted-kb-gate` | parser quality reports | historical | yes | optional external parser stubs only。 |
| v2.9.0-alpha.1 | Knowledge Runtime Loop | Local KB index/query/answer、citations、refusal | `kb-index`, `kb-query`, `kb-answer` | KB runtime reports | superseded | yes | 作为历史功能版本仍支持。 |
| v3.0.0-alpha.1 | Document Generation Loop | Grounded MD/DOCX/PDF/PPTX exports | `generate-documents`, `generate-md`, `generate-docx`, `generate-pdf`, `generate-pptx` | document generation reports | superseded | yes | opt-in and local。 |
| v3.1.0-alpha.1 | Knowledge-bound factory | Standalone and KB-bound Agent generation | `generate-agent`, `generate-bound-agent` | Agent package reports | superseded | yes | CLI validation 稳定。 |
| v3.2.0-alpha.1 | Multi-KB / multi-Agent orchestration | Agent hierarchy、child KB boundaries、memory isolation contracts | `orchestrate-multi-kb` | hierarchy and memory reports | superseded | yes | 不是长期 runtime database。 |
| v3.3.0-alpha.1 | Skill reverse and fusion | Skill reverse/fusion safety | `reverse-fuse-skills` | fusion reports | superseded | yes | 不复制外部 prompt/code。 |
| v3.4.0-alpha.1 | Workbench contracts | Navigation/action/status/asset/memory/storage contracts | `workbench-contracts` | workbench contract JSON | superseded | yes | Core contracts only，UI 单独验证。 |
| v3.6.0-alpha.1 | External benchmark and gap audit | Architecture gap audit、external benchmark、fusion plan | audit utility | root audit JSON reports | superseded | yes | 根目录保留机器可读证据。 |
| v3.7.0-alpha.1 | Query Rewrite & Retrieval Planning | Deterministic rewrite、expansion、decomposition、answering/validation plans | `rewrite-query`, `plan-retrieval`, `eval-query-rewrite` | query and retrieval plan reports | superseded | yes | 不需要真实 LLM/API/network。 |
| v3.8.0-alpha.1 | Retrieval Quality & Evaluation | Multi-query recall、rerank、evidence selection、claim/source/freshness/accuracy reports | `eval-retrieval`, `rerank-results`, `select-evidence`, `verify-claims` | retrieval and accuracy reports | superseded | yes | v3.8 外部验证仍为本地/用户提供来源。 |
| v3.9.0-alpha.1 | Local Workspace Storage & Memory Lifecycle | Registries、retention、cleanup plans、本地 PDF token reduction | `init-workspace`, `scan-workspace`, `plan-memory-lifecycle`, `preprocess-pdf-markdown` | registry, memory, parser reports | superseded | yes | 默认 `local_workspace`；`local_db`/BYO cloud 是 future only。 |
| v3.10.0-alpha.1 | Local Agent Runtime & Mother/Child Operations | Local runtime smoke、hierarchy routing、KB boundary、memory policy reports | `run-local-agent`, `orchestrate-multi-kb` | runtime and hierarchy reports | superseded | yes | 不是 cloud service 或 full autonomous runtime。 |
| v3.11.0-alpha.1 | Golden Demo & Real Acceptance Smoke | Real sample smoke、artifact openability、compatibility、sample coverage | `run-golden-demo-acceptance` | acceptance reports | superseded | yes | final release evidence 前必须重跑。 |
| v3.12.0-alpha.1 | Product Hardening & Local Release Readiness | doctor、command/package/workspace audits、privacy boundary、installer readiness、v4 gate | `product-hardening`, `doctor` | hardening and v4 gate reports | historical | yes | 最新已完成 alpha Core 版本。 |
| final-pre-v4.0 | Full product truth gate | Capability proof、docs truth、security/privacy、scale、Core/UI drift、workflow acceptance | `final-pre-v4-audit` | final audit reports | completed | yes | 最新 P0/P1 证据显示 `ready_for_v4_rc=true`。 |
| v4.0.0-rc.1 | Local Knowledge Workbench release candidate | P1 final gate、external project registry、S/A contract inclusion、local-first release readiness | `doctor`, `release-readiness`, `final-pre-v4-audit` | rc evidence、release readiness reports | current | yes | Candidate release；不是 stable v4.0.0。 |
| v4.0.0 | Stable Local Knowledge Workbench release | rc.1 acceptance 与 hardening 之后的 stable release | release-check workflow | release notes、tag、release-check CI | future | no | rc.1 acceptance 前不得声明 stable。 |

不支持或未来项：

- SaaS、多用户权限、团队协作、platform-hosted user data、cloud sync、BYO cloud/database 都不是当前默认实现。
- LLM 只是 optional assist，Core tests 不需要真实 LLM/API/network。
