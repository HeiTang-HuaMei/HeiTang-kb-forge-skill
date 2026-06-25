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
| Release-Adjacent Automation | `full_blackbox_automation_matrix`, `exe_packaging_release`, `official_sample_project_library`, `remote_task_control` | Full automation matrix, packaging experience, samples and remote control. |
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

This requirement is deliberately late in P2 order. It must not interrupt `P2-4 A2A >= 10 Agents`, must not create a new main Gate, and must not move any external project ahead of its owning P2 capability. Each owning P2 capability should record absorption proof only when it naturally closes, and the consolidated check belongs after the related P2 capability evidence exists and before `P2 Release Gate`.

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

| External Project Pattern | Owning P2 Landing Point | Required Absorption Evidence |
| --- | --- | --- |
| Knowledge reliability references such as WeKnora and GBrain | `P2-35 Retrieval Regression Benchmark Industrial`; `P2-36 Self-Improving Knowledge Maintenance` | benchmark, regression, source_trace, reliability report, or self-maintenance evidence that proves HeiTang reliability improved without exposing the reference project |
| Memory references such as MeMo / MEMO, LLM Wiki v2, and TencentDB Agent Memory | `P2-33 Memory Consolidation Industrial`; `P2-37 Agent Memory Industrial`; `P2-42 TencentDB Agent Memory Adapter Evaluation / Optional Integration` | memory cards, consolidation report, migration/observability evidence, or optional-adapter evaluation with no local model training and no bundled external memory service |
| Agent orchestration and governance references such as Fugu, Omnigent, ECC, and Autoresearch / evo | `P2-18 Fugu-style Multi-Model Orchestration`; `P2-19 Loop Orchestrator Industrial`; `P2-20 Human Brake and Judgment Gate`; `P2-23 CLI Agent Hub Evaluation` | role protocol, loop governance, checkpoint/failure/resume, human-brake, or harness evidence proving a HeiTang-native improvement |
| Workgroup product-shape references such as WorkBuddy / DeerFlow and gstack | `P2-10 Role-based Workgroup`; `P2-14 Polly-style Lead Orchestrator` | role template, workgroup task, conflict/consensus, Event Ledger, Artifact Catalog, restart, and test-only delete evidence |
| Connector and external-service references such as connect-apps, Redis Connector, Vector DB Connector, and n8n | `P2-7 Connector Industrialization`; `P2-15 Sandbox and Tool Permission Industrialization` | connector health, permission boundary, masked-secret, fallback, audit, rollback, and user-owned service boundary evidence |
| Skill, template, and engineering-method references such as Composio / awesome-codex-skills, brooks-lint, codebase-recon, MMSkills, RAG-Anything, and skill-prompt-generator | `P2-8 Full Blackbox Automation Matrix`; `P2-22 Workbench Native Skills Library`; `P2-23 CLI Agent Hub Evaluation` | native Skill/template/harness/test-matrix evidence showing the idea improved HeiTang without exposing the project name |
| Advanced parsing candidates such as OpenDataLoader PDF, PaddleOCR, MinerU, Docling, Unstructured, Marker, and Surya | `P2-9 EXE Packaging and Installation Experience`; `P2-35 Retrieval Regression Benchmark Industrial` | optional advanced parsing install/test/fallback evidence, document parsing quality evidence, and no default parser-runtime dependency |

Absorption cannot close a P2 capability by itself. It only supports the owning capability after that capability also passes its required core, blackbox or linked scenario, artifact, event, lifecycle, regression, and boundary checks.

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

## P2 Release Gate

P2 Release Gate must:

1. Confirm all required P2 rows are `close_allowed=true`.
2. Regress P0 + P1 + P2 acceptance.
3. Confirm no P2 industrial feature broke core lifecycle, user blackbox, linked blackbox, Event Ledger, Artifact Lifecycle, capability queue or staged release states.
4. Confirm module-level token modes have white-box, grey-box and black-box evidence for at least document parsing/OCR, knowledge retrieval, Agent/workgroup and external verification paths.
5. Write only `p2_release_gate_passed_needs_owner_review`.
6. Keep `global_goal_complete=false` until Final Owner Review remains.

## Not Allowed

- Do not write `production_ready`, `release_ready`, or `industrial_acceptance_passed`.
- Do not treat P2 Release Gate as public release.
- Do not auto-merge or auto-overwrite high-risk knowledge without human review.
