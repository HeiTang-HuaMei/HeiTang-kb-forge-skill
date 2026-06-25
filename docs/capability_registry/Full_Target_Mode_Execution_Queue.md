# Full Target Mode Execution Queue

Status: `full_target_mode_plan_generated_needs_execution`
Generated at: `2026-06-24T16:14:29.312025Z`

This queue is derived from `capability_chain_status.json` and `Capability_Implementation_Status.md`. It is an execution plan only.

## Chain Order From Status Machine

1. P0-4C Agent Memory Minimal Core Gate
2. P0-5B Knowledge Reliability Minimal Core Gate
3. P0 Core Lifecycle Acceptance Gate (rerun after P0 backfill)
4. P0 Release Gate
5. P1-1 Capability Chain Runner
6. P1-2 Capability Registry
7. P1-3 Memory Layer Separation Basic
8. P1-4 Evidence Graph Basic
9. P1-5 Gap Analysis Basic Plus
10. P1-6 Citation Verification Basic Plus
11. P1-7 Knowledge Reliability Eval Suite Basic
12. P1-8 Retrieval Regression Basic
13. P1-9 Scope Resolver Basic
14. P1-10 Rule Extraction Basic
15. P1-11 Classification Reasoning Basic
16. P1-12 Conflict and Exception Detection Basic
17. P1-13 AI Config Governance Basic
18. P1-14 Task Mode Router Basic
19. P1-15 Plan-and-Execute Runtime Basic
20. P1-16 Long Document Reading Strategy Basic
21. P1-17 External Skill Import Basic
22. P1-18 Workbench Skill Action Spec
23. P1-19 Document Template Registry
24. P1-20 Office Artifact Adapter Research / DOCX Basic
25. P1-21 Assistant Backend Separation
26. P1-22 UI Taste Gate
27. P1-23 Full Route Responsive Review
28. P1-24 Connection Configuration Blackbox Verification
29. P1-25 Hot-Pluggable Project Config Basic
30. P1-26 Audit Report Enhancement
31. P1-27 Codex Execution Harness Enhancement
32. P1-28 Workbench Agent Execution Harness Basic
33. P1-29 Policy Governance Basic
34. P1-30 Credential Proxy Design
35. P1-31 Harness Adapter Spec
36. P1-32 Model Pool Router Basic
37. P1-33 Thinker / Worker / Verifier Role Protocol
38. P1-34 Loop Runtime Basic
39. P1-35 Stop and Handoff Gate
40. P1-36 Loop Cost Boundary Basic
41. P1-37 Heitang Native Knowledge Format Semantic Schema
42. P1-38 Knowledge Canvas Basic
43. P1-39 Knowledge Base Table View
44. P1-40 Clean Markdown Import
45. P1-41 Engineering Learning Samples Basic
46. P1-48 Agent Memory Layer Basic
47. P1-49 Context Offload Basic
48. P1-50 Mermaid Task Map Basic
49. P1-51 Task Experience Reuse Basic
50. P1-52 OpenClaw / Hermes Memory Adapter Research
51. P1 Release Gate
52. P2-1 Workgroup Basic Runtime
53. P2-2 Office Collaboration Workgroup
54. P2-3 Research Analysis Workgroup
55. P2-4 A2A >= 10 Agents, including common assistant templates as creation seeds and a real ten-test-agent workgroup run
56. P2-5 Multi-Agent RAG Deepening
57. P2-6 Hot-Pluggable Project Config Industrial Isolation
58. P2-7 Connector Industrialization, including ordinary UI external source verification connector binding
59. P2-8 Blackbox Automation Baseline
60. P2-9 Windows Packaging Baseline Smoke
61. P2-10 Role-based Workgroup
62. P2-11 ReAct Tool Runtime Industrialization
63. P2-12 Long Context Evaluation
64. P2-13 Official Sample Project Library, including common knowledge base and document template sample packs
65. P2-14 Polly-style Lead Orchestrator
66. P2-15 Sandbox and Tool Permission Industrialization
67. P2-16 Session Share / Fork / Replay
68. P2-17 Cloud Disposable Sandbox Evaluation
69. P2-18 Fugu-style Multi-Model Orchestration
70. P2-19 Loop Orchestrator Industrial
71. P2-20 Human Brake and Judgment Gate
72. P2-21 DataAgent Foundation Industrial
73. P2-22 Workbench Native Skills Library, including common Skill templates as creation seeds
74. P2-23 CLI Agent Hub Evaluation
75. P2-24 Remote Task Control
76. P2-25 Office Agent Industrialization, including document generation template use in Office workflows
77. P2-26 Multi-KB Governance Industrial
78. P2-27 Versioned Knowledge Governance
79. P2-28 Jurisdiction / Domain Scope
80. P2-29 Human Review Console
81. P2-30 Reliability Score Industrial
82. P2-31 Night Knowledge Maintenance Loop
83. P2-32 Citation Auto-Repair Industrial
84. P2-33 Memory Consolidation Industrial
85. P2-34 Permission-Scoped Company Brain
86. P2-35 Retrieval Regression Benchmark Industrial, including external source verification reliability regression
87. P2-36 Self-Improving Knowledge Maintenance
88. P2-37 Agent Memory Industrial
89. P2-38 Mermaid Symbolic Memory Industrial
90. P2-39 Cross-Agent Memory Migration
91. P2-40 Night Memory Consolidation Loop
92. P2-41 Memory Observability Panel
93. P2-42 TencentDB Agent Memory Adapter Evaluation / Optional Integration
94. P2 Release Gate, including ordinary UI external source verification black/grey/white evidence
95. Final Owner Review Gate

## Capability Rows By Registry Order

| # | phase | capability_id | acceptance_type | close_allowed | release_blocker | current_status | next_gate |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | P0 | event_ledger | user_blackbox | true | true | core=passed; ui=passed; blackbox=passed; artifact=not_required; event=not_required; governance=not_required; restart=passed; close_allowed=true; release_blocker=true | Owner Review |
| 2 | P0 | artifact_lifecycle | artifact | true | true | core=passed; ui=passed; blackbox=passed; artifact=passed; event=not_required; governance=not_required; restart=passed; close_allowed=true; release_blocker=true | Owner Review |
| 3 | P0 | external_project_classification_registry | governance | true | true | core=passed; ui=not_required; blackbox=not_required; artifact=not_required; event=not_required; governance=passed; restart=passed; close_allowed=true; release_blocker=true | Owner Review |
| 4 | P0 | industrial_scope_metadata | core_only | true | true | core=passed; ui=not_required; blackbox=not_required; artifact=not_required; event=not_required; governance=not_required; restart=not_required; close_allowed=true; release_blocker=true | `P1-9 Scope Resolver Basic` |
| 5 | P0 | agent_p0_single_assistant | user_blackbox | true | true | core=passed; ui=passed; blackbox=passed; artifact=not_required; event=not_required; governance=not_required; restart=passed; close_allowed=true; release_blocker=true | Owner Review plus `P0-10 Assistant Bound-KB Integration`; linked/blackbox: Owner Review |
| 6 | P0 | document_library_lifecycle | user_blackbox | true | true | core=passed; ui=passed; blackbox=passed; artifact=not_required; event=not_required; governance=not_required; restart=passed; close_allowed=true; release_blocker=true | Owner Review |
| 7 | P0 | okf_minimal_core | composite | false | true | core=passed; ui=linked_partial; blackbox=linked_partial; artifact=passed; event=passed; governance=not_required; restart=linked_partial; close_allowed=false; release_blocker=true | Owner Review plus `P0-5B Knowledge Reliability Minimal Core Gate`; linked/blackbox: linked cases in P0 Core Acceptance rerun |
| 8 | P0 | material_organizing_kb_generation | user_blackbox | true | true | core=passed; ui=passed; blackbox=passed; artifact=not_required; event=not_required; governance=not_required; restart=passed; close_allowed=true; release_blocker=true | Owner Review plus `P0-5B Knowledge Reliability Minimal Core Gate`; linked/blackbox: Owner Review |
| 9 | P0 | knowledge_base_validation | artifact | true | true | core=passed; ui=passed; blackbox=passed; artifact=passed; event=not_required; governance=not_required; restart=passed; close_allowed=true; release_blocker=true | Owner Review plus `P0-5B Knowledge Reliability Minimal Core Gate`; linked/blackbox: Owner Review |
| 10 | P0 | knowledge_reliability_minimal_core | composite | false | true | core=partial; ui=linked_required; blackbox=linked_required; artifact=partial; event=partial; governance=not_required; restart=partial; close_allowed=false; release_blocker=true | `P0-5B Knowledge Reliability Minimal Core Gate`; linked/blackbox: linked cases in P0 Core Acceptance rerun |
| 11 | P0 | memory_evidence_metadata | core_only | true | true | core=passed; ui=not_required; blackbox=not_required; artifact=not_required; event=not_required; governance=not_required; restart=not_required; close_allowed=true; release_blocker=true | `P1-3 Memory Layer Separation Basic`; `P1-4 Evidence Graph Basic` |
| 12 | P0 | agent_memory_minimal_core | composite | false | true | core=not_started; ui=linked_required; blackbox=linked_required; artifact=not_started; event=not_started; governance=not_started; restart=not_started; close_allowed=false; release_blocker=true | `P0-4C Agent Memory Minimal Core Gate`; linked/blackbox: linked recovery scenario in `P0-4C Agent Memory Minimal Core Gate` |
| 13 | P0 | document_generation | artifact | true | true | core=passed; ui=passed; blackbox=passed; artifact=passed; event=not_required; governance=not_required; restart=passed; close_allowed=true; release_blocker=true | Owner Review, then `P1-19 Document Template Registry`; linked/blackbox: Owner Review |
| 14 | P0 | skill_generation | artifact | true | true | core=passed; ui=passed; blackbox=passed; artifact=passed; event=not_required; governance=not_required; restart=passed; close_allowed=true; release_blocker=true | Owner Review, then P1/P2 skill library gates; linked/blackbox: Owner Review |
| 15 | P0 | assistant_bound_kb_integration | user_blackbox | false | true | core=partial; ui=blocked; blackbox=blocked; artifact=not_required; event=not_required; governance=not_required; restart=partial; close_allowed=false; release_blocker=true | `P0-10 Assistant Bound-KB Integration` in P0 Core Acceptance rerun; linked/blackbox: `P0 Core Lifecycle Acceptance Gate (dual-track rerun)` |
| 16 | P0 | settings_path_export | user_blackbox | true | true | core=passed; ui=passed; blackbox=passed; artifact=not_required; event=not_required; governance=not_required; restart=passed; close_allowed=true; release_blocker=true | Owner Review, then P1 connection/config gates; linked/blackbox: Owner Review |
| 17 | P0 | p0_core_acceptance | governance | false | true | core=partial; ui=not_required; blackbox=not_required; artifact=not_required; event=not_required; governance=partial; restart=partial; close_allowed=false; release_blocker=true | `P0 Core Lifecycle Acceptance Gate (rerun after P0 backfill)` |
| 18 | P0 | p0_release_gate | governance | false | true | core=not_started; ui=not_required; blackbox=not_required; artifact=not_required; event=not_required; governance=not_started; restart=not_started; close_allowed=false; release_blocker=true | P0 Release Gate |
| 19 | P1 | capability_chain_runner | core_only | false | true | core=partial; ui=not_required; blackbox=not_required; artifact=not_required; event=not_required; governance=not_required; restart=not_required; close_allowed=false; release_blocker=true | `P1-1 Capability Chain Runner` |
| 20 | P1 | capability_registry | governance | true | true | core=passed; ui=not_required; blackbox=not_required; artifact=not_required; event=not_required; governance=passed; restart=passed; close_allowed=true; release_blocker=true | Owner Review after P0 backfill rerun |
| 21 | P1 | memory_layer_separation | core_only | false | true | core=not_started; ui=not_required; blackbox=not_required; artifact=not_required; event=not_required; governance=not_required; restart=not_required; close_allowed=false; release_blocker=true | `P1-3 Memory Layer Separation Basic` |
| 22 | P1 | agent_memory_layer_basic | core_only | false | true | core=not_started; ui=not_required; blackbox=not_required; artifact=not_required; event=not_required; governance=not_required; restart=not_required; close_allowed=false; release_blocker=true | `P1-48 Agent Memory Layer Basic` |
| 23 | P1 | context_offload_basic | core_only | false | true | core=not_started; ui=not_required; blackbox=not_required; artifact=not_required; event=not_required; governance=not_required; restart=not_required; close_allowed=false; release_blocker=true | `P1-49 Context Offload Basic` |
| 24 | P1 | mermaid_task_map_basic | core_only | false | true | core=not_started; ui=not_required; blackbox=not_required; artifact=not_required; event=not_required; governance=not_required; restart=not_required; close_allowed=false; release_blocker=true | `P1-50 Mermaid Task Map Basic` |
| 25 | P1 | task_experience_reuse_basic | core_only | false | true | core=not_started; ui=not_required; blackbox=not_required; artifact=not_required; event=not_required; governance=not_required; restart=not_required; close_allowed=false; release_blocker=true | `P1-51 Task Experience Reuse Basic` |
| 26 | P1 | memory_adapter_research | core_only | false | true | core=not_started; ui=not_required; blackbox=not_required; artifact=not_required; event=not_required; governance=not_required; restart=not_required; close_allowed=false; release_blocker=true | `P1-52 OpenClaw / Hermes Memory Adapter Research` |
| 27 | P1 | evidence_graph_basic | core_only | false | true | core=not_started; ui=not_required; blackbox=not_required; artifact=not_required; event=not_required; governance=not_required; restart=not_required; close_allowed=false; release_blocker=true | `P1-4 Evidence Graph Basic` |
| 28 | P1 | gap_analysis | core_only | false | true | core=not_started; ui=not_required; blackbox=not_required; artifact=not_required; event=not_required; governance=not_required; restart=not_required; close_allowed=false; release_blocker=true | `P1-5 Gap Analysis Basic Plus`; P0 minimum in `P0-5B` |
| 29 | P1 | citation_verification | core_only | false | true | core=partial; ui=not_required; blackbox=not_required; artifact=not_required; event=not_required; governance=not_required; restart=not_required; close_allowed=false; release_blocker=true | `P1-6 Citation Verification Basic Plus`; P0 minimum in `P0-5B` |
| 30 | P1 | knowledge_reliability_eval_suite | core_only | false | true | core=not_started; ui=not_required; blackbox=not_required; artifact=not_required; event=not_required; governance=not_required; restart=not_required; close_allowed=false; release_blocker=true | `P1-7 Knowledge Reliability Eval Suite Basic` |
| 31 | P1 | retrieval_regression | core_only | false | true | core=not_started; ui=not_required; blackbox=not_required; artifact=not_required; event=not_required; governance=not_required; restart=not_required; close_allowed=false; release_blocker=true | `P1-8 Retrieval Regression Basic` |
| 32 | P1 | scope_resolver_basic | core_only | false | true | core=not_started; ui=not_required; blackbox=not_required; artifact=not_required; event=not_required; governance=not_required; restart=not_required; close_allowed=false; release_blocker=true | `P1-9 Scope Resolver Basic` |
| 33 | P1 | rule_extraction_basic | core_only | false | true | core=not_started; ui=not_required; blackbox=not_required; artifact=not_required; event=not_required; governance=not_required; restart=not_required; close_allowed=false; release_blocker=true | `P1-10 Rule Extraction Basic` |
| 34 | P1 | classification_reasoning_basic | core_only | false | true | core=not_started; ui=not_required; blackbox=not_required; artifact=not_required; event=not_required; governance=not_required; restart=not_required; close_allowed=false; release_blocker=true | `P1-11 Classification Reasoning Basic` |
| 35 | P1 | conflict_exception_detection | core_only | false | true | core=not_started; ui=not_required; blackbox=not_required; artifact=not_required; event=not_required; governance=not_required; restart=not_required; close_allowed=false; release_blocker=true | `P1-12 Conflict and Exception Detection Basic` |
| 36 | P1 | ai_config_governance | core_only | true | true | core=passed; ui=not_required; blackbox=not_required; artifact=not_required; event=not_required; governance=not_required; restart=not_required; close_allowed=true; release_blocker=true | `P1-13 AI Config Governance Basic` |
| 37 | P1 | task_mode_router | core_only | false | true | core=not_started; ui=not_required; blackbox=not_required; artifact=not_required; event=not_required; governance=not_required; restart=not_required; close_allowed=false; release_blocker=true | `P1-14 Task Mode Router Basic` |
| 38 | P1 | plan_execute_runtime | core_only | false | true | core=not_started; ui=not_required; blackbox=not_required; artifact=not_required; event=not_required; governance=not_required; restart=not_required; close_allowed=false; release_blocker=true | `P1-15 Plan-and-Execute Runtime Basic` |
| 39 | P1 | long_document_strategy | core_only | false | true | core=not_started; ui=not_required; blackbox=not_required; artifact=not_required; event=not_required; governance=not_required; restart=not_required; close_allowed=false; release_blocker=true | `P1-16 Long Document Reading Strategy Basic` |
| 40 | P1 | external_skill_import | user_blackbox | false | true | core=not_started; ui=not_started; blackbox=not_started; artifact=not_required; event=not_required; governance=not_required; restart=not_required; close_allowed=false; release_blocker=true | `P1-17 External Skill Import Basic` |
| 41 | P1 | workbench_skill_action_spec | user_blackbox | false | true | core=not_started; ui=not_started; blackbox=not_started; artifact=not_required; event=not_required; governance=not_required; restart=not_required; close_allowed=false; release_blocker=true | `P1-18 Workbench Skill Action Spec` |
| 42 | P1 | document_template_registry | artifact | false | true | core=not_started; ui=not_required; blackbox=not_started; artifact=not_started; event=not_required; governance=not_required; restart=not_required; close_allowed=false; release_blocker=true | `P1-19 Document Template Registry` |
| 43 | P1 | office_artifact_adapter | artifact | false | true | core=not_started; ui=not_required; blackbox=not_started; artifact=not_started; event=not_required; governance=not_required; restart=not_required; close_allowed=false; release_blocker=true | `P1-20 Office Artifact Adapter Research / DOCX Basic` |
| 44 | P1 | assistant_backend_separation | user_blackbox | false | true | core=partial; ui=not_started; blackbox=not_started; artifact=not_required; event=not_required; governance=not_required; restart=not_required; close_allowed=false; release_blocker=true | `P1-21 Assistant Backend Separation` |
| 45 | P1 | ui_taste_gate | user_blackbox | false | true | core=not_started; ui=not_started; blackbox=not_started; artifact=not_required; event=not_required; governance=not_required; restart=not_required; close_allowed=false; release_blocker=true | `P1-22 UI Taste Gate` |
| 46 | P1 | full_route_responsive_review | user_blackbox | false | true | core=not_started; ui=not_started; blackbox=not_started; artifact=not_required; event=not_required; governance=not_required; restart=not_required; close_allowed=false; release_blocker=true | `P1-23 Full Route Responsive Review` |
| 47 | P1 | connection_configuration | user_blackbox | false | true | core=not_started; ui=not_started; blackbox=not_started; artifact=not_required; event=not_required; governance=not_required; restart=not_required; close_allowed=false; release_blocker=true | `P1-24 Connection Configuration Blackbox Verification` |
| 48 | P1 | hot_pluggable_project_config_basic | core_only | false | true | core=not_started; ui=not_required; blackbox=not_required; artifact=not_required; event=not_required; governance=not_required; restart=not_required; close_allowed=false; release_blocker=true | `P1-25 Hot-Pluggable Project Config Basic` |
| 49 | P1 | audit_report_enhancement | core_only | false | true | core=not_started; ui=not_required; blackbox=not_required; artifact=not_required; event=not_required; governance=not_required; restart=not_required; close_allowed=false; release_blocker=true | `P1-26 Audit Report Enhancement` |
| 50 | P1 | codex_execution_harness | core_only | false | true | core=not_started; ui=not_required; blackbox=not_required; artifact=not_required; event=not_required; governance=not_required; restart=not_required; close_allowed=false; release_blocker=true | `P1-27 Codex Execution Harness Enhancement` |
| 51 | P1 | workbench_agent_harness | core_only | false | true | core=not_started; ui=not_required; blackbox=not_required; artifact=not_required; event=not_required; governance=not_required; restart=not_required; close_allowed=false; release_blocker=true | `P1-28 Workbench Agent Execution Harness Basic` |
| 52 | P1 | policy_governance_basic | governance | false | true | core=not_started; ui=not_required; blackbox=not_required; artifact=not_required; event=not_required; governance=not_started; restart=partial; close_allowed=false; release_blocker=true | `P1-29 Policy Governance Basic` |
| 53 | P1 | credential_proxy_design | governance | false | true | core=not_started; ui=not_required; blackbox=not_required; artifact=not_required; event=not_required; governance=not_started; restart=partial; close_allowed=false; release_blocker=true | `P1-30 Credential Proxy Design` |
| 54 | P1 | harness_adapter_spec | governance | false | true | core=not_started; ui=not_required; blackbox=not_required; artifact=not_required; event=not_required; governance=not_started; restart=partial; close_allowed=false; release_blocker=true | `P1-31 Harness Adapter Spec` |
| 55 | P1 | model_pool_router_basic | core_only | false | true | core=not_started; ui=not_required; blackbox=not_required; artifact=not_required; event=not_required; governance=not_required; restart=not_required; close_allowed=false; release_blocker=true | `P1-32 Model Pool Router Basic` |
| 56 | P1 | role_protocol_basic | core_only | false | true | core=not_started; ui=not_required; blackbox=not_required; artifact=not_required; event=not_required; governance=not_required; restart=not_required; close_allowed=false; release_blocker=true | `P1-33 Thinker / Worker / Verifier Role Protocol` |
| 57 | P1 | loop_runtime | core_only | false | true | core=not_started; ui=not_required; blackbox=not_required; artifact=not_required; event=not_required; governance=not_required; restart=not_required; close_allowed=false; release_blocker=true | `P1-34 Loop Runtime Basic` |
| 58 | P1 | stop_handoff_gate | governance | false | true | core=not_started; ui=not_required; blackbox=not_required; artifact=not_required; event=not_required; governance=not_started; restart=partial; close_allowed=false; release_blocker=true | `P1-35 Stop and Handoff Gate` |
| 59 | P1 | loop_cost_boundary | governance | false | true | core=not_started; ui=not_required; blackbox=not_required; artifact=not_required; event=not_required; governance=not_started; restart=partial; close_allowed=false; release_blocker=true | `P1-36 Loop Cost Boundary Basic` |
| 60 | P1 | native_knowledge_format_semantic_schema | core_only | false | true | core=not_started; ui=not_required; blackbox=not_required; artifact=not_required; event=not_required; governance=not_required; restart=not_required; close_allowed=false; release_blocker=true | `P1-37 Heitang Native Knowledge Format Semantic Schema` |
| 61 | P1 | knowledge_canvas_basic | user_blackbox | false | true | core=not_started; ui=not_started; blackbox=not_started; artifact=not_required; event=not_required; governance=not_required; restart=not_required; close_allowed=false; release_blocker=true | `P1-38 Knowledge Canvas Basic` |
| 62 | P1 | knowledge_base_table_view | user_blackbox | false | true | core=not_started; ui=not_started; blackbox=not_started; artifact=not_required; event=not_required; governance=not_required; restart=not_required; close_allowed=false; release_blocker=true | `P1-39 Knowledge Base Table View` |
| 63 | P1 | clean_markdown_import | core_only | false | true | core=not_started; ui=not_required; blackbox=not_required; artifact=not_required; event=not_required; governance=not_required; restart=not_required; close_allowed=false; release_blocker=true | `P1-40 Clean Markdown Import` |
| 64 | P1 | engineering_learning_samples | core_only | false | true | core=not_started; ui=not_required; blackbox=not_required; artifact=not_required; event=not_required; governance=not_required; restart=not_required; close_allowed=false; release_blocker=true | `P1-41 Engineering Learning Samples Basic` |
| 65 | P1 | p1_release_gate | governance | false | true | core=not_started; ui=not_required; blackbox=not_required; artifact=not_required; event=not_required; governance=not_started; restart=not_started; close_allowed=false; release_blocker=true | P1 Release Gate |
| 66 | P2 | a2a_workgroup | user_blackbox | false | true | core=not_started; ui=not_started; blackbox=not_started; artifact=not_required; event=not_required; governance=not_required; restart=not_required; close_allowed=false; release_blocker=true | `P2-1 Workgroup Basic Runtime`; `P2-4 A2A >= 10 Agents` |
| 67 | P2 | office_collaboration_workgroup | user_blackbox | false | true | core=not_started; ui=not_started; blackbox=not_started; artifact=not_required; event=not_required; governance=not_required; restart=not_required; close_allowed=false; release_blocker=true | `P2-2 Office Collaboration Workgroup` |
| 68 | P2 | research_analysis_workgroup | user_blackbox | false | true | core=not_started; ui=not_started; blackbox=not_started; artifact=not_required; event=not_required; governance=not_required; restart=not_required; close_allowed=false; release_blocker=true | `P2-3 Research Analysis Workgroup` |
| 69 | P2 | multi_agent_rag_deepening | core_only | false | true | core=not_started; ui=not_required; blackbox=not_required; artifact=not_required; event=not_required; governance=not_required; restart=not_required; close_allowed=false; release_blocker=true | `P2-5 Multi-Agent RAG Deepening` |
| 70 | P2 | project_config_industrial_isolation | core_only | false | true | core=not_started; ui=not_required; blackbox=not_required; artifact=not_required; event=not_required; governance=not_required; restart=not_required; close_allowed=false; release_blocker=true | `P2-6 Hot-Pluggable Project Config Industrial Isolation` |
| 71 | P2 | connector_industrialization | core_only | false | true | core=not_started; ui=not_required; blackbox=not_required; artifact=not_required; event=not_required; governance=not_required; restart=not_required; close_allowed=false; release_blocker=true | `P2-7 Connector Industrialization`; ordinary UI external source verification connector binding |
| 72 | P2 | blackbox_automation_baseline | core_only | false | true | core=not_started; ui=not_required; blackbox=not_required; artifact=not_required; event=not_required; governance=not_required; restart=not_required; close_allowed=false; release_blocker=true | `P2-8 Blackbox Automation Baseline`; framework baseline only; final full matrix reruns at P2 Release Gate |
| 73 | P2 | windows_packaging_baseline_smoke | user_blackbox | false | true | core=not_started; ui=not_started; blackbox=not_started; artifact=not_required; event=not_required; governance=not_required; restart=not_started; close_allowed=false; release_blocker=true | `P2-9 Windows Packaging Baseline Smoke`; smoke baseline only; final packaging/install/config/permission/rollback reruns at P2 Release Gate |
| 74 | P2 | role_based_workgroup | user_blackbox | false | true | core=not_started; ui=not_started; blackbox=not_started; artifact=not_required; event=not_required; governance=not_required; restart=not_required; close_allowed=false; release_blocker=true | `P2-10 Role-based Workgroup` |
| 75 | P2 | react_tool_runtime_industrial | core_only | false | true | core=not_started; ui=not_required; blackbox=not_required; artifact=not_required; event=not_required; governance=not_required; restart=not_required; close_allowed=false; release_blocker=true | `P2-11 ReAct Tool Runtime Industrialization` |
| 76 | P2 | long_context_evaluation | core_only | false | true | core=not_started; ui=not_required; blackbox=not_required; artifact=not_required; event=not_required; governance=not_required; restart=not_required; close_allowed=false; release_blocker=true | `P2-12 Long Context Evaluation` |
| 77 | P2 | official_sample_project_library | artifact | false | true | core=not_started; ui=not_required; blackbox=not_started; artifact=not_started; event=not_required; governance=not_required; restart=not_required; close_allowed=false; release_blocker=true | `P2-13 Official Sample Project Library` |
| 78 | P2 | polly_style_lead_orchestrator | core_only | false | true | core=not_started; ui=not_required; blackbox=not_required; artifact=not_required; event=not_required; governance=not_required; restart=not_required; close_allowed=false; release_blocker=true | `P2-14 Polly-style Lead Orchestrator` |
| 79 | P2 | sandbox_tool_permission | governance | false | true | core=not_started; ui=not_required; blackbox=not_required; artifact=not_required; event=not_required; governance=not_started; restart=partial; close_allowed=false; release_blocker=true | `P2-15 Sandbox and Tool Permission Industrialization` |
| 80 | P2 | session_share_fork_replay | core_only | false | true | core=not_started; ui=not_required; blackbox=not_required; artifact=not_required; event=not_required; governance=not_required; restart=not_required; close_allowed=false; release_blocker=true | `P2-16 Session Share / Fork / Replay` |
| 81 | P2 | cloud_disposable_sandbox | core_only | false | true | core=not_started; ui=not_required; blackbox=not_required; artifact=not_required; event=not_required; governance=not_required; restart=not_required; close_allowed=false; release_blocker=true | `P2-17 Cloud Disposable Sandbox Evaluation` |
| 82 | P2 | fugu_multi_model_orchestration | core_only | false | true | core=not_started; ui=not_required; blackbox=not_required; artifact=not_required; event=not_required; governance=not_required; restart=not_required; close_allowed=false; release_blocker=true | `P2-18 Fugu-style Multi-Model Orchestration` |
| 83 | P2 | loop_orchestrator_industrial | core_only | false | true | core=not_started; ui=not_required; blackbox=not_required; artifact=not_required; event=not_required; governance=not_required; restart=not_required; close_allowed=false; release_blocker=true | `P2-19 Loop Orchestrator Industrial` |
| 84 | P2 | human_brake_judgment_gate | governance | false | true | core=not_started; ui=not_required; blackbox=not_required; artifact=not_required; event=not_required; governance=not_started; restart=partial; close_allowed=false; release_blocker=true | `P2-20 Human Brake and Judgment Gate` |
| 85 | P2 | dataagent_foundation_industrial | core_only | false | true | core=not_started; ui=not_required; blackbox=not_required; artifact=not_required; event=not_required; governance=not_required; restart=not_required; close_allowed=false; release_blocker=true | `P2-21 DataAgent Foundation Industrial` |
| 86 | P2 | native_skills_library | artifact | false | true | core=not_started; ui=not_required; blackbox=not_started; artifact=not_started; event=not_required; governance=not_required; restart=not_required; close_allowed=false; release_blocker=true | `P2-22 Workbench Native Skills Library` |
| 87 | P2 | cli_agent_hub_evaluation | core_only | false | true | core=not_started; ui=not_required; blackbox=not_required; artifact=not_required; event=not_required; governance=not_required; restart=not_required; close_allowed=false; release_blocker=true | `P2-23 CLI Agent Hub Evaluation` |
| 88 | P2 | remote_task_control | user_blackbox | false | true | core=not_started; ui=not_started; blackbox=not_started; artifact=not_required; event=not_required; governance=not_required; restart=not_required; close_allowed=false; release_blocker=true | `P2-24 Remote Task Control` |
| 89 | P2 | office_agent_industrialization | user_blackbox | false | true | core=not_started; ui=not_started; blackbox=not_started; artifact=not_required; event=not_required; governance=not_required; restart=not_required; close_allowed=false; release_blocker=true | `P2-25 Office Agent Industrialization` |
| 90 | P2 | multi_kb_governance_industrial | core_only | false | true | core=not_started; ui=not_required; blackbox=not_required; artifact=not_required; event=not_required; governance=not_required; restart=not_required; close_allowed=false; release_blocker=true | `P2-26 Multi-KB Governance Industrial` |
| 91 | P2 | versioned_knowledge_governance | core_only | false | true | core=not_started; ui=not_required; blackbox=not_required; artifact=not_required; event=not_required; governance=not_required; restart=not_required; close_allowed=false; release_blocker=true | `P2-27 Versioned Knowledge Governance` |
| 92 | P2 | jurisdiction_domain_scope | core_only | false | true | core=not_started; ui=not_required; blackbox=not_required; artifact=not_required; event=not_required; governance=not_required; restart=not_required; close_allowed=false; release_blocker=true | `P2-28 Jurisdiction / Domain Scope` |
| 93 | P2 | human_review_console | governance | false | true | core=not_started; ui=not_required; blackbox=not_required; artifact=not_required; event=not_required; governance=not_started; restart=partial; close_allowed=false; release_blocker=true | `P2-29 Human Review Console` |
| 94 | P2 | reliability_score_industrial | core_only | false | true | core=not_started; ui=not_required; blackbox=not_required; artifact=not_required; event=not_required; governance=not_required; restart=not_required; close_allowed=false; release_blocker=true | `P2-30 Reliability Score Industrial` |
| 95 | P2 | night_knowledge_maintenance | core_only | false | true | core=not_started; ui=not_required; blackbox=not_required; artifact=not_required; event=not_required; governance=not_required; restart=not_required; close_allowed=false; release_blocker=true | `P2-31 Night Knowledge Maintenance Loop` |
| 96 | P2 | citation_auto_repair | core_only | false | true | core=not_started; ui=not_required; blackbox=not_required; artifact=not_required; event=not_required; governance=not_required; restart=not_required; close_allowed=false; release_blocker=true | `P2-32 Citation Auto-Repair Industrial` |
| 97 | P2 | memory_consolidation_industrial | core_only | false | true | core=not_started; ui=not_required; blackbox=not_required; artifact=not_required; event=not_required; governance=not_required; restart=not_required; close_allowed=false; release_blocker=true | `P2-33 Memory Consolidation Industrial` |
| 98 | P2 | permission_scoped_company_brain | core_only | false | true | core=not_started; ui=not_required; blackbox=not_required; artifact=not_required; event=not_required; governance=not_required; restart=not_required; close_allowed=false; release_blocker=true | `P2-34 Permission-Scoped Company Brain` |
| 99 | P2 | retrieval_regression_benchmark_industrial | core_only | false | true | core=not_started; ui=not_required; blackbox=not_required; artifact=not_required; event=not_required; governance=not_required; restart=not_required; close_allowed=false; release_blocker=true | `P2-35 Retrieval Regression Benchmark Industrial`; external source verification reliability regression |
| 100 | P2 | self_improving_knowledge_maintenance | core_only | false | true | core=not_started; ui=not_required; blackbox=not_required; artifact=not_required; event=not_required; governance=not_required; restart=not_required; close_allowed=false; release_blocker=true | `P2-36 Self-Improving Knowledge Maintenance` |
| 101 | P2 | agent_memory_industrial | core_only | false | true | core=not_started; ui=not_required; blackbox=not_required; artifact=not_required; event=not_required; governance=not_required; restart=not_required; close_allowed=false; release_blocker=true | `P2-37 Agent Memory Industrial` |
| 102 | P2 | mermaid_symbolic_memory_industrial | core_only | false | true | core=not_started; ui=not_required; blackbox=not_required; artifact=not_required; event=not_required; governance=not_required; restart=not_required; close_allowed=false; release_blocker=true | `P2-38 Mermaid Symbolic Memory Industrial` |
| 103 | P2 | cross_agent_memory_migration | core_only | false | true | core=not_started; ui=not_required; blackbox=not_required; artifact=not_required; event=not_required; governance=not_required; restart=not_required; close_allowed=false; release_blocker=true | `P2-39 Cross-Agent Memory Migration` |
| 104 | P2 | night_memory_consolidation_loop | core_only | false | true | core=not_started; ui=not_required; blackbox=not_required; artifact=not_required; event=not_required; governance=not_required; restart=not_required; close_allowed=false; release_blocker=true | `P2-40 Night Memory Consolidation Loop` |
| 105 | P2 | memory_observability_panel | user_blackbox | false | true | core=not_started; ui=not_started; blackbox=not_started; artifact=not_required; event=not_required; governance=not_required; restart=not_required; close_allowed=false; release_blocker=true | `P2-41 Memory Observability Panel` |
| 106 | P2 | tencentdb_agent_memory_adapter_evaluation | governance | false | true | core=not_started; ui=not_required; blackbox=not_required; artifact=not_required; event=not_required; governance=not_started; restart=partial; close_allowed=false; release_blocker=true | `P2-42 TencentDB Agent Memory Adapter Evaluation / Optional Integration` |
| 107 | P2 | p2_release_gate | governance | false | true | core=not_started; ui=not_required; blackbox=not_required; artifact=not_required; event=not_required; governance=not_started; restart=not_started; close_allowed=false; release_blocker=true | P2 Release Gate; ordinary UI external source verification evidence |
| 108 | Release | final_owner_review_gate | governance | false | true | core=not_started; ui=not_required; blackbox=not_required; artifact=not_required; event=not_required; governance=not_started; restart=not_started; close_allowed=false; release_blocker=true | Final Owner Review |

## Phase Gates

- P0 Release Gate runs after all P0 rows are close_allowed=true and P0 regression passes.
- P1 Release Gate runs after all P1 rows are close_allowed=true and P0 regression passes.
- P2 Release Gate runs after all P2 rows are close_allowed=true and P0+P1+P2 final regression passes, including the final full blackbox matrix, final package/install/config/permission/rollback checks, and ordinary UI external source verification evidence with source trace, evidence map and validation report.
- Final Owner Review is the only final human stop after staged gates pass.
