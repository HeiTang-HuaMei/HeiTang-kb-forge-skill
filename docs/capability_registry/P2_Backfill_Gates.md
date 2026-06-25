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

## P2 Release Gate

P2 Release Gate must:

1. Confirm all required P2 rows are `close_allowed=true`.
2. Regress P0 + P1 + P2 acceptance.
3. Confirm no P2 industrial feature broke core lifecycle, user blackbox, linked blackbox, Event Ledger, Artifact Lifecycle, capability queue or staged release states.
4. Write only `p2_release_gate_passed_needs_owner_review`.
5. Keep `global_goal_complete=false` until Final Owner Review remains.

## Not Allowed

- Do not write `production_ready`, `release_ready`, or `industrial_acceptance_passed`.
- Do not treat P2 Release Gate as public release.
- Do not auto-merge or auto-overwrite high-risk knowledge without human review.
