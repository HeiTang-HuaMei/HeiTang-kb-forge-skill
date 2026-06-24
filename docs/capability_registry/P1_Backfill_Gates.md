# P1 Backfill Gates

Status: `p1_backfill_routes_defined_needs_owner_review`

P1 starts only after P0 Core Acceptance and P0 Release Gate pass with Owner Review pending or accepted. P1 uses the same acceptance fields as P0: Core, UI Binding, Blackbox, Artifact, Event, Governance, Restart, Release status, evidence report, evidence commit, and linked blackbox cases.

## Entry Rule

P1 must not begin until:

1. All required P0 capability rows have `close_allowed=true` for their acceptance type.
2. `P0 Release Gate` writes `p0_release_gate_passed_needs_owner_review`.
3. `capability_chain_status.json` advances current phase to `P1`.
4. `global_goal_complete=false` remains true while P1/P2/Release gates remain.

## P1 Gate Groups

| Gate Group | Required Capability Rows | Acceptance Focus |
| --- | --- | --- |
| Capability Runner and Registry | `capability_chain_runner`, `capability_registry` | Queue execution, checkpoint/failure/resume, no single Gate equals global completion. |
| Memory and Evidence Basic | `memory_layer_separation`, `agent_memory_layer_basic`, `context_offload_basic`, `mermaid_task_map_basic`, `task_experience_reuse_basic`, `memory_adapter_research` | Memory separation, context offload, task map and experience reuse without direct TencentDB integration. |
| Knowledge Reliability Basic | `evidence_graph_basic`, `gap_analysis`, `citation_verification`, `knowledge_reliability_eval_suite`, `retrieval_regression`, `scope_resolver_basic`, `rule_extraction_basic`, `classification_reasoning_basic`, `conflict_exception_detection` | Evidence, citation, gap, rule, conflict and retrieval regression basics. |
| AI and Task Governance | `ai_config_governance`, `task_mode_router`, `plan_execute_runtime`, `model_pool_router_basic`, `role_protocol_basic` | Task profiles, routing, execution, verifier roles and no model overclaim. |
| Document / Skill / Office Basic | `document_template_registry`, `office_artifact_adapter`, `external_skill_import`, `workbench_skill_action_spec`, `assistant_backend_separation` | Template registry, DOCX/basic Office adapter research, action spec and backend separation. |
| UI and Configuration Checks | `ui_taste_gate`, `full_route_responsive_review`, `connection_configuration`, `hot_pluggable_project_config` | User-facing route quality, connection config and project config. |
| Harness / Policy / Loop Basic | `audit_report_enhancement`, `codex_execution_harness_enhancement`, `workbench_agent_execution_harness_basic`, `policy_governance_basic`, `credential_proxy_design`, `harness_adapter_spec`, `loop_runtime`, `stop_handoff_gate`, `loop_cost_boundary` | Execution harness, policy, credentials, loop control, cost and stop gates. |
| Knowledge Format and Views | `native_knowledge_format_semantic_schema`, `knowledge_canvas_basic`, `knowledge_base_table_view`, `clean_markdown_import`, `engineering_learning_samples` | Semantic schema, canvas/table views, markdown import and sample flows. |

## P1 Release Gate

P1 Release Gate must:

1. Confirm all required P1 rows are `close_allowed=true`.
2. Regress P0 user_blackbox, artifact, composite and governance acceptance.
3. Confirm no P1 change broke Event Ledger, Artifact Lifecycle, capability queue, OKF linked cases, reliability linked cases, or Agent Memory linked cases.
4. Write only `p1_release_gate_passed_needs_owner_review`.
5. Keep `global_goal_complete=false`.

## Not Allowed

- Do not enter P2 until P1 Release Gate passes.
- Do not write `production_ready`, `release_ready`, or `industrial_acceptance_passed`.
- Do not directly integrate external projects unless their Gate says `real_integration` and dependencies are accepted.
