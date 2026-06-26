# P2 Backfill Gates

Status: `p2_backfill_routes_defined_needs_owner_review`

P2 starts only after P1 Release Gate passes with Owner Review pending or accepted. P2 uses the same acceptance fields as P0/P1 and must include P0 + P1 regression at its stage exit.

## Entry Rule

P2 must not begin until:

1. All required P1 capability rows have `close_allowed=true`.
2. `P1 Release Gate` writes `p1_release_gate_passed_needs_owner_review`.
3. `capability_chain_status.json` advances current phase to `P2`.
4. `global_goal_complete=false` remains true while P2/Release gates remain.

## P2 Gate Groups

| Gate Group | Required Capability Rows | Acceptance Focus |
| --- | --- | --- |
| Workgroup / A2A | `a2a_workgroup`, `office_collaboration_workgroup`, `research_analysis_workgroup`, `role_based_workgroup`, `multi_agent_rag_deepening` | Workgroup runtime, A2A, multi-agent retrieval and role collaboration. |
| Industrial Connectors and Runtime | `project_config_industrial_isolation`, `connector_industrialization`, `react_tool_runtime_industrial`, `sandbox_tool_permission`, `session_share_fork_replay`, `cloud_disposable_sandbox` | Isolation, connectors, tool runtime, sandbox and replay. |
| Release-Adjacent Automation | `blackbox_automation_baseline`, `windows_packaging_baseline_smoke`, `official_sample_project_library`, `remote_task_control` | Automation baseline, packaging smoke baseline, Windows EXE Core/UI decoupling reservation, samples and remote control; final full matrix and final packaging regression remain P2 Release Gate duties. |
| Industrial Knowledge Governance | `multi_kb_governance_industrial`, `versioned_knowledge_governance`, `jurisdiction_domain_scope`, `human_review_console`, `reliability_score_industrial` | Multi-KB, versioning, jurisdiction, review and scoring. |
| Maintenance and Self-Improvement | `night_knowledge_maintenance`, `citation_auto_repair`, `memory_consolidation_industrial`, `retrieval_regression_benchmark_industrial`, `self_improving_knowledge_maintenance` | Maintenance loops, repair suggestions and benchmarks with human review. |
| Agent Memory Industrial | `agent_memory_industrial`, `mermaid_symbolic_memory_industrial`, `cross_agent_memory_migration`, `night_memory_consolidation_loop`, `memory_observability_panel`, `tencentdb_agent_memory_adapter_evaluation` | Industrial task memory, symbolic memory, migration, observability and optional adapter evaluation. |
| Orchestration and Human Brake | `polly_style_lead_orchestrator`, `fugu_multi_model_orchestration`, `loop_orchestrator_industrial`, `human_brake_judgment_gate`, `dataagent_foundation_industrial`, `native_skills_library`, `cli_agent_hub_evaluation`, `office_agent_industrialization` | Orchestration, human brake, data foundation, skills library, CLI hub and Office industrialization. |

## P2-4 Agent Template Landing Requirement

`P2-4 A2A >= 10 Agents` must include a user-facing "common assistant templates" entry point as the seed for creating a workgroup. Templates are not evidence by themselves; closure requires creating ten test-marked assistant instances from the templates and running one real workgroup task.

Required templates:

1. Material organizing assistant
2. Knowledge base QA assistant
3. Evidence verification assistant
4. Document writing assistant
5. Quality review assistant
6. Risk review assistant
7. Skill generation assistant
8. Task coordination assistant
9. Planning assistant
10. Delivery check assistant

P2-4 acceptance must verify:

1. The UI exposes product-facing names such as "common assistant templates" and "create workgroup", not provider, adapter, parser, matrix, or implementation project names.
2. A user can create ten temporary assistants with a test marker from the templates.
3. The ten assistants can run one workgroup task and produce per-assistant outputs, discussion summary, consensus/conflict report, Event Ledger entries and Artifact Catalog records.
4. Delete checks only remove the current test-marked assistants and generated workgroup artifacts.
5. Template existence alone must not set `close_allowed=true`; the ten-agent blackbox run and evidence package are required.

## P2 Knowledge, Skill and Document Template Landing Requirements

P2 must also carry common templates for knowledge bases, Skills and document generation. These templates are user-facing creation seeds, not completion evidence by themselves. Closure still requires real create/open/export/delete/restart evidence, Event Ledger records and Artifact Catalog records where applicable.

Template routing:

| Template Area | Target P2 Gate | Product-Facing Entry | Minimum Template Seed Set | Required Acceptance Evidence |
| --- | --- | --- | --- | --- |
| Knowledge base templates | `P2-13 Official Sample Project Library`; `P2-26 Multi-KB Governance Industrial`; `P2-27 Versioned Knowledge Governance` | "common knowledge base templates" and "create knowledge base" | company knowledge base, project archive, policy library, research library, customer support library | create test knowledge base from template, import test documents, build source trace, validate query/answer path, version/scope metadata where applicable, restart recovery and test-only deletion |
| Skill templates | `P2-22 Workbench Native Skills Library` | "common Skill templates" and "create Skill" | evidence QA Skill, document writing Skill, citation check Skill, task planning Skill, review checklist Skill | create test Skill from template, localize/bind to test knowledge base, validate/export/open/delete, write operation history, Event Ledger and Artifact Catalog records |
| Document generation templates | `P2-13 Official Sample Project Library`; `P2-25 Office Agent Industrialization` | "common document templates" and "generate document" | report, proposal, meeting summary, project plan, operating manual | select template, generate test document from a test knowledge base, bind citations/source trace, export supported format, open/export/delete, restart recovery, Event Ledger and Artifact Catalog records |

Template acceptance rules:

1. Templates must use product-facing names and must not expose provider, adapter, parser, matrix, or implementation project names in ordinary UI.
2. Template seed files alone must not set `close_allowed=true`.
3. Each template area must include at least one blackbox or artifact lifecycle path that creates a test-marked object and verifies visible user result plus persisted evidence.
4. Delete checks may only remove the current test-marked objects and generated artifacts.
5. P1 `Document Template Registry` remains the basic registry foundation; P2 adds broader product template packs and industrial lifecycle evidence.

## Deferred P2 External Project Absorption Landing Requirement

External projects classified as `absorb`, `learn`, or `reference` must not be treated as successfully absorbed by registration alone. Their project names must remain outside ordinary product UI, and they must not become runtime dependencies unless separately reclassified and accepted as `real_integration`.

This requirement is deliberately late in P2 order. It must not interrupt or rewrite the active P2 chain, must not create a new main Gate, and must not move any external project ahead of its owning P2 capability. Each owning P2 capability should record absorption proof only when it naturally closes, and the consolidated check belongs after the related P2 capability evidence exists and before or during `P2 Release Gate` regression.

Rolling-chain correction: the active P2 position must be read from `capability_chain_status.json` at evidence time. Any P0, P1, or P2 Gate that is not currently present in `remaining_gates` is historical fit only. It must not be used as retrospective acceptance evidence, active binding, closure proof, or status-machine write-back. Fresh absorption evidence can only attach to a P2 Gate still present in `remaining_gates`, to `P2 Release Gate` regression, or to a later Owner-approved capability. If a listed landing Gate leaves `remaining_gates` before absorption evidence is produced, that Gate automatically moves to historical fit.

Minimum absorption proof:

1. `extracted_strength`: the strongest one to three ideas learned from the external project.
2. `mapped_heitang_capability`: the existing HeiTang capability that owns the idea.
3. `native_design_change`: the HeiTang-native design, schema, workflow, test, audit, or UI-boundary change made without copying the external product as a module.
4. `user_or_quality_improvement`: the user-facing, reliability, governance, or maintainability improvement that can be observed or tested.
5. `evidence_report`: a report, source trace, validation output, blackbox result, or regression result proving the improvement.
6. `absorbed_status`: one of `absorb_candidate`, `absorbed_into_design`, `absorbed_into_runtime`, `absorbed_with_evidence`, or `rejected_after_review`.

Classification and product-improvement check:

1. Every external project must have exactly one `primary_handling` value for execution control: `real_integration`, `absorb`, `learn`, `reference`, or `reject`.
2. Secondary tags are allowed for nuance, such as `shape_reference`, `engineering_method`, `template_schema_reference`, `advanced_candidate`, or `connector_candidate`; secondary tags must not override the primary handling.
3. A project can both contribute an idea and inspire product shape, but closure must name which owning P2 capability accepts the concrete improvement.
4. P2 closure must compare the previous HeiTang behavior with the improved HeiTang behavior. If no user-path, quality, reliability, governance, or maintainability improvement is observable, the project remains `absorb_candidate` or moves to `rejected_after_review`.
5. Project accumulation is not accepted evidence. A larger list of external references cannot improve `close_allowed`; only verified HeiTang-native product improvement can support closure.

P2 product-improvement rubric:

| Dimension | Pass Standard | Not Enough |
| --- | --- | --- |
| User Value | The user can complete a task more clearly, with fewer steps, better output, or a safer next action. | Only naming an external product or adding a hidden entry. |
| Quality / Reliability | A test, benchmark, validation report, source_trace, or regression result shows better correctness, traceability, recall, recovery, or error handling. | A design note without executable or report evidence. |
| Native Fit | The improvement lands inside an existing HeiTang capability, schema, workflow, template, connector, or governance rule. | A new external-project-shaped module or ordinary UI project name. |
| Boundary Safety | No unapproved dependency, bundled service, secret exposure, local model training, GPU requirement, or user-data deletion risk is introduced. | A future integration claim without dependency and fallback proof. |
| Evidence Completeness | The owning P2 capability report records extracted strength, mapped capability, native change, before/after improvement, and evidence path. | A registry row that says `absorb`, `learn`, or `reference` without proof. |

Deferred P2 landing points:

| External Project Pattern | Historical Fit Only, No Retroactive Evidence | Rolling P2 Landing Point | Required Absorption Evidence |
| --- | --- | --- | --- |
| Knowledge reliability references such as WeKnora and GBrain | none | `P2-35 Retrieval Regression Benchmark Industrial`; `P2-36 Self-Improving Knowledge Maintenance` | benchmark, regression, source_trace, reliability report, or self-maintenance evidence that proves HeiTang reliability improved without exposing the reference project |
| Memory references such as MeMo / MEMO, LLM Wiki v2, and TencentDB Agent Memory | `P0-4C Agent Memory Minimal Core Gate`; `P1-48 Agent Memory Layer Basic` | `P2-33 Memory Consolidation Industrial`; `P2-37 Agent Memory Industrial`; `P2-42 TencentDB Agent Memory Adapter Evaluation / Optional Integration` | memory cards, consolidation report, migration/observability evidence, or optional-adapter evaluation with no local model training and no bundled external memory service |
| Agent orchestration and governance references such as Fugu, Omnigent, ECC, and Autoresearch / evo | `P2-18 Fugu-style Multi-Model Orchestration`; `P2-19 Loop Orchestrator Industrial`; `P2-20 Human Brake and Judgment Gate`; `P2-21 DataAgent Foundation Industrial` | `P2-23 CLI Agent Hub Evaluation` | role protocol, loop governance, checkpoint/failure/resume, human-brake, or harness evidence proving a HeiTang-native improvement |
| Workgroup product-shape references such as WorkBuddy / DeerFlow and gstack | `P2-10 Role-based Workgroup`; `P2-14 Polly-style Lead Orchestrator` | `P2 Release Gate` | closed workgroup-shape fit can be regression context only; fresh evidence must wait for release-gate regression or a later Owner-approved capability |
| Product workflow and UI-quality references such as AionUi and taste-skill | `P2-8 Blackbox Automation Baseline`; `P2-13 Official Sample Project Library` | `P2-22 Workbench Native Skills Library`; `P2-25 Office Agent Industrialization`; `P2 Release Gate` | route-level blackbox, responsive/taste regression, template/workflow evidence, generated artifact evidence, and no external project name in ordinary UI |
| Local-first knowledge workspace references such as Obsidian-Skills | none | `P2-22 Workbench Native Skills Library`; `P2-26 Multi-KB Governance Industrial`; `P2-27 Versioned Knowledge Governance`; `P2-34 Permission-Scoped Company Brain` | native open-format knowledge/Skill workflow, backlinks/source trace, multi-KB/version/scope evidence, and no cloned external workspace module |
| Current P2 absorption candidates such as OpenKnowledge | `P2-13 Official Sample Project Library` | `P2-22 Workbench Native Skills Library`; `P2-26 Multi-KB Governance Industrial`; `P2-27 Versioned Knowledge Governance`; `P2-34 Permission-Scoped Company Brain`; `P2-37 Agent Memory Industrial` | local-first Markdown/LLM Wiki direction, native knowledge package, durable memory, source trace, version/scope metadata, permission boundary, git-friendly collaboration evidence, and no external project name in ordinary UI |
| Current P2 absorption candidates such as SAG / SQL-augmented retrieval architecture references | `P1-4 Evidence Graph Basic`; `P1-7 Knowledge Reliability Eval Suite Basic`; `P1-8 Retrieval Regression Basic`; `P1-37 Heitang Native Knowledge Format Semantic Schema`; `P2-21 DataAgent Foundation Industrial` | `P2-26 Multi-KB Governance Industrial`; `P2-27 Versioned Knowledge Governance`; `P2-30 Reliability Score Industrial`; `P2-35 Retrieval Regression Benchmark Industrial`; `P2-36 Self-Improving Knowledge Maintenance`; `P2 Release Gate` | semantic event storage design, entity-index/source_trace mapping, SQL-join local graph or hyperedge retrieval benchmark, incremental update report, cross-document multi-hop retrieval regression, and no runtime/dependency/UI/project-name leakage |
| Current P2 absorption candidates such as RubyLLM / unified model interface | `P2-7 Connector Industrialization`; `P2-18 Fugu-style Multi-Model Orchestration` | `P2 Release Gate` | P2 Release Gate may regression-check unified model configuration, model-role routing, fallback, cost/token policy and masked-secret evidence without adopting the referenced runtime |
| Current P2 absorption candidates such as goal-first Skill learning flows | none | `P2-22 Workbench Native Skills Library`; `P2-23 CLI Agent Hub Evaluation`; `P2-25 Office Agent Industrialization` | native Skill template, learning plan artifact, Skill validation, export/open/delete evidence and no new learning main entry before Owner review |
| Current P2 absorption candidates for Agent memory productization | `P0-4C Agent Memory Minimal Core Gate`; `P1-48 Agent Memory Layer Basic` | `P2-33 Memory Consolidation Industrial`; `P2-37 Agent Memory Industrial`; `P2-41 Memory Observability Panel` | retrievable/updatable/forgettable memory cards, consolidation report, lifecycle checks, observability summary, restart recovery and test-only delete evidence |
| Connector and external-service references such as connect-apps, Redis Connector, Vector DB Connector, n8n, and OpenCLI Source Connector | `P2-7 Connector Industrialization`; `P2-15 Sandbox and Tool Permission Industrialization` | `P2-24 Remote Task Control`; `P2-35 Retrieval Regression Benchmark Industrial`; `P2 Release Gate` | connector health, permission boundary, masked-secret, fallback, audit, rollback, user-owned service boundary, source_trace/evidence_map/validation_report, and ordinary UI path evidence where applicable |
| Skill, template, and engineering-method references such as Composio / awesome-codex-skills, brooks-lint, codebase-recon, MMSkills, Jellyfish, story-flicks, seedance2-skill, RAG-Anything, and skill-prompt-generator | `P2-8 Blackbox Automation Baseline`; `P2-13 Official Sample Project Library` | `P2-22 Workbench Native Skills Library`; `P2-23 CLI Agent Hub Evaluation`; `P2-25 Office Agent Industrialization`; `P2-35 Retrieval Regression Benchmark Industrial` | native Skill/template/harness/test-matrix evidence showing the idea improved HeiTang without exposing the project name; story/video references may only contribute document/Skill structure and must not introduce GPU video generation |
| Advanced parsing candidates such as OpenDataLoader PDF, PaddleOCR, MinerU, Docling, Unstructured, Marker, and Surya | `P2-9 Windows Packaging Baseline Smoke` | `P2-35 Retrieval Regression Benchmark Industrial` | optional advanced parsing install/test/fallback evidence, document parsing quality evidence, and no default parser-runtime dependency |

Absorption cannot close a P2 capability by itself. It only supports the owning capability after that capability also passes its required core, blackbox or linked scenario, artifact, event, lifecycle, regression, and boundary checks.

P2 landing completeness rule:

1. Every non-rejected external project row must name at least one P2 landing point, even when it also has P0/P1 or already-run P2 historical or closed-reference context.
2. `reject` rows intentionally have no P2 landing point and must keep the rejection reason.
3. If a project has only P0/P1 ownership and no P2 landing point, the registry is incomplete until it is either mapped to an existing P2 capability or explicitly rejected/deferred with Owner review.
4. A P2 landing point is not evidence. It only identifies which P2 capability must later prove real HeiTang-native improvement.
5. Historical fit rows do not authorize rerunning or rewriting closed P0/P1/P2 gates; they are regression/reference context only.

## P2 Module-Level Token Mode Landing Requirement

P2 must add a module-level token economy policy for high-cost LLM, OCR, retrieval, Agent and external verification paths. This is a product runtime rule, not a single global switch and not a user-facing implementation matrix.

User-facing modes:

| Mode | Product Meaning | Runtime Behavior |
| --- | --- | --- |
| Economy | Save usage for routine work. | Use local parsing, cached artifacts, confidence gates and small evidence packets first; call LLM or external sources only for low-confidence, conflict, missing-evidence, latest-information or high-risk cases. |
| Standard | Balance quality and usage. | Use moderate retrieval depth, selective LLM validation and external verification when evidence is weak, stale, conflicting or important. |
| Deep | Maximize quality for important work. | Use larger evidence packets, stronger validation, multi-step review, broader retrieval and more active external verification while still enforcing token budgets and evidence boundaries. |

Module-level override is required. The product may have a global default, but each module must be able to record or apply its own mode when relevant:

| Module | Economy Requirement | Standard Requirement | Deep Requirement |
| --- | --- | --- | --- |
| Document parsing / OCR | Do not LLM-enhance clear text; only repair low-confidence regions. | Repair low-confidence regions and layout doubts with bounded evidence. | More aggressive structure recovery for important documents, still region-scoped. |
| Knowledge base and document retrieval | High-confidence local evidence answers directly. | Low-confidence, conflict or weak source_trace triggers LLM validation. | Cross-document reasoning, counter-evidence check and richer validation report. |
| Document generation | Use compact evidence packet and existing templates. | Include citation checks and structure validation. | Add outline review, citation review and quality review passes. |
| Skill generation | Use template-led generation with minimal validation. | Add validation and local binding checks. | Add test generation, review and revision loop. |
| Agent / Workgroup | Prefer single-agent or shared-evidence short runs. | Use bounded collaboration only when the task needs it. | Allow broader multi-agent review, conflict/consensus and stronger evidence package. |
| External information source verification | Default off unless requested, high-risk or evidence is insufficient. | Verify latest, stale, conflicting or important claims. | Actively verify key claims through bounded trusted sources. |

The runtime must still enforce token budgets in all modes. Deep mode increases budget and verification depth; it must not pass full documents, full chat history, full search results or full web pages to the LLM by default.

Required white-box evidence:

1. A persisted or inspectable policy model exists for global default plus per-module override.
2. Economy, Standard and Deep produce different budgets, retrieval depth, validation triggers and external-verification behavior.
3. Confidence gates skip LLM enhancement for clear OCR/text, high-confidence retrieval and internally consistent source_trace.
4. Selective enhancement sends only low-confidence OCR regions, retrieval conflicts, missing evidence, stale/latest claims or high-risk claims to LLM or external verification.
5. Event Ledger or runtime report records selected mode, trigger reason, estimated token budget class, evidence packet size class and whether LLM or external verification was used.

Required grey-box evidence:

1. A user-visible module setting or equivalent product configuration can set different modes for at least two modules, such as Knowledge Base in Economy and Agent in Deep.
2. The UI shows product-facing names only, such as Economy, Standard and Deep; it must not expose provider, adapter, parser, matrix, token internals or external project names.
3. After running the same test-marked workflow with different module modes, reports show different runtime decisions while preserving the same user task boundary.
4. Mode changes persist across restart or reload where the owning module has durable configuration.

Required black-box evidence:

1. In Economy mode, clear text parsing does not trigger LLM OCR; high-confidence retrieval answers from source_trace without LLM validation; Event Ledger records the skip reason.
2. In Standard mode, an ambiguous retrieval or weak source_trace triggers bounded LLM validation and writes validation_report.
3. In Deep mode, a cross-document or Agent workgroup task performs broader evidence collection, conflict/consensus or review evidence, and still uses bounded evidence packets.
4. External information source verification runs only when the task asks for latest information, internal evidence is stale/conflicting/insufficient, or the claim is high risk; otherwise it records a no-external-check reason.
5. Regression confirms no mode treats full documents, full histories, full search results or full web pages as default prompt input.

## P2 Model Gateway Broad API Adaptation Landing Requirement

All P2 capabilities are held to the P2 industrial acceptance bar. This Model Gateway requirement does not downgrade earlier P2 gates and must not be retroactively mixed into `P2-6 Hot-Pluggable Project Config Industrial Isolation` after that gate has run. It is a deferred cross-cutting P2 acceptance requirement for broad external model API adaptation across domestic and international hosted model services.

The requirement covers multi-provider onboarding, capability probing, availability smoke, model selection policy, module-level model binding, fallback, cost/token policy, error degradation, audit records, and white-box/grey-box/black-box acceptance. This is not local model training, not GPU inference, not bundled model weights and not packaging a model runtime into the EXE.

Scope:

1. Multi-provider onboarding for domestic, international and custom OpenAI-compatible API families.
2. Model capability probing for chat, document generation, Skill generation, Agent reasoning, Agent review, retrieval verification, citation verification, OCR repair, embedding and rerank roles.
3. Model availability smoke with harmless prompts, embedding dimension checks, auth failure, timeout, rate-limit and invalid-model handling.
4. Model selection policy that can choose by module, task role, token mode, cost class, latency class, context window, capability role and fallback priority.
5. Module-level model binding so different product modules can use different providers or roles without changing the global default.
6. Fallback and error degradation that disables only the affected role or module and gives the user a clear next action.
7. Cost/token strategy integration with Economy, Standard and Deep modes.
8. Audit records for provider family, model alias, role, selected mode, smoke status, latency class, cost class, fallback reason and masked secret state.

Deferred P2 landing points:

| P2 Gate | Responsibility |
| --- | --- |
| `P2-7 Connector Industrialization` | External model API connector health, timeout/rate-limit/auth failure handling, fallback and audit, without revising completed P2-6 evidence. |
| `P2-18 Fugu-style Multi-Model Orchestration` | Multi-provider role routing, verifier/reviewer model roles, fallback strategy, deterministic selection policy and no fake provider selection. |
| `P2 Release Gate` | Regression that provider configuration, token modes, model roles, masked secrets and external-service boundaries remain consistent across P2. |

Required provider coverage:

1. International hosted model API families such as OpenAI-compatible, Claude-compatible, Gemini-compatible, Mistral-compatible and Cohere-compatible services.
2. Domestic hosted model API families such as DeepSeek-compatible, Qwen-compatible, Zhipu-compatible, Baidu-compatible, Tencent-compatible, Moonshot-compatible, MiniMax-compatible, Baichuan-compatible and iFlytek-compatible services.
3. OpenAI-compatible custom endpoints for enterprise gateways or self-hosted API gateways.
4. Separate embedding provider support with dimension check and sample embedding smoke.
5. Optional rerank or verification provider support with bounded input and validation_report evidence.

Required role model:

- `chat_answer`
- `document_generation`
- `skill_generation`
- `agent_reasoning`
- `agent_review`
- `retrieval_verification`
- `citation_verification`
- `ocr_repair`
- `embedding`
- `rerank`

Required white-box evidence:

1. Provider configuration schema supports endpoint, model alias, provider family, role list, API key reference, timeout, rate limit and fallback policy without storing plaintext secrets.
2. Role routing rejects missing capabilities instead of silently routing to an arbitrary model.
3. Minimal harmless request smoke exists for chat-like models, embedding smoke includes dimension checks, and failure paths cover auth, timeout and rate limits.
4. Token mode policy can bind different model roles per module without bypassing token budgets.
5. Capability probing records supported roles, context-window class, cost class, latency class, streaming support where applicable, structured-output support where applicable and fallback priority.
6. Selection policy is deterministic for the same task, module and mode input, and records why the selected model was chosen.

Required grey-box evidence:

1. Settings or equivalent product configuration exposes ordinary language such as AI model service, embedding service, verification model and test connection.
2. Ordinary UI must not expose provider, adapter, parser, matrix, token internals or external project names as product modules.
3. A user can configure at least two model families or a model family plus custom endpoint, test them, and see masked status without revealing credentials.
4. Module-level binding can show that different modules use different allowed roles, such as Knowledge Base verification and Agent reasoning.
5. Changing a module binding affects only that module and does not silently change other modules.
6. Fallback state is visible as a product action such as "test connection", "choose another model service", or "use local evidence only", not as a provider matrix.

Required black-box evidence:

1. A configured model provider can pass a minimal harmless request and write Event Ledger plus validation_report evidence with masked secrets.
2. A configured embedding provider can create one sample vector, verify dimension, and reject incompatible vector configuration.
3. A failing provider shows a clear user action and falls back or disables only the affected role.
4. A module using an unsupported model role is blocked with a clear error and no silent downgrade.
5. Reports prove no local model training, bundled weights, GPU runtime requirement, plaintext secret, cookie or authorization header leakage.
6. Economy, Standard and Deep modes select different allowed budget/validation behavior without bypassing the configured model role.
7. At least one domestic family path, one international family path, one custom endpoint path and one embedding path are represented by smoke or documented blocked evidence before P2 Release Gate.

## P2 Source-Neutral Connectivity Policy

P2 treats outbound API connectivity as source-neutral. Ordinary product UI may ask only for a reachable endpoint, key/reference, model alias and a test action. It must not ask the user to classify the source as domestic, international, VPN-backed, or proxy-backed, and it must not expose VPN controls or bundled proxy logic.

1. If the user can reach the API under the current network environment, the product treats the service as usable.
2. The product may respect the user's existing system proxy settings for outbound access, but it does not bundle or manage VPN.
3. Local loopback traffic used by the app or test harness (`localhost`, `127.0.0.1`, `::1`) should bypass proxy routing by default so local UI and smoke tests remain stable.
4. Connection failures must report reachable/unreachable, auth, timeout, DNS, proxy, or rate-limit states without implying the source is the problem.
5. This policy is owned by `P2-7 Connector Industrialization`, `P2-18 Fugu-style Multi-Model Orchestration`, and `P2 Release Gate`.

## P2 Windows EXE Core/UI Decoupling Landing Requirement

`P2-9 Windows Packaging Baseline Smoke` must reserve the Core/UI decoupling contract needed by the Windows EXE path and future browser-hosted workbench paths. This is a packaging baseline requirement, not a macOS native-client rewrite and not final packaging acceptance.

Minimum baseline proof:

1. The core service can be described, started, health-checked, stopped and restarted independently from the Windows UI shell.
2. The UI shell talks to the core through an explicit local connection contract, such as a local endpoint, port, IPC channel or equivalent descriptor, instead of relying on hidden in-process assumptions.
3. Packaging smoke records startup, local service health, UI availability, config path, log/report path, exit/restart behavior and permission boundary for the current Windows build.
4. Redis, vector database, external model services and optional parsing engines remain external services or optional connectors; their service binaries must not be packaged into the EXE.
5. `P2-15 Sandbox and Tool Permission Industrialization` owns the path, permission, local-service boundary, secret masking and tool sandbox checks related to this decoupling contract.
6. macOS browser mode means local core service plus browser workbench access. It must not be treated as rebuilding a macOS native client.
7. Plugin or connector manifests that need platform targeting must reserve `platform_id` values such as `windows-x64`, `macos-arm64`, `macos-x64` and `linux-x64`.
8. `P2 Release Gate` must rerun final packaging, install, config, permission, rollback and Core/UI decoupling checks after all later P2 capabilities have landed.

This requirement must not retroactively rewrite completed P2 evidence. It becomes evidence only when `P2-9`, `P2-15` or `P2 Release Gate` records fresh smoke, report and regression output for the relevant slice.

## P2 External Source Verification User-Path Landing Requirement

P2 must prove that external source verification is not an internal-only capability. Ordinary product UI must provide a real user path for checking outside information, while still hiding implementation names from users. The user-facing path uses ordinary actions such as "search sources", "external check", "paste link", or "add manual evidence"; it must not show `OpenCLI`, provider, adapter, parser, router, matrix, or project names in ordinary UI.

This requirement is a deferred cross-cutting P2 acceptance requirement after `P2-6 Hot-Pluggable Project Config Industrial Isolation`. It must not retroactively rewrite completed P2 evidence, but it is mandatory before P2 Release Gate because it is the product check against closed-loop, internal-only answers.

Required product path:

```text
ordinary user action
-> search sources / external check / paste link / manual evidence
-> Source Searcher / Source Fetcher / Manual Evidence Importer
-> source_trace
-> evidence_map
-> validation_report
-> document library or knowledge-base verification path
-> answer, document, Skill, Agent, or workgroup evidence where applicable
```

Internal role boundaries:

| User-Facing Action | Internal Capability | Required Boundary |
| --- | --- | --- |
| Search sources / external check | OpenCLI Source Connector as a Source Searcher where configured and authorized | Candidate discovery only; not a URL body fetcher, crawler, browser automation tool, or UI label. |
| Paste link | Generic URL Fetcher or current link-source import path | Public URL body extraction or link record creation with source trace; not OpenCLI. |
| Manual evidence | Manual Evidence Importer | User-supplied evidence with secret, cookie, token and private-data guard. |
| Use verified evidence | Unified Source Trace / Evidence Map | No outside result may enter answers, documents, Skills, Agents or reports without trace and evidence linkage. |

Deferred P2 landing points:

| P2 Gate | Responsibility |
| --- | --- |
| `P2-7 Connector Industrialization` | Wire the ordinary user source-check path to configured connectors, health states, unavailable/degraded states, masked configuration, audit records and fallback. |
| `P2-35 Retrieval Regression Benchmark Industrial` | Prove external verification improves retrieval reliability, source freshness checks, conflict handling and citation validation without replacing local KB evidence. |
| `P2 Release Gate` | Regress the ordinary UI path, source trace, evidence map, validation report, document/KB handoff, no-secret scan, bounded network use and UI naming boundary. |

Required white-box evidence:

1. The runtime has an inspectable source acquisition path that separates Source Searcher, Source Fetcher and Manual Evidence Importer responsibilities.
2. The OpenCLI-backed Source Searcher path is invoked for external source candidate discovery when configured and authorized, and writes candidate, confidence, source trace, evidence map and validation report artifacts.
3. URL body extraction is handled by the fetcher path, not by the OpenCLI-backed search path.
4. Manual evidence is marked as manual evidence and cannot masquerade as public search or fetched web evidence.
5. Unavailable, unauthorized, timeout, invalid-query and network-failure paths write clear degraded evidence without claiming success.
6. Secret, cookie, token and authorization-header guards run before evidence is persisted.

Required grey-box evidence:

1. Ordinary UI exposes product actions such as "search sources", "external check", "paste link" or "add evidence", not `OpenCLI` or other implementation names.
2. A user-triggered source check creates or updates source trace, evidence map and validation report artifacts visible through product results or reports.
3. Accepted outside evidence can enter the document library or knowledge-base verification path with its trace preserved.
4. If the connector is unavailable or unconfigured, the UI shows a clear next action such as "configure external check", "try again later", "use local evidence only", or "paste a link"; it must not show raw provider, adapter, parser, router or project errors.
5. Economy, Standard and Deep token modes change when external checking is skipped, selective, or broader, while keeping bounded source packets.

Required black-box evidence:

1. From ordinary UI, a test-marked user can run an external check and produce a non-empty source trace, evidence map and validation report.
2. The same test verifies that the UI never displays `OpenCLI`, provider, adapter, parser, router, matrix, dependency gate, or `0/x` implementation status.
3. A pasted public link follows the URL fetch or link-source path and remains separate from OpenCLI candidate discovery.
4. A manual evidence item is accepted only when it passes secret/private-data guards and is labeled as manual evidence in trace outputs.
5. A retrieval, answer, document, Skill, Agent, or workgroup flow can use accepted external evidence with backlinks, or records why external evidence was not used.
6. Regression proves the product does not crawl broadly, bypass paywalls or CAPTCHA, import cookies/tokens, fetch private sources, or send full pages/search results to the LLM by default.

This requirement cannot close a P2 capability by itself. It supports the owning P2 capability only after that capability also passes its required core, user-path or linked scenario, artifact, event, lifecycle, regression and boundary checks.

## P2 Release Gate

P2 Release Gate must:

1. Confirm all required P2 rows are `close_allowed=true`.
2. Regress P0 + P1 + P2 acceptance.
3. Confirm no P2 industrial feature broke core lifecycle, user blackbox, linked blackbox, Event Ledger, Artifact Lifecycle, capability queue or staged release states.
4. Confirm module-level token modes have white-box, grey-box and black-box evidence for at least document parsing/OCR, knowledge retrieval, Agent/workgroup and external verification paths.
5. Confirm broad external model API adaptation has white-box, grey-box and black-box evidence for representative domestic, international, custom endpoint and embedding provider paths.
6. Confirm ordinary UI external source verification has white-box, grey-box and black-box evidence, including source trace, evidence map, validation report, document/KB handoff, no-secret scan and no implementation-name leakage.
7. Rerun the final full blackbox matrix, including all P2-1 through P2-42 cases appended after the P2-8 baseline.
8. Rerun final packaging/install/config/permission/rollback and Core/UI decoupling checks, including all capabilities added after the P2-9 baseline.
9. Write only `p2_release_gate_passed_needs_owner_review`.
10. Keep `global_goal_complete=false` until Final Owner Review remains.

## Not Allowed

- Do not write `production_ready`, `release_ready`, or `industrial_acceptance_passed`.
- Do not treat P2 Release Gate as public release.
- Do not auto-merge or auto-overwrite high-risk knowledge without human review.
