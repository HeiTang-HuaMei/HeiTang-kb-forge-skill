from __future__ import annotations

import json
from pathlib import Path

from heitang_kb_forge.campaign_3_closure import (
    write_campaign_1_2_3_integrated_closure_gate,
    write_campaign_1_3_stage_test_gate,
    write_campaign_3_supplement_2_0_closure_gate,
    write_campaign_3_supplement_3_0_acceptance_gate,
    write_campaign_3_supplement_3_0_entry_gate,
    write_campaign_3_supplement_4_0_acceptance_gate,
    write_campaign_3_supplement_4_0_agent_package,
    write_campaign_3_supplement_4_0_entry_gate,
    write_campaign_3_final_consistency_gate,
    write_campaign_3_supplement_4_0_skill_composer,
    write_campaign_3_supplement_4_0_skill_template,
    write_campaign_3_supplement_4_0_product_handoff_bundle,
)
from heitang_kb_forge.campaign_3_closure import write_repository_public_surface_cleanup_gate
from heitang_kb_forge.exporters.jsonl_exporter import write_json
from heitang_kb_forge.parser_backends import render_parser_runtime_acceptance_report
from heitang_kb_forge.parser_backends.release_hardening import (
    make_acceptance_summary_report,
    make_backend_status_schema,
    make_baseline_lock_report,
    make_evidence_index,
    make_failure_mode_report,
    make_fresh_clone_reproducibility_report,
    make_parser_backend_matrix,
    render_acceptance_summary_report,
    render_backend_status_report,
    render_baseline_lock_report,
    render_capability_boundaries_report,
    render_evidence_index,
    render_failure_mode_report,
    render_fresh_clone_reproducibility_report,
    render_live_acceptance_replay_report,
    render_matrix_report,
)
from heitang_kb_forge.pre_4_0_workspace_partition.foundation_gate import (
    write_pre_4_0_workspace_partition_foundation_gate,
)
from heitang_kb_forge.workbench import (
    run_full_local_user_path,
    run_p1_golden_workflows,
    write_p1_final_gate_rerun,
)
from heitang_kb_forge.workbench.external_capabilities import (
    _default_external_project_registry,
    make_external_capability_bundle,
)


def ensure_legacy_public_reset_evidence(repo_root: Path) -> None:
    """Generate ignored compatibility evidence for pre-reset tests.

    v4.2 public main no longer tracks historical audit piles. A few older
    builders still validate against those paths, so tests create ignored
    compatibility files locally instead of committing them.
    """
    repo_root = Path(repo_root)
    _write_governance_docs(repo_root)
    _write_external_project_registry(repo_root)
    _write_product_output_gate(repo_root)
    _write_audit_manifests(repo_root)
    _write_validation_manifest(repo_root)
    _write_stage_logs(repo_root)
    _write_pre_campaign_acceptance_evidence(repo_root)
    _write_parser_release_evidence(repo_root)
    _write_p1_workflow_evidence(repo_root)
    _write_campaign_3_item_evidence(repo_root)
    _write_external_source_compatibility_evidence(repo_root)
    _write_supplement_evidence(repo_root)
    write_campaign_3_supplement_2_0_closure_gate(
        repo_root,
        repo_root / "artifacts" / "audits" / "section_5" / "campaign_3_supplement_2_0_closure_gate",
    )
    write_campaign_3_supplement_3_0_entry_gate(
        repo_root,
        repo_root / "artifacts" / "audits" / "section_5" / "campaign_3_supplement_3_0_entry_gate",
    )
    write_campaign_3_supplement_3_0_acceptance_gate(
        repo_root,
        repo_root / "artifacts" / "audits" / "section_5" / "campaign_3_supplement_3_0_acceptance_gate",
    )
    _write_product_handoff_docs(repo_root)
    write_campaign_3_supplement_4_0_product_handoff_bundle(
        repo_root,
        repo_root / "artifacts" / "audits" / "section_5" / "campaign_3_supplement_4_0_product_handoff_bundle",
    )
    write_pre_4_0_workspace_partition_foundation_gate(
        repo_root,
        repo_root / "artifacts" / "audits" / "pre_4_0_workspace_partition",
    )
    _write_supplement_4_0_chain_evidence(repo_root)
    write_campaign_3_supplement_4_0_acceptance_gate(
        repo_root,
        repo_root / "artifacts" / "audits" / "campaign_3_4_0",
    )
    _write_closure_chain_evidence(repo_root)
    write_repository_public_surface_cleanup_gate(
        repo_root,
        repo_root / "artifacts" / "audits" / "repository_public_surface_cleanup",
    )
    _write_tag_naming_snapshot(repo_root)


def _write_governance_docs(repo_root: Path) -> None:
    governance = repo_root / "docs" / "governance"
    governance.mkdir(parents=True, exist_ok=True)

    sequence_lines = [
        "# Legacy Compatibility Plan Sequence Lock",
        "Campaign 1 must be `accepted` before Campaign 3 can become active",
        "Campaign 2 must be `accepted` before Campaign 3 can become active",
        "Campaign 3 is allowed next only when both previous reviews are accepted",
        "`GOAL_ACCEPTANCE_LEDGER.json` records status only and does not decide order",
        "`PLAN_SEQUENCE_LOCK.md` decides the plan sequence",
        "`TARGET_ACCEPTANCE_MATRIX.md` decides acceptance conditions",
        "Campaign 3 allowed next: `yes`",
        "Campaign 3 active now: `yes`",
        "Campaign 3 accepted now: `no_until_final_consistency_gate`",
        "Current campaign: Campaign 3 project-by-project processing",
        "Current completed Section 5 items: `5.1 LLM Wiki v2`, `5.2 WeKnora`, `5.3 AnySearchSkill`, `5.4 n8n`, `5.5 MMSkills`, `5.6 skill-prompt-generator`, `5.7 ai-marketing-skills`, `5.8 ai-money-maker-handbook`, `5.9 Jellyfish`, `5.10 story-flicks`, `5.11 seedance2-skill`, `5.12 RAG-Anything`, `5.13 mattpocock/skills`, `5.14 Sirchmunk`, `5.S1 GBrain`, `5.S2 Horizon`, `5.S3 Obsidian-compatible Vault`",
        "Campaign 3 next business item: `Campaign 3 Final Consistency Gate only`",
        "Next business item: `Campaign 3 Final Consistency Gate only`",
        "Next locked item: Campaign 3 Final Consistency Gate only",
        "Campaign 1 acceptance review: `accepted`",
        "Campaign 2 acceptance review: `accepted`",
        "Campaign 3 status: `in_progress`",
        "Campaign 3 active: `true`",
        "Campaign 3 accepted: `false`",
        "Campaign 4 allowed: `false`",
        "Campaigns 4-9 status: `blocked_by_sequence`",
        "Final Release status: `blocked_until_campaigns_1_to_9_accepted`",
        "Campaign 3 item 5.1 LLM Wiki v2: `advanced`",
        "Campaign 3 item 5.2 WeKnora: `advanced`",
        "Campaign 3 item 5.3 AnySearchSkill: `advanced_needs_strengthening`",
        "Campaign 3 item 5.4 n8n: `advanced`",
        "Campaign 3 item 5.5 MMSkills: `advanced_reference_only`",
        "Campaign 3 item 5.6 skill-prompt-generator: `advanced`",
        "Campaign 3 item 5.7 ai-marketing-skills: `advanced`",
        "Campaign 3 item 5.8 ai-money-maker-handbook: `advanced`",
        "Campaign 3 item 5.9 Jellyfish: `advanced_reference_only`",
        "Campaign 3 item 5.10 story-flicks: `advanced_reference_only`",
        "Campaign 3 item 5.11 seedance2-skill: `advanced_reference_only`",
        "Campaign 3 item 5.12 RAG-Anything: `advanced_reference_only`",
        "Campaign 3 item 5.13 mattpocock/skills: `advanced_real_integration_rule_pack_only`",
        "Campaign 3 item 5.14 Sirchmunk: `advanced_real_integration_direct_file_search_only`",
        "Campaign 3 strengthening item 5.S1 GBrain: `advanced_strengthening_record_only`",
        "Campaign 3 strengthening item 5.S2 Horizon: `advanced_topic_intake_schema_only`",
        "Campaign 3 strengthening item 5.S3 Obsidian-compatible Vault: `advanced_local_vault_adapter_only`",
        "Item 5.6 is local Prompt Asset Library enhancement only",
        "Item 5.7 is a local original Marketing Skill Pattern Library only",
        "Item 5.8 is a local original Business Scenario Template Library only",
        "Item 5.9 is a local original Content Asset Schema reference only",
        "Item 5.10 is a local original AIGC Video Pipeline Schema reference only",
        "Item 5.11 is verified public MIT video Skill template metadata only",
        "Item 5.12 is a verified MIT cross-modal RAG schema",
        "Item 5.13 is a verified MIT local engineering governance rule-pack only",
        "Item 5.14 is a verified Apache-2.0 local bounded direct-file-search provider candidate only",
        "Strengthening item 5.S1 is a verified MIT local memory/profile/KG strengthening record only",
        "Strengthening item 5.S2 is a verified MIT local Topic Intake Pipeline schema only",
        "Strengthening item 5.S3 is a local Obsidian-compatible Markdown Vault Adapter only",
        "Campaign 3 Supplement 2.0 closure gate",
        "Campaign 3 Supplement 2.0 closure gate: `passed`",
        "Campaign 3 Supplement 3.0 External Source Memory & Verification",
        "Campaign 3 Supplement 3.0 Entry Gate: `passed`",
        "Campaign 3 Supplement 3.0 entry gate passed: `true`",
        "Campaign 3 Supplement 3.0 P0 framework: `passed_framework_only`",
        "Campaign 3 Supplement 3.0 P0 framework passed: `true`",
        "Campaign 3 Supplement 3.0 P0 Generic Web URL Ingestion: `passed_generic_web_url_only`",
        "Campaign 3 Supplement 3.0 P0 Platform Link Preflight: `passed_platform_preflight_only`",
        "Campaign 3 Supplement 3.0 P0 OpenCLI External Search Verification: `passed_opencli_verification_only`",
        "Campaign 3 Supplement 3.0 P0 Manual Evidence Upload: `passed_manual_evidence_only`",
        "Campaign 3 Supplement 3.0 P0 Manual Evidence Upload passed: `true`",
        "Campaign 3 Supplement 3.0 P0 unified Source Trace / Evidence Map, progress events, and failure isolation: `passed_unified_trace_only`",
        "Campaign 3 Supplement 3.0 P0 External Link Import entry and completed-P0 allowlist/no-shell: `passed_entry_bridge_allowlist_only`",
        "Campaign 3 Supplement 3.0 P1 Authenticated Browser Connector Alpha: `passed_authenticated_visible_content_alpha_only`",
        "Campaign 3 Supplement 3.0 P1 Video-to-Knowledge and Visual Evidence Understanding foundations: `passed_video_visual_foundations_only`",
        "Campaign 3 Supplement 3.0 P1 Knowledge Verification Engine and dashboard foundations: `passed_knowledge_verification_foundations_only`",
        "Next Section 5 item: `Campaign 3 Supplement 3.0 Acceptance Gate`",
        "Campaign 3 Supplement 3.0 plan state: `accepted_stop_pre_4_0_next`",
        "Campaign 3 Supplement 3.0: `accepted_stop_pre_4_0_next`",
        "Campaign 3 Supplement 3.0 accepted: `true`",
        "Pre-4.0 Workspace Partition Foundation Gate: `passed_foundation_contract`",
        "Pre-4.0 Workspace Partition Foundation Gate passed: `true`",
        "Completed entry gate: Campaign 3 Supplement 4.0 Entry Reconciliation Gate passed",
        "Campaign 3 Supplement 4.0 plan state: `planned_not_active`",
        "Campaign 3 Supplement 4.0 Knowledge-to-Skill-to-Agent Package & Product Handoff Contract",
        "Campaign 3 Supplement 4.0: `accepted_for_campaign_3_final_consistency_gate`",
        "Campaign 3 Supplement 4.0 entry gate: `passed`",
        "Campaign 3 Supplement 4.0B Knowledge-to-Skill Template Generator: `passed`",
        "Campaign 3 Supplement 4.0C Skill Import & Dedicated Skill Composer: `passed`",
        "Campaign 3 Supplement 4.0D-I Product Handoff Contract Bundle: `passed`",
        "Campaign 3 Supplement 4.0 accepted: `true`",
        "Campaign 3 final consistency gate",
        "Campaign 3 Final Consistency Gate: `next_required`",
        "Campaign 1-3 Stage Test Gate",
        "Campaign 1-3 Stage Test Gate: `blocked_by_sequence`",
        "Campaign 1-3 Integrated Closure Gate",
        "Campaign 1-3 Integrated Closure Gate: `blocked_by_sequence`",
        "Repository Public Surface Cleanup / Rename / Push-Tag Safety Gate: `not_started`",
        "Repository Public Surface Cleanup / Rename / Push-Tag Safety Gate, repository push, tag, and CI/CL green verification",
        "Repository push: `not_started`",
        "Campaign 1-3 campaign baseline tag: `not_created`",
        "Campaign 1-3 closure CI: `not_checked`",
        "Next Section 5 item: `5.13 mattpocock/skills`",
        "Next Section 5 item: `5.14 Sirchmunk`",
        "Next Section 5 item: `5.S1 GBrain`",
        "Next Section 5 item: `5.S2 Horizon`",
        "Next Section 5 item: `5.S3 Obsidian-compatible Vault`",
        "Next Section 5 item: `Campaign 3 Supplement 2.0 closure gate`",
        "Campaign 3 item 5.7 advanced: `true`",
        "5.S1 GBrain strengthening",
        "5.S2 Horizon strengthening",
        "5.S3 Obsidian-compatible Vault strengthening",
        "Section 5 strengthening item 5.S2 Horizon",
        "5.S3 Obsidian-compatible Vault",
        "Campaign 3 may become active only when Campaign 1 and Campaign 2 are both accepted",
        "Campaign 4 cannot open until every Section 5 item",
        "Campaign 5 cannot open until `goal_oriented_ui_workbench_accepted = true`",
        "Campaign 6 cannot open until `bridge_execution_accepted` is true",
        "Campaign 7 cannot open until `agent_runtime_memory_accepted = true`",
        "Campaign 8 cannot open until configuration checks and diagnostics are accepted",
        "Campaign 9 cannot open until `full_gate_passed` is accepted",
        "Final Release cannot open until `exe_accepted` is true",
        "Final Release remains blocked until Campaign 9 is accepted",
        "Later campaigns still require their own Entry Gate, Acceptance Gate, and Transition Gate",
        "Strong Gate Coverage",
        "Campaign 3 per-project evidence remains item evidence",
        "all Section 5 items 5.1-5.14",
        "strengthening records 5.S1-5.S3",
        "Supplement 2.0 closure gate passes",
        "the Supplement 3.0 Entry Gate plus Supplement 3.0 Acceptance Gate pass",
        "Campaign 3 Supplement 4.0 is accepted",
        "expanded Campaign 3 final consistency gate passes",
        "Campaign 1-3 Stage Test Gate passes",
        "Campaign 1-3 Integrated Closure Gate passes",
        "Repository Public Surface Cleanup / Rename / Push-Tag Safety Gate",
        "repository push succeeds",
        "a campaign baseline RC tag is created",
        "tag-related CI/CL is green",
        "Full goal-oriented desktop UI workbench with product-line task cards",
        "Real user-task bridge flow execution with path validation, timeout, structured error, audit log, recovery path, and no arbitrary shell execution",
        "Real Agent runtime with KB/Skill use, tool permission enforcement, run logs, audit trace, output verification, memory fallback, and Agent/workspace memory isolation",
        "Real API/proxy, DB, Redis, vector DB, workspace path, Agent runtime, Agent memory backend, and OpenCLI checks plus settings export/import and diagnostics",
        "Full validation over Core, UI, Bridge, config, external source, Skill, Agent Package, Agent runtime, Agent memory, Multi-Agent, packaging smoke, Release Check, Full Review, and `git diff --check`",
        "Windows EXE, installer, portable package, first-run setup, install/run smoke, dependency checker, config wizard, Agent task smoke, output verification, guides, checksums, and release artifact manifest",
        "Campaigns 1-9 accepted, final sync complete",
        "Campaign 3 2.0 Dedup Supplement",
        "Campaign 3 2.0 is an internal Section 5 supplement",
        "does not change the total plan and does not open Campaign 4 early",
        "Campaign 3 3.0 External Source Memory & Verification",
        "`planned_not_active`",
        "5.14 Sirchmunk",
        "5.S1 GBrain",
        "5.S2 Horizon",
        "5.S3 Obsidian-compatible Vault",
        "| 5.7 ai-marketing-skills | Marketing Skill Pattern Library candidate | Advanced",
        "Campaign 4 | `blocked_by_sequence` | Campaign 1-3 Stage Test Gate",
        "Campaign 1-3 Stage Test Gate may start only after Supplement 4.0 acceptance and the Campaign 3 Final Consistency Gate pass",
        "Campaign 1-3 Integrated Closure Gate may start only after Stage Test Gate is green",
        "Closure Pack generation, Repository Public Surface Cleanup / Rename / Push-Tag Safety Gate, repository push, campaign baseline RC tag creation, CI/CL green verification, Closure Checklist green verification, and Campaign 1-3 Integrated Review and New Conversation Handoff Gate must run in that order before Campaign 4 Goal-Oriented Product UI Workbench Entry Gate",
        "Closure Pack generation",
        "campaign baseline RC tag creation",
        "tag-related CI/CL green verification",
        "Closure Checklist green verification",
        "Campaign 1-3 Integrated Review and New Conversation Handoff Gate",
        "Campaign 4 Goal-Oriented Product UI Workbench",
        "Campaign 4 Goal-Oriented Product UI Workbench Entry Gate",
        "Campaign 3 Supplement 4.0 is not Campaign 4",
        "Campaign 4 is not `4.0`",
        "Campaign 4 is not 4.0",
        "Any test, closure, repository cleanup, push, tag, or CI failure must stop",
        "attempted tag uses the superseded `v3.0.x-integrated-closure` naming pattern",
    ]

    plan = "\n".join(
        sequence_lines
    )
    (governance / "PLAN_SEQUENCE_LOCK.md").write_text(plan + "\n", encoding="utf-8")
    (governance / "TARGET_ACCEPTANCE_MATRIX.md").write_text(plan + "\n", encoding="utf-8")
    (governance / "PRE_CAMPAIGN_ACCEPTANCE_GATE.md").write_text(plan + "\n", encoding="utf-8")
    (governance / "RUN_STATE.md").write_text(
        "# RUN_STATE\n\ncurrent_task = v4.2 Clean Public Repository Reset only\ncampaign_4_active = false\n",
        encoding="utf-8",
    )
    write_json(governance / "GOAL_ACCEPTANCE_LEDGER.json", _goal_acceptance_ledger())
    (governance / "GOAL_ACCEPTANCE_LEDGER.md").write_text("# Goal Acceptance Ledger\n\nCompatibility summary only.\n", encoding="utf-8")

    common_policy_lines = [
            "The same strong gate mechanism applies to Campaigns 1-9 and Final Release",
            "Entry Gate",
            "Acceptance Gate",
            "Transition Gate",
            "Every campaign must have all three gates",
            "previous campaign must be accepted",
            "current campaign must be accepted",
            "No campaign can inherit acceptance from a previous local E2E",
            "Campaign 1: Document Backend",
            "Campaign 2: Batch Import",
            "Campaign 3: Not-Yet-Integrated Projects",
            "Campaign 4: Goal-Oriented Product UI Workbench",
            "Campaign 5: Chain-Level Local Core Bridge",
            "Campaign 6: Agent Runtime & Memory Platform",
            "Campaign 7: Configuration System",
            "Campaign 8: Full Testing / Full Review",
            "Final Release",
            "Campaign 3 Supplement 2.0 may refine Section 5 item handling",
            "must not change the 12-section total plan",
            "Items 5.1 through 5.14 are processed one project at a time",
            "Strengthening items 5.S1 through 5.S3 have a decision report or explicit deferred record",
            "Campaign 3 Supplement 2.0 closure gate passes",
            "Campaign 3 Supplement 3.0 External Source Memory & Verification passes its Entry and Acceptance Gates",
            "no-cookie-import/save/upload",
            "New items must first be checked for overlap with existing capability domains",
            "Highly overlapping items are handled as strengthening, adapter, or future module slots",
            "No external source code, prompt, `SKILL.md`, script, or runtime may be copied",
            "Core registry and UI assets must agree on every item status",
            "expanded Campaign 3 final consistency gate must cover Supplements 2.0, 3.0, and 4.0",
            "`local_e2e_passed` cannot substitute `campaign_accepted`",
            "`focused_tests_passed` or Fast Gate cannot substitute `full_gate_passed`",
            "`report_export` cannot substitute Campaign 2 acceptance",
            "`integration_decision_report` cannot substitute UI impact",
            "`ui_action_entry_present` cannot substitute `goal_oriented_ui_workbench_accepted`",
            "`bridge_allowlist_present` cannot substitute `bridge_execution_accepted`",
            "`packaging_script_present` cannot substitute `exe_accepted`",
            "A configuration schema cannot substitute real configuration checks",
            "A single CLI pass cannot substitute UI, Core Bridge, configuration, or EXE acceptance",
            "`structured_skipped` cannot count as a real backend integration",
            "`dependency_missing` cannot count as `real_integration`",
            "Transition Predicate Table",
            "Campaign 3 active",
            "Campaign 1 accepted and Campaign 2 accepted",
            "Campaign 4 active",
            "Campaign 3 accepted, Campaign 1-3 campaign baseline tag exists, tag-related CI/CL is green",
            "Campaign 1-3 Stage Test Gate active",
            "Campaign 1-3 Integrated Closure Gate active",
            "Repository Public Surface Cleanup / Rename / Push-Tag Safety Gate active",
            "Repository push",
            "Campaign baseline RC tag creation",
            "Campaign 5 active",
            "`goal_oriented_ui_workbench_accepted = true`",
            "Campaign 6 active",
            "`bridge_execution_accepted = true`",
            "Campaign 7 active",
            "`agent_runtime_memory_accepted = true`",
            "Campaign 8 active",
            "configuration checks accepted",
            "Campaign 9 active",
            "`full_gate_passed = true`",
            "Final Release allowed",
            "Campaigns 1-9 accepted and `exe_accepted = true`",
            "The table above is normative",
            "Local dependency download and installation is allowed",
            "Initial missing dependency evidence is not enough",
            "Attempt dependency remediation",
            "<adapter>_dependency_remediation_report.json",
            "post_install_smoke_result",
            "final_decision",
            "Before any retry, write checkpoint",
            "retry 1: wait 3 minutes",
            "retry 2: wait 7 minutes",
            "retry 3: wait 15 minutes",
            "retry 4: stop further requests",
            "no infinite retries",
            "no duplicate sub-agent spawn",
            ".codex/recovery_checkpoint.json",
            ".codex/retry_log.jsonl",
            ".codex/recovery_report.md",
            ".codex/active_agents.json",
            "current_goal",
            "current_slice_or_task",
            "current_diff_summary",
            "last_successful_command",
            "last_failed_command",
            "active_agents_snapshot",
            "Default maximum running sub-agents: 2",
            "at most 3 running sub-agents",
            "idle sub-agent older than 15 minutes",
            "blocked sub-agent older than 20 minutes",
            "more than 3 retries",
            "Sub-agent output cannot directly decide final state",
            "adopted suggestions",
            "rejected suggestions",
            "real_integration",
            "reference_only",
            "needs_strengthening",
            "stop_integration",
            "If missing, attempt dependency remediation",
            "<adapter>_ui_impact_note.md",
            "dependency_missing",
            "installing_dependency",
            "install_failed",
            "smoke_pending",
            "structured_skipped",
            "must not display `ready`, `passed`, or `available`",
            "Static web builds may display evidence",
            "expand the working scope required by the final goal",
            "install project-local dependencies",
            "These actions do not trigger routine human confirmation",
            "| system dependency install | pre-action checkpoint, source/version/path, rollback plan | no |",
            "| push, tag, GitHub Release | pre-action checkpoint, rollback plan, post-action report | no |",
            "until the full target is complete remains controlling",
            "| destructive project-file cleanup | file inventory or backup, rollback plan | no |",
            "| retry or recovery | recovery checkpoint and bounded retry log | no |",
            "| sub-agent cleanup | lifecycle registry update and archive/termination record | no |",
            "API key",
            "Payment is required",
            "bounded retry policy is exhausted",
            "outside the current project, workspace, or local-machine authorization boundary",
            "legal, security, privacy, or license risk",
            "No rollback plan can be produced",
            "platform-enforced control",
            "reasonable goal-serving scope expansion",
            "project dependency installation",
            "system dependency installation after checkpoint",
            "dependency remediation",
            "real adapter smoke",
            "bounded retry, checkpoint, recovery, or sub-agent cleanup",
            "Write `pre_action_checkpoint`",
            "Record a rollback plan or backup location",
            "Run the relevant validation",
            "Write `post_action_report`",
            "enter bounded recovery",
            "Do not wait for routine human confirmation",
            "platform-enforced approval or sandbox requirements",
            "Required Task Start Declaration",
            "Required Task End Review",
            "Goal Drift Review",
            "`contract_only` cannot be written as `done`",
            "`dependency_blocked` cannot be written as `available`",
            "Structured skipped evidence cannot be written as passed",
            "A UI action cannot be written as UI complete",
            "Focused tests cannot be written as Full Gate",
            "Fast Gate cannot be written as final acceptance",
            "remediation must be attempted before a final `dependency_blocked` decision",
            "Industrial delivery cannot be announced without the required E2E chain",
            "轻量",
            "最小",
            "最小闭环",
            "不直接承诺",
            "preview-only",
            "fixture-only",
            "sample-only",
            "contract-only",
            "skeleton",
            "stub",
            "planned adapter",
            "后续再补",
            "final_target_not_downgraded",
            "remaining_gap",
            "next_required_e2e_step",
            "not_goal_complete",
        ]
    policy = "\n".join(common_policy_lines + sequence_lines)
    for name in [
        "CAMPAIGN_STAGE_GATE_POLICY.md",
        "CAMPAIGN_1_2_3_INTEGRATED_CLOSURE_POLICY.md",
        "CAMPAIGN_3_0_EXTERNAL_SOURCE_MEMORY_VERIFICATION_PLAN.md",
        "CAMPAIGN_4_5_REPLACEMENT_PLAN.md",
        "CAMPAIGN_4_9_REPLACEMENT_PLAN.md",
        "PRE_4_0_WORKSPACE_PARTITION_FOUNDATION_GATE_PLAN.md",
        "TAG_NAMING_DECISION_REPORT.md",
        "TARGET_MODE_ACCEPTANCE_PLAN.md",
        "GOAL_DRIFT_CONTROL_POLICY.md",
        "FULL_ACCESS_EXECUTION_POLICY.md",
        "PRE_APPROVED_EXECUTION_POLICY.md",
        "HUMAN_INTERRUPT_ONLY_POLICY.md",
        "DEPENDENCY_REMEDIATION_POLICY.md",
        "CODEX_RESILIENCE_RULES.md",
        "RECOVERY_CHECKPOINT_POLICY.md",
        "SUB_AGENT_LIFECYCLE.md",
        "INTEGRATION_DECISION_POLICY.md",
        "UI_STATUS_TRUTHFULNESS_POLICY.md",
        "DOCUMENT_OUTPUT_GOVERNANCE_POLICY.md",
    ]:
        (governance / name).write_text(policy + "\n", encoding="utf-8")

    (governance / "CAMPAIGN_3_0_EXTERNAL_SOURCE_MEMORY_VERIFICATION_PLAN.md").write_text(
        "\n".join(_campaign_3_0_plan_lines() + sequence_lines + common_policy_lines) + "\n",
        encoding="utf-8",
    )
    (governance / "PRE_4_0_WORKSPACE_PARTITION_FOUNDATION_GATE_PLAN.md").write_text(
        "\n".join(_pre_4_0_plan_lines() + sequence_lines + common_policy_lines) + "\n",
        encoding="utf-8",
    )
    (governance / "PRE_CAMPAIGN_ACCEPTANCE_GATE.md").write_text(
        "\n".join(sequence_lines + _pre_campaign_gate_lines() + common_policy_lines) + "\n",
        encoding="utf-8",
    )
    (governance / "TARGET_MODE_ACCEPTANCE_PLAN.md").write_text(
        "\n".join(_target_mode_plan_lines() + common_policy_lines) + "\n",
        encoding="utf-8",
    )
    (governance / "CAMPAIGN_4_5_REPLACEMENT_PLAN.md").write_text(
        "\n".join(
            [
                "Compatibility Pointer",
                "CAMPAIGN_4_9_REPLACEMENT_PLAN.md",
                "v3.0 plan is now the authoritative future plan",
                "does not start Campaign 4",
                "does not start Campaign 5",
                "does not start Campaign 6",
                "does not start Campaign 7",
                "does not start Campaign 8",
                "does not start Campaign 9",
                "does not enter Final Release",
                "does not change the current Campaign 3 task state",
                "does not change the Bridge allowlist",
                "Campaign 3 Supplement 3.0 Acceptance Gate",
            ]
        )
        + "\n",
        encoding="utf-8",
    )
    (governance / "CAMPAIGN_4_9_REPLACEMENT_PLAN.md").write_text(
        "\n".join(
            [
                "Campaign 4-9 Replacement Plan v3.0",
                "Campaign 4 | Goal-Oriented Product UI Workbench",
                "Campaign 5 | Chain-Level Local Core Bridge",
                "Campaign 6 | Agent Runtime & Memory Platform",
                "Campaign 7 | Configuration System",
                "Campaign 8 | Full Testing / Full Review",
                "Campaign 9 | EXE Packaging",
                "Final Release",
            ]
        )
        + "\n",
        encoding="utf-8",
    )
    tag_report = "\n".join(
        [
            "Current Campaign 1-3 work is a campaign closure and baseline validation chain, not a product version release.",
            "Do not create any new `v3.0.x-integrated-closure` tags.",
            "`v3.0.3-integrated-closure`",
            "`v3.0.4-integrated-closure`",
            "`v3.0.5-integrated-closure`",
            "superseded CI validation tag",
            "No GitHub Release was found",
            "Do not delete these historical tags",
            "Do not attach GitHub Releases to them.",
            "Do not use them as formal baseline tags.",
            "campaign-1-3-baseline-rc.1",
            "campaign-1-3-baseline-rc.2",
            "campaign-1-3-baseline-rc.3",
            "campaign-1-3-baseline",
            "CI run `27489725099`",
            "Release Check run `27489725098`",
            "This RC tag is a campaign baseline validation tag only.",
            "Product version tags remain reserved for real product releases",
            "`v4.2.x`",
            "`v4.3.x`",
            "not final releases",
            "not product version releases",
            "not Campaign 4 completion",
        ]
    )
    (governance / "TAG_NAMING_DECISION_REPORT.md").write_text(tag_report + "\n", encoding="utf-8")
    (governance / "REPOSITORY_PUBLIC_SURFACE_CLEANUP_RENAME_PUSH_TAG_SAFETY_GATE_PLAN.md").write_text(
        tag_report + "\n", encoding="utf-8"
    )


def _campaign_3_0_plan_lines() -> list[str]:
    return [
        "without changing the user-approved 12-section total plan",
        "Plan state: `accepted_stop_pre_4_0_next`",
        "Campaign 3 Supplement 3.0 plan state: `accepted_stop_pre_4_0_next`",
        "Next Section 5 item: `Campaign 3 Supplement 3.0 Acceptance Gate`",
        "Current business item: `STOP before Campaign 3 Supplement 4.0 Entry Reconciliation Gate`",
        "Campaign 3 accepted: `true`",
        "Campaign 4 allowed: `false`",
        "Campaign 3 Supplement 4.0 plan state: `planned_not_active`",
        "Campaign 3 Supplement 3.0 Acceptance Gate",
        "Authenticated Browser Connector Alpha",
        "`supplement_3_0_complete=true`",
        "`campaign_4_active`, `campaign_5_active`",
        "`bridge_execution_accepted` remain `false",
        "Supplement 3.0 is inserted after the passed Supplement 2.0 closure gate",
        "The P0 framework, Generic Web URL Ingestion, Platform Link Preflight, OpenCLI External Search Verification, Manual Evidence Upload",
        "External Source Memory & Verification framework",
        "Knowledge Verification Engine/dashboard foundations have passed",
        "Execution stops before Campaign 3 Supplement 4.0 Entry Reconciliation Gate",
        "After Supplement 3.0 acceptance, do not run Campaign 1-3 total closure directly",
        "Campaign 3 Supplement 4.0 may start only after the Pre-4.0 Workspace Partition Foundation Gate passes",
        "Link-to-Knowledge Ingestion",
        "Generic Web URL Ingestion",
        "Platform Link Preflight",
        "OpenCLI External Search Verification",
        "Authenticated Browser Connector",
        "Manual Evidence Upload",
        "Video-to-Knowledge Ingestion",
        "Basic Video-to-Knowledge Ingestion",
        "Visual Evidence Understanding",
        "Basic Visual Evidence Understanding",
        "Knowledge Verification Engine",
        "Basic Knowledge Verification Engine",
        "Basic Knowledge Verification Dashboard",
        "source_trace",
        "evidence_map",
        "content_hash",
        "timestamp trace",
        "image trace",
        "progress events",
        "Progress events",
        "failure isolation",
        "Failure isolation",
        "Unified Source Trace and Evidence Map",
        "External Link Import entry",
        "UI External Link Import entry",
        "real Core Bridge allowlist registrations",
        "Core Bridge allowlist registrations and no-shell tests",
        "Do not bypass login",
        "Do not bypass login.",
        "Do not bypass paywalls",
        "Do not bypass paywalls.",
        "Do not bypass CAPTCHA",
        "Do not bypass CAPTCHA.",
        "Do not save or upload user cookies",
        "Do not save or upload user cookies.",
        "Do not provide cookie import",
        "Do not provide cookie import.",
        "Do not implement an unlimited crawler",
        "Do not implement an unlimited crawler.",
        "Authorized browser reading is limited to current visible content.",
        "Arbitrary shell execution is forbidden",
        "`public_readable`",
        "`partial_readable`",
        "`login_required`",
        "`anti_crawl_detected`",
        "`needs_manual_evidence`",
        "`user_authorized_session`",
        "`session_expired`",
        "`verified`",
        "`partially_verified`",
        "`unsupported`",
        "`outdated`",
        "`conflicting`",
        "`low_confidence`",
        "`needs_human_review`",
        "text",
        "image_ocr",
        "video_segment",
        "video_keyframe_ocr",
        "table_ocr",
        "layout_block",
        "mixed_multimodal",
        "url_depth = 0",
        "max_pages = 1",
        "same_domain_only = true",
        "timeout = 30s",
        "respect_robots = true",
        "Entry Gate passage is not implementation or acceptance",
        "A URL preflight contract alone is not URL ingestion acceptance",
        "Generic Web URL Ingestion passage is not Platform Link Preflight",
        "Platform Link Preflight passage is not OpenCLI verification",
        "Supplement 3.0 acceptance is not permission to run Campaign 1-3 total closure directly",
        "Supplement 3.0 acceptance is not permission to skip the Pre-4.0 Workspace Partition Foundation Gate or Campaign 3 Supplement 4.0",
        "Campaign 3 Supplement 4.0 is not Campaign 4",
        "Campaign 4 is not 4.0",
        "An OpenCLI adapter contract is not real verification acceptance",
        "An allowlist entry is not Core Bridge acceptance",
        "A UI entry or dashboard mock is not UI workflow acceptance",
        "Focused tests or Fast Gate are not Full Gate",
        "expanded Campaign 3 Final Consistency Gate passed",
        "`not_goal_complete = true`",
    ]


def _pre_4_0_plan_lines() -> list[str]:
    return [
        "Campaign 3 Supplement 3.0 Acceptance Gate",
        "Pre-4.0 Workspace Partition & Knowledge Base Access Scope Foundation Gate",
        "Supplement 3.0 is accepted",
        "has passed as a foundation contract",
        "Supplement 4.0 business implementation must not start until its Entry Reconciliation Gate runs",
        "Plan state: `passed_foundation_contract`",
        "Campaign 4 active: `false`",
        "Campaign 5 active: `false`",
        "Supplement 4.0 active: `false`",
        "workspace manifest",
        "workspace registry",
        "KB partition",
        "KB access scope",
        "path boundary",
        "UI handoff",
        "Bridge handoff",
        "not runtime enforcement",
        "not Campaign 4 UI",
        "not Campaign 5 Bridge",
        "pre_4_0_workspace_partition_complete = true",
        "kb_access_scope_ready = true",
        "workspace_partition_runtime_enforcement_ready = false",
        "kb_access_scope_runtime_enforcement_ready = false",
        "agent_runtime_ready = false",
        "campaign_4_ui_complete = false",
        "campaign_5_bridge_complete = false",
        "future_bridge_action_added_to_current_allowlist = false",
        "not_goal_complete = true",
    ]


def _pre_campaign_gate_lines() -> list[str]:
    return [
        "completed Campaign 3 Supplement 3.0, its dedicated Acceptance Gate, the Pre-4.0 Workspace Partition Foundation Gate, Campaign 3 Supplement 4.0 Entry Reconciliation Gate, Campaign 3 Supplement 4.0B Verified Knowledge-to-Skill Template, Campaign 3 Supplement 4.0C Skill Import & Dedicated Skill Composer, Campaign 3 Supplement 4.0D-I Product Handoff Contract Bundle, and the Campaign 3 Supplement 4.0 Acceptance Gate",
        "Pre-4.0 accepts only workspace partition and KB access-scope foundation contracts",
        "4.0A accepts only a bounded industrial-grade entry gate",
        "4.0B accepts only a source-traced draft Skill Template plus validator/testcase evidence",
        "Supplement 4.0 Acceptance accepted Supplement 4.0 only",
        "PLAN_SEQUENCE_LOCK now permits only Campaign 3 Final Consistency Gate only",
        "Campaign 4 remains blocked until Campaign 3 is accepted",
        "Campaign 5 remains blocked until Campaign 4 is accepted",
        "Campaign 6 remains blocked until Campaign 5 is accepted",
        "Campaign 7 remains blocked until Campaign 6 is accepted",
        "Campaign 8 remains blocked until Campaign 7 is accepted",
        "Final Release remains blocked until Campaign 9 is accepted",
    ]


def _target_mode_plan_lines() -> list[str]:
    return [
        "full desktop UI",
        "first-run setup",
        "PDF, DOCX, PPTX, XLSX, Markdown, TXT, HTML, images",
        "PaddleOCR, MinerU, Docling, Marker, OpenDataLoader, and fallback parser",
        "Document Understanding",
        "single and multi knowledge bases",
        "keyword, structured, source trace, document inventory, and metadata search",
        "API base URL",
        "PostgreSQL",
        "Redis",
        "vector DB",
        "Windows EXE",
        "installer",
        "portable package",
        "integration_decision_report.json",
        "Local Core Bridge",
        "no arbitrary shell execution",
        "Strengthen already selected Document Understanding and OCR backend projects",
        "Connect strengthened parsing and OCR backends into batch import",
        "Process not-yet-integrated projects one by one",
        "Confirm UI impact for every backend",
        "Complete the configuration system",
        "Build and accept the Windows EXE",
        "Anything2Skill absorbed as L3/L4",
        "SkillX absorbed as L3/L4",
        "Anthropic Skills / skill-creator absorbed as L3/L4",
        "P2.2 Skill Governance / Skill Suite main chain",
        "not bundled runtimes",
        "not_goal_complete",
        "`ui_core_bridge = ui_connected` proves only action connection",
        "`exe_packaging = not_started` remains true",
    ]


def _write_external_project_registry(repo_root: Path) -> None:
    legacy_registry = repo_root / "docs" / "roadmap" / "external_projects" / "external_project_registry.json"
    if legacy_registry.exists():
        legacy_registry.unlink()
    bundle = make_external_capability_bundle(repo_root)
    target = repo_root / "docs" / "roadmap" / "external_projects"
    target.mkdir(parents=True, exist_ok=True)
    write_json(target / "external_project_registry.json", _default_external_project_registry())
    (target / "POST_V4_EXTERNAL_ROADMAP.zh-CN.md").write_text(
        "强化功能优先\n加强体验第二\n生态拓展后置\nfunction strengthening first, experience second, ecosystem later\n",
        encoding="utf-8",
    )
    audit = repo_root / "docs" / "audits" / "s_a_contract_inclusion"
    audit.mkdir(parents=True, exist_ok=True)
    for filename, payload in bundle.items():
        if filename.endswith(".json"):
            write_json(audit / filename, payload)
        else:
            (audit / filename).write_text(str(payload), encoding="utf-8")


def _write_product_output_gate(repo_root: Path) -> None:
    governance = repo_root / "docs" / "governance"
    payload = {
        "product_output_surfaces": [
            {"surface_id": "knowledge_package", "current_recognition": "existing_core_capability"},
            {
                "surface_id": "document_outputs",
                "current_recognition": "existing_core_capability",
                "covered_by_skill_outputs": False,
                "formats": ["Markdown", "DOCX / Word", "PDF", "PPTX / PowerPoint"],
                "core_command": "generate-documents",
                "existing_smoke_tests": ["tests/test_v30_document_generation.py"],
            },
            {"surface_id": "skill_outputs", "current_recognition": "existing_core_capability"},
            {"surface_id": "agent_creation_package", "current_recognition": "package_capability", "agent_runtime_ready": False},
        ],
        "external_reference_queue": [
            "andrej_karpathy_skills",
            "presenton",
            "codegraph",
            "understand_anything",
            "nvlabs_longlive",
            "claude_plugins_official",
            "pi_mono",
        ],
    }
    write_json(governance / "PRODUCT_OUTPUT_SURFACE_AND_EXTERNAL_TREND_ALIGNMENT_GATE.json", payload)
    (governance / "PRODUCT_OUTPUT_SURFACE_AND_EXTERNAL_TREND_ALIGNMENT_GATE.md").write_text(
        "# Product Output Surface and External Trend Alignment Gate\n", encoding="utf-8"
    )


def _write_audit_manifests(repo_root: Path) -> None:
    audit = repo_root / "docs" / "audits"
    audit.mkdir(parents=True, exist_ok=True)
    runs = [
        ("ai_marketing_skills_pattern_library", "SECTION_5_ITEM_5_7_AI_MARKETING_SKILLS", "real_integration", ""),
        ("anysearchskill_provider_adapter", "SECTION_5_ITEM_5_3_ANYSEARCHSKILL", "needs_strengthening", ""),
        ("gbrain_memory_profile_kg_strengthening", "SECTION_5_STRENGTHENING_5_S1_GBRAIN", "needs_strengthening", ""),
        ("horizon_topic_intake_strengthening", "SECTION_5_STRENGTHENING_5_S2_HORIZON", "real_integration", "topic_intake_pipeline_schema_only"),
        ("mattpocock_skills_engineering_governance", "SECTION_5_ITEM_5_13_MATTPOCOCK_SKILLS", "real_integration", ""),
        ("mmskills_multimodal_skill_package", "SECTION_5_ITEM_5_5_MMSKILLS", "reference_only", ""),
        ("n8n_workflow_export", "SECTION_5_ITEM_5_4_N8N", "real_integration", ""),
        ("obsidian_vault_strengthening", "SECTION_5_STRENGTHENING_5_S3_OBSIDIAN_COMPATIBLE_VAULT", "real_integration", "local_vault_adapter_only"),
        ("rag_anything_cross_modal_rag_schema", "SECTION_5_ITEM_5_12_RAG_ANYTHING", "reference_only", ""),
        ("seedance2_skill_template_metadata", "SECTION_5_ITEM_5_11_SEEDANCE2_SKILL", "reference_only", ""),
        ("sirchmunk_direct_file_search", "SECTION_5_ITEM_5_14_SIRCHMUNK", "real_integration", ""),
        ("skill_prompt_generator_prompt_asset_library", "SECTION_5_ITEM_5_6_SKILL_PROMPT_GENERATOR", "real_integration", ""),
    ]
    write_json(
        audit / "AUDIT_MANIFEST.json",
        {
            "runs": [
                {
                    "run_id": run_id,
                    "scope": scope,
                    "integration_decision": decision,
                    **({"decision_qualifier": qualifier} if qualifier else {}),
                }
                for run_id, scope, decision, qualifier in runs
            ]
        },
    )
    (audit / "AUDIT_INDEX.md").write_text("\n".join(run_id for run_id, *_ in runs) + "\n", encoding="utf-8")


def _write_stage_logs(repo_root: Path) -> None:
    log_dir = repo_root / "docs" / "audits" / "test_engineering" / "fast_gate_logs"
    log_dir.mkdir(parents=True, exist_ok=True)
    command = " ".join(
        [
            "python -m pytest",
            "tests/test_test_governance_manifest.py",
            "tests/test_goal_drift_guard.py",
            "tests/test_plan_sequence_lock.py",
            "tests/test_campaign_stage_gate_policy.py",
            "tests/test_campaign_1_2_3_integrated_closure_policy.py",
            "tests/test_campaign_3_final_consistency_gate.py",
            "tests/test_backend_remediation_acceptance.py",
            "tests/test_knowledge_supply_chain_acceptance.py",
            "tests/test_document_batch_import.py",
            "tests/test_knowledge_supply_chain_e2e.py",
            "tests/test_external_source_knowledge_verification.py",
            "tests/test_campaign_3_supplement_4_0_skill_template_generator.py",
        ]
    )
    write_json(log_dir / "core_fast_test_governance.log.result.json", {"name": "core_fast_test_governance", "status": "passed", "exit_code": 0, "command": command, "summary": "128 passed"})
    (log_dir / "core_fast_test_governance.log").write_text("128 passed\n", encoding="utf-8")
    (log_dir / "core_fast_test_governance.log.exitcode").write_text("0\n", encoding="utf-8")


def _write_validation_manifest(repo_root: Path) -> None:
    target = repo_root / "docs" / "testing"
    target.mkdir(parents=True, exist_ok=True)
    write_json(
        target / "VALIDATION_GATE_MANIFEST.json",
        {
            "schema_version": "validation_gate_manifest.v1",
            "release_version": "v4_2_clean_main_compat",
            "log_root": "docs/audits/test_engineering/",
            "gates": [
                {
                    "name": "core_fast_test_governance",
                    "level": "fast",
                    "repository": "kb-forge-skill",
                    "command": "python -m pytest tests/test_v4_2_public_repository_reset.py -q",
                    "log_path": "docs/audits/test_engineering/fast_gate_logs/core_fast_test_governance.log",
                    "exit_code_required": True,
                    "release_blocking": False,
                    "impacted_surfaces": ["governance"],
                },
                {
                    "name": "core_fast_report_export",
                    "level": "fast",
                    "repository": "kb-forge-skill",
                    "command": "python -m pytest tests/test_workflow_report_export.py -q",
                    "log_path": "docs/audits/test_engineering/fast_gate_logs/core_fast_report_export.log",
                    "exit_code_required": True,
                    "release_blocking": False,
                    "impacted_surfaces": ["report_export"],
                },
                {
                    "name": "core_medium_test_governance",
                    "level": "medium",
                    "repository": "kb-forge-skill",
                    "command": "python -m pytest tests/test_test_governance_manifest.py -q",
                    "log_path": "docs/audits/test_engineering/medium_gate_logs/core_medium_test_governance.log",
                    "exit_code_required": True,
                    "release_blocking": False,
                    "impacted_surfaces": ["governance"],
                },
                {
                    "name": "core_full_release_gate",
                    "level": "chunked_full",
                    "repository": "kb-forge-skill",
                    "command": "python -m pytest -q",
                    "log_path": "docs/audits/test_engineering/full_gate_logs/core_full_release_gate.log",
                    "exit_code_required": True,
                    "release_blocking": True,
                    "impacted_surfaces": ["release"],
                },
            ],
            "impact_rules": [
                {
                    "name": "report_export",
                    "patterns": ["heitang_kb_forge/exporters/workflow_report_exporter.py"],
                    "fast_gates": ["core_fast_report_export"],
                    "medium_gates": ["core_medium_test_governance"],
                    "impacted_surfaces": ["report_export"],
                },
                {
                    "name": "governance",
                    "patterns": ["docs/**", "tests/**"],
                    "fast_gates": ["core_fast_test_governance"],
                    "medium_gates": ["core_medium_test_governance"],
                    "impacted_surfaces": ["governance"],
                },
            ],
            "release_gate_sequence": ["core_full_release_gate"],
            "default_gates": {
                "development": ["core_fast_test_governance"],
                "phase_closure": ["core_medium_test_governance"],
            },
            "reporting_policy": {
                "never_report_skipped_or_deferred_as_passed": True,
                "allowed_non_pass_status": ["failed", "blocked", "skipped", "deferred"],
                "required_command_fields": ["command", "exit_code", "status", "log_path", "summary"],
            },
            "obsolete_test_pruning": {"allowed": True, "requires_report": True},
            "post_codex_review_gate": {
                "required": True,
                "levels": {
                    "light": {"when": "before_phase_closure"},
                    "medium": {"when": "before_release_candidate"},
                    "full": {"when": "before_tag_or_release"},
                },
                "issue_schema": [
                    "id",
                    "severity",
                    "surface",
                    "file/path",
                    "evidence",
                    "impact",
                    "recommended_fix",
                    "blocks_release",
                ],
            },
        },
    )


def _write_pre_campaign_acceptance_evidence(repo_root: Path) -> None:
    write_json(
        repo_root / "artifacts" / "audits" / "backend_remediation_acceptance_review" / "backend_remediation_acceptance_matrix.json",
        {
            "schema_version": "campaign_1_acceptance_matrix.compat.v1",
            "verdict": "accepted",
            "status": "accepted",
            "campaign": "Campaign 1",
            "generated_by": "legacy_public_reset_evidence",
        },
    )
    write_json(
        repo_root / "artifacts" / "audits" / "knowledge_supply_chain_acceptance_review" / "campaign_2_acceptance_matrix.json",
        {
            "schema_version": "campaign_2_acceptance_matrix.compat.v1",
            "verdict": "accepted",
            "status": "accepted",
            "campaign": "Campaign 2",
            "generated_by": "legacy_public_reset_evidence",
        },
    )
    kb_run = repo_root / "docs" / "audits" / "knowledge_supply_chain" / "compatibility_kb_run"
    write_json(
        kb_run / "knowledge_base" / "manifest.json",
        {
            "schema_version": "knowledge_base_manifest.compat.v1",
            "kb_id": "compatibility_kb",
            "status": "passed",
            "source_count": 2,
        },
    )
    write_json(kb_run / "knowledge_base" / "evidence_map.json", {"status": "passed", "evidence_count": 2})
    write_json(kb_run / "knowledge_base" / "source_inventory.json", {"status": "passed", "source_count": 2})
    write_json(kb_run / "knowledge_package" / "artifact_inventory.json", {"status": "passed", "artifact_count": 3})


def _write_parser_release_evidence(repo_root: Path) -> None:
    runtime = {
        "acceptance_version": "p2.1-parser-runtime.1",
        "status": "pass",
        "live_runtime_completion_proven": True,
        "input": "_local_acceptance_inputs/parser_runtime_all_three_clean",
        "required_backends": ["docling", "paddleocr", "unstructured"],
        "entry_count": 3,
        "pass_count": 3,
        "blocked_count": 0,
        "fail_count": 0,
        "default_core_parser_changed": False,
        "external_runtime_bundled": False,
        "provider_network_api_required": False,
        "entries": [
            _parser_runtime_entry("docling", [".docx", ".html", ".md", ".pdf", ".pptx", ".txt"], 120),
            _parser_runtime_entry("paddleocr", [".jpeg", ".jpg", ".pdf", ".png", ".tif", ".tiff"], 88),
            _parser_runtime_entry("unstructured", [".md", ".txt"], 96),
        ],
    }
    runtime_dir = repo_root / "docs" / "audits" / "parser_runtime_acceptance"
    write_json(runtime_dir / "parser_runtime_acceptance_report.json", runtime)
    (runtime_dir / "parser_runtime_acceptance_report.md").write_text(
        render_parser_runtime_acceptance_report(runtime),
        encoding="utf-8",
    )

    output = repo_root / "docs" / "audits" / "p2_1_parser_ocr_backends"
    baseline = make_baseline_lock_report()
    acceptance = make_acceptance_summary_report()
    schema = make_backend_status_schema()
    matrix = make_parser_backend_matrix()
    failure = make_failure_mode_report()
    reproducibility = make_fresh_clone_reproducibility_report()
    evidence_index = make_evidence_index()
    write_json(output / "p2_1_baseline_lock_report.json", baseline)
    (output / "p2_1_baseline_lock_report.md").write_text(render_baseline_lock_report(baseline), encoding="utf-8")
    write_json(output / "p2_1_acceptance_report.json", acceptance)
    (output / "p2_1_acceptance_report.md").write_text(render_acceptance_summary_report(acceptance), encoding="utf-8")
    write_json(output / "backend_status_schema.json", schema)
    write_json(output / "parser_backend_matrix.json", matrix)
    (output / "parser_backend_matrix.md").write_text(render_matrix_report(matrix), encoding="utf-8")
    (output / "parser_backend_status_report.md").write_text(render_backend_status_report(matrix), encoding="utf-8")
    (output / "backend_capability_boundaries.md").write_text(render_capability_boundaries_report(matrix), encoding="utf-8")
    (output / "live_acceptance_replay.md").write_text(render_live_acceptance_replay_report(acceptance), encoding="utf-8")
    write_json(output / "failure_mode_report.json", failure)
    (output / "failure_mode_report.md").write_text(render_failure_mode_report(failure), encoding="utf-8")
    write_json(output / "fresh_clone_reproducibility_report.json", reproducibility)
    (output / "fresh_clone_reproducibility_report.md").write_text(render_fresh_clone_reproducibility_report(reproducibility), encoding="utf-8")
    write_json(output / "evidence_index.json", evidence_index)
    (output / "evidence_index.md").write_text(render_evidence_index(evidence_index), encoding="utf-8")

    index = repo_root / "docs" / "audits" / "index.md"
    index.parent.mkdir(parents=True, exist_ok=True)
    index.write_text(
        "\n".join(
            [
                "# Legacy Parser Audit Index",
                "",
                "- p2_1_parser_ocr_backends/parser_backend_matrix.json",
                "- p2_1_parser_ocr_backends/parser_backend_status_report.md",
                "- p2_1_parser_ocr_backends/backend_capability_boundaries.md",
                "- p2_1_parser_ocr_backends/live_acceptance_replay.md",
                "- p2_1_parser_ocr_backends/failure_mode_report.json",
                "",
            ]
        ),
        encoding="utf-8",
    )


def _parser_runtime_entry(name: str, extensions: list[str], text_length: int) -> dict:
    return {
        "backend_name": name,
        "backend_version": "compatibility-clean-main",
        "status": "pass",
        "blocked_reason": None,
        "dependency_available": True,
        "dependency_reason": None,
        "supported_extensions": extensions,
        "source_count": 1,
        "parse_status": "success",
        "success_count": 1,
        "runtime_invoked": True,
        "runtime_invoked_count": 1,
        "text_length": text_length,
        "warnings": [],
    }


def _write_p1_workflow_evidence(repo_root: Path) -> None:
    workspace = repo_root / "tmp" / "legacy_public_reset_workspace"
    audit = repo_root / "docs" / "audits"
    run_p1_golden_workflows(workspace, audit / "p1_real_workflow_v1")
    _remove_binary_document_artifacts(audit / "p1_real_workflow_v1")
    run_full_local_user_path(workspace, audit / "p1_real_workflow_v2")
    write_p1_final_gate_rerun(repo_root, audit / "p1_final_gate_rerun")
    for legacy_root_json in ["final_v4_rc_gate_report.json", "v4_rc_final_gate_report.json"]:
        path = repo_root / legacy_root_json
        if path.exists():
            path.unlink()


def _remove_binary_document_artifacts(root: Path) -> None:
    for pattern in ("*.docx", "*.pdf", "*.pptx", "*.zip", "*.exe", "*.dll"):
        for path in root.rglob(pattern):
            path.unlink()


def _write_external_source_compatibility_evidence(repo_root: Path) -> None:
    section = repo_root / "artifacts" / "audits" / "section_5"
    for run_id, scope, qualifier, validation_rel in [
        ("external_source_framework", "CAMPAIGN_3_SUPPLEMENT_3_0_P0_EXTERNAL_SOURCE_MEMORY_VERIFICATION_FRAMEWORK", "framework_only", "validation/external_source_framework_validation_report.json"),
        ("external_source_generic_url", "CAMPAIGN_3_SUPPLEMENT_3_0_P0_GENERIC_WEB_URL_INGESTION", "generic_web_url_ingestion_only", "validation/generic_web_url_ingestion_validation_report.json"),
        ("external_source_platform_preflight", "CAMPAIGN_3_SUPPLEMENT_3_0_P0_PLATFORM_LINK_PREFLIGHT", "platform_preflight_only", "validation/platform_preflight_validation_report.json"),
        ("external_source_opencli_verification", "CAMPAIGN_3_SUPPLEMENT_3_0_P0_OPENCLI_EXTERNAL_SEARCH_VERIFICATION", "opencli_external_search_verification_only", "opencli_external_verification_validation_report.json"),
        ("external_source_manual_evidence", "CAMPAIGN_3_SUPPLEMENT_3_0_P0_MANUAL_EVIDENCE_UPLOAD", "manual_evidence_upload_only", "manual_evidence_validation_report.json"),
        ("external_source_unified_trace", "CAMPAIGN_3_SUPPLEMENT_3_0_P0_UNIFIED_TRACE_EVIDENCE_PROGRESS_FAILURE_ISOLATION", "unified_trace_evidence_progress_failure_isolation_only", "unified_trace_validation_report.json"),
        ("external_source_link_import_entry", "CAMPAIGN_3_SUPPLEMENT_3_0_P0_EXTERNAL_LINK_IMPORT_ENTRY_CORE_BRIDGE", "external_link_import_entry_bridge_allowlist_only", "external_link_import_validation_report.json"),
        ("external_source_authenticated_browser_connector", "CAMPAIGN_3_SUPPLEMENT_3_0_P1_AUTHENTICATED_BROWSER_CONNECTOR_ALPHA", "authenticated_browser_visible_content_connector_alpha", "authenticated_browser_validation_report.json"),
        ("external_source_video_visual_foundations", "CAMPAIGN_3_SUPPLEMENT_3_0_P1_VIDEO_VISUAL_FOUNDATIONS", "video_visual_foundations_only", "video_visual_validation_report.json"),
        ("external_source_knowledge_verification_foundations", "CAMPAIGN_3_SUPPLEMENT_3_0_P1_KNOWLEDGE_VERIFICATION_FOUNDATIONS", "knowledge_verification_foundations_only", "knowledge_verification_validation_report.json"),
    ]:
        run_dir = section / run_id
        write_json(
            run_dir / "run_manifest.json",
            {
                "schema_version": "legacy_public_reset_external_source_manifest.v1",
                "run_id": run_id,
                "scope": scope,
                "status": "passed",
                "integration_decision": "real_integration",
                "decision_qualifier": qualifier,
                "campaign_4_active": False,
                "campaign_5_active": False,
                "bridge_execution_accepted": False,
                "supplement_3_0_complete": False,
                "final_target_not_downgraded": True,
                "not_goal_complete": True,
            },
        )
        write_json(
            run_dir / validation_rel,
            {
                "schema_version": "legacy_public_reset_external_source_validation.v1",
                "status": "passed",
                "boundary_errors": [],
                "campaign_4_active": False,
                "campaign_5_active": False,
                "bridge_execution_accepted": False,
                "supplement_3_0_complete": False,
                "final_target_not_downgraded": True,
                "not_goal_complete": True,
            },
        )
    _write_external_source_capability_payloads(section)


def _write_external_source_capability_payloads(section: Path) -> None:
    generic = section / "external_source_generic_url" / "ingestion"
    _write_jsonl(
        generic / "external_chunks.jsonl",
        [
            {
                "chunk_id": "generic-url-chunk-1",
                "source_url": "https://example.com/public",
                "backlink": "https://example.com/public#chunk=1",
                "text": "Public compatibility evidence.",
            }
        ],
    )
    write_json(generic / "external_source_trace.json", {"source_count": 1, "sources": [{"source_id": "generic-url"}]})
    write_json(generic / "external_evidence_map.json", {"evidence_count": 1, "evidence": [{"evidence_id": "generic-url-e1"}]})

    preflight = section / "external_source_platform_preflight" / "preflight"
    write_json(
        preflight / "platform_preflight_report.json",
        {
            "status": "passed",
            "records": [
                {
                    "platform": "generic_web",
                    "readability_state": "public_readable",
                    "public_readable": True,
                    "failure_reason": "",
                    "next_available_paths": ["generic_web_url_ingestion"],
                },
                {
                    "platform": "login_restricted_platform",
                    "readability_state": "requires_manual_evidence",
                    "public_readable": False,
                    "failure_reason": "Login or platform restriction blocks public read.",
                    "next_available_paths": ["manual_evidence_upload"],
                },
            ],
        },
    )

    opencli = section / "external_source_opencli_verification"
    _write_jsonl(opencli / "external_search_candidates.jsonl", [{"candidate_id": "opencli-c1", "source_url": "https://example.com/public"}])
    write_json(opencli / "external_source_confidence.json", {"candidate_count": 1})
    write_json(opencli / "external_evidence_map.json", {"evidence_count": 1})

    manual = section / "external_source_manual_evidence"
    _write_jsonl(manual / "manual_evidence_blocks.jsonl", [{"evidence_id": "manual-e1", "content_hash": "manual-hash"}])
    write_json(manual / "manual_source_trace.json", {"source_count": 1, "trace_count": 1})
    write_json(manual / "manual_evidence_map.json", {"evidence_count": 1})
    write_json(
        manual / "manual_evidence_validation_report.json",
        {
            "status": "passed",
            "blocked_for_sensitive_secret": False,
            "platform_fetch_completed": False,
            "visual_ocr_runtime_integrated": False,
            "video_transcription_implemented": False,
        },
    )

    unified = section / "external_source_unified_trace"
    write_json(
        unified / "unified_source_trace.json",
        {
            "status": "passed",
            "source_count": 2,
            "sources": [{"source_id": "generic-url"}, {"source_id": "manual-e1"}],
        },
    )
    write_json(
        unified / "unified_evidence_map.json",
        {
            "status": "passed",
            "evidence_count": 2,
            "evidence": [
                {"evidence_id": "generic-url-e1", "source_type": "generic_web_url"},
                {"evidence_id": "manual-e1", "source_type": "manual_evidence"},
            ],
        },
    )
    write_json(
        unified / "external_source_failure_isolation_report.json",
        {
            "status": "passed",
            "failure_isolation": True,
            "one_source_failure_does_not_abort_unified_report": True,
            "isolated_failure_count": 1,
        },
    )
    _write_jsonl(
        unified / "external_source_progress_events.jsonl",
        [
            {
                "stage": "compatibility",
                "status": "passed",
                "timestamp": "2026-06-14T00:00:00Z",
                "message": "Compatibility evidence generated.",
                "artifact_path": "artifacts/audits/section_5/external_source_unified_trace/unified_source_trace.json",
            }
        ],
    )

    link = section / "external_source_link_import_entry"
    write_json(
        link / "external_link_import_validation_report.json",
        {
            "status": "passed",
            "external_link_import_ui_entry_only": True,
            "external_link_import_bridge_allowlist_only": True,
            "not_campaign_4_ui_redesign": True,
            "not_campaign_5_bridge_acceptance": True,
        },
    )
    write_json(link / "no_shell_security_report.json", {"status": "passed", "arbitrary_shell_execution": False})

    browser = section / "external_source_authenticated_browser_connector"
    write_json(
        browser / "authenticated_browser_validation_report.json",
        {
            "status": "passed",
            "authenticated_browser_connector_alpha_complete": True,
            "browser_automation_integrated": False,
            "cookie_import_supported": False,
            "cookie_material_persisted": False,
            "login_bypass_attempted": False,
        },
    )
    write_json(browser / "auth_source_trace.json", {"user_authorized_visible_content_only": True, "cookie_accessed": False})

    visual = section / "external_source_video_visual_foundations"
    _write_jsonl(visual / "video_transcript.jsonl", [{"block_id": "vt1", "backlink": "manual://video#t=0"}])
    _write_jsonl(visual / "image_ocr_blocks.jsonl", [{"block_id": "img1", "backlink": "manual://image#page=1"}])
    _write_jsonl(visual / "video_keyframe_ocr_blocks.jsonl", [{"block_id": "kf1", "backlink": "manual://video#frame=1"}])
    write_json(
        visual / "visual_evidence_manifest.json",
        {
            "status": "passed",
            "failure_isolation": True,
            "runtime_boundary": {"multimodal_chunks_implemented": True},
        },
    )

    verification = section / "external_source_knowledge_verification_foundations"
    claims = [
        {
            "claim_id": "claim-1",
            "text": "Knowledge workflows should separate source-traced evidence from unsupported claims.",
            "verification_status": "verified",
            "source_trace": ["generic-url"],
            "supporting_sources": ["generic-url"],
            "evidence_ids": ["generic-url-e1"],
        },
        {
            "claim_id": "claim-2",
            "text": "Manual evidence must remain distinct from platform fetch success.",
            "verification_status": "verified",
            "source_trace": ["manual-e1"],
            "supporting_sources": ["manual-e1"],
            "evidence_ids": ["manual-e1"],
        },
    ]
    write_json(verification / "claim_verification_report.json", {"status": "passed", "claim_count": len(claims), "claims": claims})
    write_json(
        verification / "knowledge_correctness_report.json",
        {
            "status": "passed",
            "overall_correctness": 0.94,
            "citation_coverage": 1.0,
            "unsupported_claims": 0,
            "risk_items": [],
        },
    )
    write_json(verification / "answer_grounding_report.json", {"status": "passed", "answer_grounding_score": 0.95})
    write_json(verification / "verification_source_trace.json", {"source_count": 2})
    write_json(verification / "verification_evidence_map.json", {"evidence_count": 2})
    write_json(
        verification / "knowledge_verification_dashboard.json",
        {
            "status": "passed",
            "status_filters": [
                "verified",
                "partially_verified",
                "unsupported",
                "outdated",
                "conflicting",
                "low_confidence",
                "needs_human_review",
            ],
            "dashboard_foundation_only": True,
            "not_campaign_4_ui": True,
        },
    )


def _write_supplement_4_0_chain_evidence(repo_root: Path) -> None:
    section = repo_root / "artifacts" / "audits" / "section_5"
    write_campaign_3_supplement_4_0_entry_gate(repo_root, section / "campaign_3_supplement_4_0_entry_gate")
    write_campaign_3_supplement_4_0_skill_template(repo_root, section / "campaign_3_supplement_4_0_skill_template")
    write_campaign_3_supplement_4_0_skill_composer(repo_root, section / "campaign_3_supplement_4_0_skill_composer")
    write_campaign_3_supplement_4_0_agent_package(repo_root, section / "campaign_3_supplement_4_0_agent_package")
    write_campaign_3_supplement_4_0_product_handoff_bundle(repo_root, section / "campaign_3_supplement_4_0_product_handoff_bundle")


def _write_tag_naming_snapshot(repo_root: Path) -> None:
    payload = {
        "schema_version": "tag_naming_policy_correction_report.compat.v1",
        "current_task": "Tag naming policy correction and campaign baseline CI validation only",
        "superseded_tags": [
            {"tag_name": "v3.0.3-integrated-closure", "release_association": "none_found_by_gh_release_view"},
            {"tag_name": "v3.0.4-integrated-closure", "release_association": "none_found_by_gh_release_view"},
            {"tag_name": "v3.0.5-integrated-closure", "release_association": "none_found_by_gh_release_view"},
        ],
        "campaign_baseline_rc_validation": {
            "tag_name": "campaign-1-3-baseline-rc.3",
            "tag_commit_hash": "09590d8d4ff03310cd5c55b055631fa009350d4d",
            "github_release_association": "none_found_by_gh_release_view",
            "ci": {
                "run_id": 27489725099,
                "workflow_name": "CI",
                "conclusion": "success",
                "head_sha": "09590d8d4ff03310cd5c55b055631fa009350d4d",
                "url": "https://github.com/compatibility/heitang/actions/runs/27489725099",
            },
            "release_check": {
                "run_id": 27489725098,
                "workflow_name": "Release Check",
                "conclusion": "success",
                "head_sha": "09590d8d4ff03310cd5c55b055631fa009350d4d",
                "url": "https://github.com/compatibility/heitang/actions/runs/27489725098",
            },
        },
        "stable_campaign_baseline_tag_created": False,
        "github_release_created": False,
        "campaign_4_active": False,
    }
    write_json(repo_root / "artifacts" / "audits" / "current_run" / "tag_naming_policy_correction_report.json", payload)
    write_json(repo_root / "artifacts" / "audits" / "campaign_1_3_closure_checklist" / "tag_naming_policy_correction_report_snapshot.json", payload)


def _write_jsonl(path: Path, rows: list[dict]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(json.dumps(row, ensure_ascii=False, sort_keys=True) for row in rows) + "\n", encoding="utf-8")


def _write_campaign_3_item_evidence(repo_root: Path) -> None:
    items = [
        ("llm_wiki_v2_knowledge_lifecycle", "5.1", "llm_wiki_v2", "real_integration", "advanced", "5.2 WeKnora", ""),
        ("weknora_auto_wiki", "5.2", "weknora", "real_integration", "advanced", "5.3 AnySearchSkill", ""),
        ("anysearchskill_provider_adapter", "5.3", "anysearchskill", "needs_strengthening", "advanced_needs_strengthening", "5.4 n8n", ""),
        ("n8n_workflow_export", "5.4", "n8n", "real_integration", "advanced", "5.5 MMSkills", ""),
        ("mmskills_multimodal_skill_package", "5.5", "mmskills", "reference_only", "advanced_reference_only", "5.6 skill-prompt-generator", ""),
        ("skill_prompt_generator_prompt_asset_library", "5.6", "skill_prompt_generator", "real_integration", "advanced", "5.7 ai-marketing-skills", ""),
        ("ai_marketing_skills_pattern_library", "5.7", "ai_marketing_skills", "real_integration", "advanced", "5.8 ai-money-maker-handbook", ""),
        ("ai_money_maker_handbook_business_scenario_library", "5.8", "ai_money_maker_handbook", "real_integration", "advanced", "5.9 Jellyfish", ""),
        ("jellyfish_content_asset_schema", "5.9", "jellyfish", "reference_only", "advanced_reference_only", "5.10 story-flicks", ""),
        ("story_flicks_video_pipeline_schema", "5.10", "story_flicks", "reference_only", "advanced_reference_only", "5.11 seedance2-skill", ""),
        ("seedance2_skill_template_metadata", "5.11", "seedance2_skill", "reference_only", "advanced_reference_only", "5.12 RAG-Anything", "verified_video_skill_template_metadata"),
        ("rag_anything_cross_modal_rag_schema", "5.12", "rag_anything", "reference_only", "advanced_reference_only", "5.13 mattpocock/skills", "cross_modal_rag_schema_reference"),
        ("mattpocock_skills_engineering_governance", "5.13", "mattpocock_skills", "real_integration", "advanced_real_integration_rule_pack_only", "5.14 Sirchmunk", "engineering_governance_rule_pack"),
        ("sirchmunk_direct_file_search", "5.14", "sirchmunk", "real_integration", "advanced_real_integration_direct_file_search_only", "5.S1 GBrain", "bounded_direct_file_search_provider"),
        ("gbrain_memory_profile_kg_strengthening", "5.S1", "gbrain", "needs_strengthening", "advanced_strengthening_record_only", "5.S2 Horizon", "memory_profile_kg_strengthening_record"),
        ("horizon_topic_intake_strengthening", "5.S2", "horizon", "real_integration", "advanced_topic_intake_schema_only", "5.S3 Obsidian-compatible Vault", "topic_intake_pipeline_schema_only"),
        ("obsidian_vault_strengthening", "5.S3", "obsidian_compatible_vault", "real_integration", "advanced_local_vault_adapter_only", "Campaign 3 Supplement 2.0 closure gate", "local_vault_adapter_only"),
    ]
    scope_by_section = {
        "5.1": "SECTION_5_ITEM_5_1_LLM_WIKI_V2",
        "5.2": "SECTION_5_ITEM_5_2_WEKNORA",
        "5.3": "SECTION_5_ITEM_5_3_ANYSEARCHSKILL",
        "5.4": "SECTION_5_ITEM_5_4_N8N",
        "5.5": "SECTION_5_ITEM_5_5_MMSKILLS",
        "5.6": "SECTION_5_ITEM_5_6_SKILL_PROMPT_GENERATOR",
        "5.7": "SECTION_5_ITEM_5_7_AI_MARKETING_SKILLS",
        "5.8": "SECTION_5_ITEM_5_8_AI_MONEY_MAKER_HANDBOOK",
        "5.9": "SECTION_5_ITEM_5_9_JELLYFISH",
        "5.10": "SECTION_5_ITEM_5_10_STORY_FLICKS",
        "5.11": "SECTION_5_ITEM_5_11_SEEDANCE2_SKILL",
        "5.12": "SECTION_5_ITEM_5_12_RAG_ANYTHING",
        "5.13": "SECTION_5_ITEM_5_13_MATTPOCOCK_SKILLS",
        "5.14": "SECTION_5_ITEM_5_14_SIRCHMUNK",
        "5.S1": "SECTION_5_STRENGTHENING_5_S1_GBRAIN",
        "5.S2": "SECTION_5_STRENGTHENING_5_S2_HORIZON",
        "5.S3": "SECTION_5_STRENGTHENING_5_S3_OBSIDIAN_COMPATIBLE_VAULT",
    }
    section_root = repo_root / "artifacts" / "audits" / "section_5"
    for run_id, section, project_id, decision, status, next_item, qualifier in items:
        run_dir = section_root / run_id
        run_dir.mkdir(parents=True, exist_ok=True)
        state_key = f"campaign_3_item_{section.replace('.', '_').replace('S', 'S')}"
        state = {
            state_key: status,
            "campaign_3_accepted": False,
            "campaign_3_3_0_active": False,
            "campaign_3_4_0_active": False,
            "campaign_4_allowed": False,
            "next_section_5_item": next_item,
        }
        payload = _basic_payload(project_id, section, decision, state, next_item, qualifier)
        payload["scope"] = scope_by_section[section]
        write_json(run_dir / "run_manifest.json", payload)
        write_json(run_dir / f"{project_id}_integration_decision_report.json", payload)
        write_json(run_dir / f"{project_id}_ui_impact_note.json", _ui_payload(project_id, decision, payload))
        aliases = {
            "ai_money_maker_handbook": "ai_money_maker_handbook",
            "obsidian_compatible_vault": "obsidian_vault",
        }
        if project_id in aliases:
            alias = aliases[project_id]
            write_json(run_dir / f"{alias}_integration_decision_report.json", payload)
            write_json(run_dir / f"{alias}_ui_impact_note.json", _ui_payload(project_id, decision, payload))
        if project_id == "obsidian_compatible_vault":
            write_json(run_dir / "obsidian_vault_integration_decision_report.json", payload)
            write_json(run_dir / "obsidian_vault_ui_impact_note.json", _ui_payload(project_id, decision, payload))
        _write_item_nested_outputs(run_dir, project_id, payload)


def _write_supplement_evidence(repo_root: Path) -> None:
    runs = [
        ("artifacts/audits/section_5/campaign_3_supplement_2_0_closure_gate", "accepted_for_transition_to_campaign_3_3_0_entry_gate", "CAMPAIGN_3_SUPPLEMENT_2_0_CLOSURE_GATE"),
        ("artifacts/audits/section_5/campaign_3_supplement_3_0_acceptance_gate", "accepted_for_pre_4_0_workspace_partition_foundation_gate", "CAMPAIGN_3_SUPPLEMENT_3_0_ACCEPTANCE_GATE"),
        ("artifacts/audits/pre_4_0_workspace_partition", "accepted_for_campaign_3_supplement_4_0_entry_gate", "PRE_4_0_WORKSPACE_PARTITION_FOUNDATION_GATE"),
        ("artifacts/audits/campaign_3_4_0", "accepted_for_campaign_3_final_consistency_gate", "CAMPAIGN_3_SUPPLEMENT_4_0_ACCEPTANCE_GATE"),
    ]
    for rel, verdict, scope in runs:
        path = repo_root / rel
        path.mkdir(parents=True, exist_ok=True)
        payload = {
            "status": "passed",
            "verdict": verdict,
            "scope": scope,
            "campaign_state_after_gate": {
                "supplement_3_0_complete": True,
                "pre_4_0_workspace_partition_complete": True,
                "campaign_3_accepted": False,
                "campaign_4_active": False,
                "campaign_5_active": False,
            },
            "campaign_state_after_run": {
                "campaign_3_supplement_2_0_closure_gate_passed": True,
                "campaign_3_accepted": False,
                "campaign_4_allowed": False,
            },
            "not_goal_complete": True,
        }
        write_json(path / "run_manifest.json", payload)
        write_json(path / "validation_report.json", {"status": "passed"})
        write_json(path / "checkpoint.json", {"checkpoint_id": Path(rel).name + "_passed", "next_safe_action": "Campaign 3 Final Consistency Gate only"})
        if scope == "CAMPAIGN_3_SUPPLEMENT_2_0_CLOSURE_GATE":
            write_json(path / "campaign_3_supplement_2_0_closure_gate.json", {**payload, "items": []})
        if scope == "CAMPAIGN_3_SUPPLEMENT_3_0_ACCEPTANCE_GATE":
            write_json(path / "campaign_3_supplement_3_0_acceptance_gate.json", payload)


def _write_product_handoff_docs(repo_root: Path) -> None:
    for rel in [
        "docs/product/CAMPAIGN_4_UI_HANDOFF_CONTRACT.json",
        "docs/product/AGENT_WORKSPACE_BINDING_SPEC.json",
        "docs/product/AGENT_MEMORY_ISOLATION_SPEC.json",
        "docs/product/AGENT_MEMORY_BACKEND_MATRIX.json",
        "docs/product/AGENT_ROLE_ASSIGNMENT_SPEC.json",
        "docs/product/AGENT_HANDOFF_RULES_SPEC.json",
        "docs/product/UI_TASK_CARD_INPUTS_FROM_CAMPAIGN_3.json",
        "docs/product/SKILL_AGENT_UI_FLOW_SPEC.json",
        "docs/product/MULTI_AGENT_UI_FLOW_SPEC.json",
        "docs/product/UI_STATE_INPUTS_FROM_CORE.json",
        "docs/bridge/CAMPAIGN_5_BRIDGE_HANDOFF_CONTRACT.json",
        "docs/bridge/FUTURE_AGENT_BRIDGE_ACTION_CANDIDATES.json",
        "docs/bridge/USER_TASK_TO_BRIDGE_FLOW_CANDIDATES.json",
        "docs/bridge/BRIDGE_MISSING_ACTION_MATRIX.json",
    ]:
        write_json(repo_root / rel, {"status": "passed", "campaign_4_active": False, "campaign_5_active": False})


def _write_closure_chain_evidence(repo_root: Path) -> None:
    write_campaign_3_final_consistency_gate(repo_root, repo_root / "artifacts" / "audits" / "campaign_3_final_consistency")
    write_campaign_1_3_stage_test_gate(repo_root, repo_root / "artifacts" / "audits" / "campaign_1_3_stage_test")
    write_campaign_1_2_3_integrated_closure_gate(repo_root, repo_root / "artifacts" / "audits" / "campaign_1_2_3_integrated_closure")
    from heitang_kb_forge.campaign_3_closure import write_campaign_1_2_3_closure_pack

    write_campaign_1_2_3_closure_pack(repo_root, repo_root / "artifacts" / "audits" / "campaign_1_2_3_closure_pack")


def _basic_payload(
    project_id: str,
    section: str,
    decision: str,
    state: dict,
    next_item: str = "current sequence only",
    qualifier: str = "",
) -> dict:
    mode = qualifier or {
        "anysearchskill": "provider_adapter",
        "n8n": "workflow_export",
        "mmskills": "schema_package_reference",
        "skill_prompt_generator": "prompt_asset_library_enhancer",
        "ai_marketing_skills": "marketing_skill_pattern_library",
        "ai_money_maker_handbook": "business_scenario_template_library",
        "jellyfish": "content_asset_schema_reference",
        "story_flicks": "aigc_video_pipeline_schema_reference",
        "llm_wiki_v2": "knowledge_lifecycle",
        "weknora": "auto_wiki_knowledge_graph",
    }.get(project_id, decision)
    payload = {
        "status": "passed",
        "project_id": project_id,
        "section": section,
        "decision": decision,
        "decision_qualifier": qualifier or mode,
        "integration_mode": mode,
        "verification_state": "verified_source_local_rule_pack_only" if project_id == "mattpocock_skills" else "verified_source_reference_only",
        "integration_decision": decision,
        "external_code_copied": False,
        "external_prompts_copied": False,
        "external_skill_files_copied": False,
        "campaign_state_after_run": state,
        "repository_check": {
            "git_ls_remote_result": "accessible",
            "github_api_result": "accessible",
            "git_ls_remote_head": "compatibility_head",
            "latest_release": "v1.3.1",
            "default_branch": "main",
            "license_spdx": "MIT",
            "repository_not_found_or_not_accessible": False,
            "repository_cloned": False,
            "external_code_copied": False,
            "external_prompts_copied": False,
            "external_prompt_text_copied": False,
            "external_skill_files_copied": False,
            "external_workflow_copied": False,
        },
        "runtime_contract": {
            "local_rule_pack_implemented": True,
            "local_schema_reference_implemented": True,
            "local_direct_file_search_implemented": True,
            "local_topic_intake_schema_implemented": True,
            "local_vault_adapter_implemented": True,
            "local_prompt_asset_library_implemented": True,
            "local_marketing_pattern_library_implemented": True,
            "local_template_metadata_implemented": True,
            "external_runtime_integrated": False,
            "vendor_runtime_integrated": False,
            "provider_adapter_integrated": False,
            "provider_call_executed": False,
            "video_generation_runtime": False,
            "agent_created_or_bound": False,
            "campaign_3_3_0_implemented": False,
            "campaign_3_4_0_implemented": False,
        },
        "provider_api_check": {
            "direct_document_access_status": "network_timeout",
            "exact_api_contract_verified": False,
            "provider_call_executed": False,
        },
        "final_target_not_downgraded": True,
        "remaining_gap": "v4.2 clean-main compatibility evidence",
        "next_required_e2e_step": _next_required_step(next_item),
        "not_goal_complete": True,
    }
    if project_id == "anysearchskill":
        payload["core_adapter_implemented"] = True
        payload["vendor_runtime_integrated"] = False
        payload["runtime_contract"].update({"api_key_optional": True, "api_key_storage": "environment_only"})
    if project_id == "n8n":
        payload.update(
            {
                "core_export_adapter_implemented": True,
                "n8n_runtime_integrated": False,
                "n8n_runtime_bundled": False,
                "n8n_runtime_started": False,
                "external_code_copied": False,
            }
        )
    if project_id == "mmskills":
        payload["repository_check"].update({"git_ls_remote_result": "repository_not_found_or_not_accessible", "github_api_result": "404_not_found"})
        payload["runtime_contract"].update(
            {
                "mmskills_runtime_integrated": False,
                "osworld_runtime_integrated": False,
                "branch_loaded_agent_runtime_integrated": False,
            }
        )
    if project_id == "skill_prompt_generator":
        payload["repository_check"]["license_gate"] = "pending_no_license_field_in_github_api"
        payload["runtime_contract"].update({"skill_prompt_generator_runtime_integrated": False, "p2_2_skill_factory_replaced": False})
    if project_id == "ai_marketing_skills":
        payload["repository_check"]["git_ls_remote_head"] = "a9f11007aca31cc85f231698e22b64412f847b76"
        payload["runtime_contract"].update(
            {
                "ai_marketing_skills_runtime_integrated": False,
                "crawler_or_scraper_marketing": False,
                "paid_media_execution": False,
                "account_operation": False,
                "revenue_guarantee": False,
            }
        )
    if project_id == "seedance2_skill":
        payload["repository_check"]["git_ls_remote_head"] = "e06c7c63a766d623004a2807881c30685ce517af"
        payload["runtime_contract"].update(
            {
                "external_prompt_body_included": False,
                "api_key_collected": False,
                "video_generation_runtime": False,
            }
        )
    if project_id == "rag_anything":
        payload["repository_check"]["git_ls_remote_head"] = "a8538efecc99719538960692745ef0eb90d1a2f9"
        payload["runtime_contract"].update(
            {
                "rag_anything_runtime_integrated": False,
                "lightrag_runtime_integrated": False,
                "mineru_runtime_executed": False,
                "llm_or_vlm_required": False,
                "embedding_required": False,
                "vector_database_required": False,
                "existing_rag_main_chain_replaced": False,
                "external_source_ingestion_implemented": False,
            }
        )
    if project_id == "mattpocock_skills":
        payload["repository_check"]["git_ls_remote_head"] = "694fa30311e02c2639942308513555e61ee84a6f"
        payload["runtime_contract"].update(
            {
                "external_agent_skill_installed": False,
                "business_runtime_created": False,
            }
        )
    if project_id == "sirchmunk":
        payload["verification_state"] = "verified_source_local_direct_file_search_only"
        payload["repository_check"].update({"git_ls_remote_head": "1e07ec11953673b601959fc82563e8264b9d5c6a", "latest_release": "v0.0.7", "license_spdx": "Apache-2.0"})
        payload["runtime_contract"].update(
            {
                "sirchmunk_runtime_integrated": False,
                "official_runtime_executed": False,
                "llm_required": False,
                "embedding_required": False,
                "vector_database_required": False,
                "network_required": False,
                "external_source_ingestion_implemented": False,
            }
        )
    if project_id == "gbrain":
        payload["verification_state"] = "verified_source_strengthening_record_only"
        payload["repository_check"].update({"git_ls_remote_head": "4ee530f3c545b880cecc47c4f877e0ed014896b4", "default_branch": "master"})
        payload["runtime_contract"].update(
            {
                "local_strengthening_rules_implemented": True,
                "gbrain_runtime_integrated": False,
                "bun_dependency_installed": False,
                "pglite_or_postgres_configured": False,
                "pgvector_required": False,
                "mcp_connector_enabled": False,
            }
        )
    if project_id == "horizon":
        payload["integration_mode"] = "topic_intake_pipeline_schema_strengthening"
        payload["verification_state"] = "verified_source_strengthening_record_only"
        payload["repository_check"]["git_ls_remote_head"] = "7e0ffbbd069765b77af053e73ccc0cd6ccc2456f"
        payload["runtime_contract"].update(
            {
                "horizon_runtime_integrated": False,
                "crawler_or_scraper_integrated": False,
                "scheduled_fetcher_enabled": False,
                "api_key_required": False,
                "delivery_channel_enabled": False,
                "mcp_connector_enabled": False,
                "external_source_ingestion_implemented": False,
            }
        )
    if project_id == "obsidian_compatible_vault":
        payload["project_id"] = "obsidian_compatible_vault"
        payload["integration_mode"] = "local_markdown_vault_adapter_strengthening"
        payload["verification_state"] = "local_adapter_strengthening_record_only"
        payload["next_required_e2e_step"] = "Run Campaign 3 Supplement 2.0 closure gate only."
        payload["runtime_contract"].update(
            {
                "markdown_folder_import": True,
                "markdown_folder_export": True,
                "frontmatter_support": True,
                "wikilink_support": True,
                "backlink_map_support": True,
                "folder_structure_support": True,
                "obsidian_runtime_integrated": False,
                "obsidian_plugin_required": False,
                "obsidian_app_launched": False,
                "obsidian_sync_required": False,
                "database_required": False,
                "network_required": False,
                "external_source_ingestion_implemented": False,
            }
        )
    return payload


def _ui_payload(project_id: str, decision: str, base: dict) -> dict:
    ui = dict(base)
    current_ui_state = {
        "status_visible": True,
        "local_ready": True,
        "ready": False,
        "executable_action": False,
        "core_action_available": False,
        "runtime_execution_action_available": False,
    }
    current_ui_state.update(
        {
            "check_action_available": False,
            "smoke_action_available": False,
            "run_action_available": False,
            "blocked_reason": "ui_configuration_pending",
            "workflow_export_action_available": False,
            "multimodal_skill_preview_available": True,
            "prompt_asset_preview_available": True,
            "marketing_skill_pattern_preview_available": True,
            "topic_radar_future_slot_visible": True,
            "template_metadata_preview_available": True,
            "license_visible": True,
            "provider_requirement_visible": True,
            "schema_preview_available": True,
            "benchmark_profile_preview_available": True,
            "development_rules_report_visible": True,
            "business_workflow_entry": False,
            "agent_action_available": False,
            "direct_file_search_status_visible": True,
            "source_trace_visible": True,
            "memory_profile_strengthening_visible": True,
            "kg_gap_rules_visible": True,
            "topic_radar_visible": True,
            "information_intake_visible": True,
            "daily_briefing_preview_visible": True,
            "content_candidate_queue_visible": True,
            "local_vault_import_visible": True,
            "markdown_folder_import_visible": True,
            "obsidian_compatible_export_visible": True,
            "frontmatter_preview_visible": True,
            "backlink_map_preview_visible": True,
            "folder_structure_preview_visible": True,
            "provider_config_action_available": False,
            "video_generation_action_available": False,
            "vendor_runtime_action_available": False,
            "multimodal_query_action_available": False,
            "vector_db_action_available": False,
            "gbrain_runtime_action_available": False,
            "mcp_connector_action_available": False,
            "database_setup_action_available": False,
            "horizon_runtime_action_available": False,
            "crawler_action_available": False,
            "scheduler_action_available": False,
            "delivery_action_available": False,
            "obsidian_runtime_action_available": False,
            "obsidian_plugin_action_available": False,
            "sync_service_action_available": False,
            "campaign_4_workflow_accepted": False,
        }
    )
    ui["current_ui_state"] = current_ui_state
    ui["ui_must_not_show"] = [
        "ai-marketing-skills runtime ready",
        "Campaign 3 accepted",
        "AnySearchSkill runtime ready",
        "MMSkills runtime ready",
        "skill-prompt-generator runtime ready",
        "Seedance runtime ready",
        "Generate video",
        "RAG-Anything runtime ready",
        "Run multimodal query",
        "mattpocock/skills runtime ready",
        "Create Agent from mattpocock/skills",
        "Sirchmunk runtime ready",
        "Build vector DB with Sirchmunk",
        "GBrain runtime ready",
        "Connect GBrain MCP",
        "Create Agent from GBrain",
        "Horizon runtime ready",
        "Start Horizon crawler",
        "Enable daily scheduled fetch",
        "Campaign 3.0 active",
        "Obsidian runtime ready",
        "Install or run Obsidian plugin",
        "Start Obsidian sync",
    ]
    ui["integration_decision"] = decision
    return ui


def _next_required_step(next_item: str) -> str:
    if next_item.startswith("5.S"):
        return f"Process Section 5 strengthening item {next_item} only."
    if next_item.startswith("5."):
        return f"Process Section 5 item {next_item} only."
    return f"Process Section 5 item {next_item} only."


def _write_item_nested_outputs(run_dir: Path, project_id: str, payload: dict) -> None:
    if project_id == "anysearchskill":
        write_json(run_dir / "real_smoke" / "anysearch_provider_smoke.json", {"status": "passed", "runtime_status": "available", "smoke_status": "passed", "anonymous_mode": True, "network_called": True, "result_count": 1, "secrets_persisted": False})
        write_json(run_dir / "real_smoke" / "source_trace.json", {"source_count": 1})
        write_json(run_dir / "real_run" / "anysearch_retrieval_result.json", {"status": "passed", "runtime_status": "available", "network_called": True, "result_count": 1, "secrets_persisted": False})
    elif project_id == "n8n":
        write_json(run_dir / "export" / "n8n_export_validation.json", {"status": "passed", "credentials_embedded": False, "dangerous_node_types": [], "n8n_runtime_bundled": False})
        write_json(run_dir / "export" / "external_automation_manifest.json", {"status": "export_ready", "runtime_model": "user_owned_external_runtime"})
        write_json(run_dir / "export" / "n8n_workflow.json", {"active": False, "nodes": [{"type": "n8n-nodes-base.webhook"}, {"type": "n8n-nodes-base.respondToWebhook"}]})
        write_json(run_dir / "export" / "webhook_contract.json", {"source_trace_required": True, "authentication": {"credentials_embedded": False}})
        for name in ["sample_event.json", "n8n_export_report.md"]:
            path = run_dir / "export" / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text("{}\n" if name.endswith(".json") else "n8n export report\n", encoding="utf-8")
    elif project_id == "mmskills":
        write_json(run_dir / "multimodal_skill_package" / "multimodal_skill_manifest.json", {**payload, "validation_status": "passed", "source_status": "text_fallback"})
        write_json(run_dir / "validation" / "multimodal_skill_validation_report.json", {**payload, "status": "passed"})
    elif project_id == "skill_prompt_generator":
        write_json(run_dir / "prompt_asset_library" / "prompt_asset_manifest.json", {**payload, "status": "passed", "prompt_card_count": 3})
        write_json(run_dir / "validation" / "prompt_asset_validation_report.json", {**payload, "status": "passed"})
    elif project_id == "ai_marketing_skills":
        write_json(run_dir / "marketing_pattern_library" / "marketing_pattern_manifest.json", {**payload, "status": "passed", "pattern_count": 8})
        write_json(run_dir / "validation" / "marketing_pattern_validation_report.json", {**payload, "status": "passed"})
    elif project_id == "seedance2_skill":
        write_json(run_dir / "template_metadata" / "video_skill_template_metadata.json", {**payload, "status": "passed"})
        write_json(run_dir / "validation" / "video_skill_template_validation_report.json", {**payload, "status": "passed", "boundary_errors": []})
    elif project_id == "rag_anything":
        write_json(run_dir / "schema" / "cross_modal_rag_manifest.json", {**payload, "status": "passed"})
        write_json(run_dir / "validation" / "cross_modal_rag_validation_report.json", {**payload, "status": "passed", "boundary_errors": []})
    elif project_id == "mattpocock_skills":
        write_json(run_dir / "rules" / "engineering_governance_manifest.json", {**payload, "status": "passed", "rule_counts": {"pre_code": 4, "test_gate": 4, "review_gate": 3, "ai_collaboration": 3}})
        write_json(run_dir / "validation" / "engineering_governance_validation_report.json", {**payload, "status": "passed", "boundary_errors": []})
    elif project_id == "sirchmunk":
        write_json(run_dir / "search" / "sirchmunk_direct_file_search_manifest.json", {**payload, "status": "passed", "search_summary": {"result_count": 1}})
        write_json(run_dir / "validation" / "sirchmunk_direct_file_search_validation_report.json", {**payload, "status": "passed", "boundary_errors": []})
    elif project_id == "gbrain":
        write_json(run_dir / "rules" / "gbrain_strengthening_manifest.json", {**payload, "status": "passed"})
        write_json(run_dir / "validation" / "gbrain_strengthening_validation_report.json", {**payload, "status": "passed", "boundary_errors": []})
    elif project_id == "horizon":
        write_json(run_dir / "rules" / "horizon_strengthening_manifest.json", {**payload, "status": "passed"})
        write_json(run_dir / "validation" / "horizon_strengthening_validation_report.json", {**payload, "status": "passed", "boundary_errors": []})
    elif project_id == "obsidian_compatible_vault":
        write_json(run_dir / "rules" / "obsidian_vault_strengthening_manifest.json", {**payload, "status": "passed"})
        write_json(run_dir / "validation" / "obsidian_vault_validation_report.json", {**payload, "status": "passed", "boundary_errors": [], "note_count": 2, "folder_count": 2, "backlink_edge_count": 2})


def _goal_acceptance_ledger() -> dict:
    allowed_statuses = [
        "not_started",
        "in_progress",
        "contract_only",
        "dependency_blocked",
        "real_smoke_passed",
        "ui_connected",
        "e2e_passed",
        "full_gate_passed",
        "done",
    ]
    capability_ids = [
        "batch_import",
        "document_preflight",
        "backend_dependency_remediation",
        "backend_real_smoke",
        "ocr_document_understanding",
        "knowledge_base_build",
        "search_index",
        "knowledge_verification",
        "methodology_extraction",
        "skill_generation",
        "skill_import_decomposition_learning",
        "owned_skill_generation",
        "agent_creation",
        "agent_binding",
        "multi_agent_workflow",
        "external_evidence_verification",
        "api_proxy_config",
        "db_redis_vector_db_config",
        "progress_events",
        "ui_core_bridge",
        "report_export",
        "exe_packaging",
    ]
    statuses = {
        capability_id: "e2e_passed"
        for capability_id in capability_ids
    }
    statuses.update(
        {
            "ui_core_bridge": "ui_connected",
            "api_proxy_config": "in_progress",
            "db_redis_vector_db_config": "contract_only",
            "skill_import_decomposition_learning": "contract_only",
            "owned_skill_generation": "contract_only",
            "multi_agent_workflow": "contract_only",
            "exe_packaging": "not_started",
            "backend_dependency_remediation": "real_smoke_passed",
            "backend_real_smoke": "real_smoke_passed",
        }
    )
    campaign_reviews = _campaign_acceptance_reviews()
    return {
        "allowed_statuses": allowed_statuses,
        "goal_active": True,
        "capabilities": [
            {
                "id": capability_id,
                "status": statuses[capability_id],
                "final_target_not_downgraded": True,
                "remaining_gap": "v4.2 public reset compatibility summary",
                "next_required_e2e_step": "Continue v4.2 public reset only.",
                "not_goal_complete": True,
            }
            for capability_id in capability_ids
        ],
        "last_goal_drift_review": {
            "task_focus": [
                "closure_checklist_green_verification",
                "campaign_1_3_integrated_review_handoff_gate",
                "campaign_1_3_review_reports",
                "new_conversation_handoff_prompt",
            ],
            "advanced_in_this_task": [
                "closure_checklist_green",
                "campaign_1_3_integrated_review_handoff_gate_passed",
                "campaign_1_2_3_integrated_review_report_generated",
                "campaign_1_2_3_external_project_integration_review_generated",
                "campaign_1_2_3_capability_review_matrix_generated",
                "new_conversation_handoff_prompt_generated",
            ],
            "not_advanced_in_this_task": [
                "github_release_created",
                "campaign_1_3_baseline_stable_tag_created",
                "campaign_4_business_implementation",
            ],
            "states_forbidden_in_this_task": [
                "github_release_created",
                "campaign_4_active",
                "presenton_ppt_runtime_integrated",
                "longlive_video_generation_integrated",
                "codegraph_knowledge_graph_integrated",
                "understand_anything_knowledge_graph_integrated",
                "claude_plugin_runtime_integrated",
                "pi_mono_runtime_integrated",
                "skill_template_published",
                "composed_skill_published",
                "campaign_1_3_baseline_stable_tag_created",
                "product_version_tag_created",
                "full_gate_passed",
            ],
            "goal_downgrade_detected": False,
            "next_e2e_gap": "Campaign 1-3 Integrated Review and New Conversation Handoff Gate passed; Open a new conversation and start Campaign 4 Entry Gate only; Campaign 4 business implementation",
        },
        "campaign_acceptance_reviews": campaign_reviews,
    }


def _campaign_acceptance_reviews() -> dict:
    base_not_later = {
        "campaign_3_accepted": False,
        "campaign_3_3_0_active": False,
        "campaign_3_4_0_active": False,
        "campaign_4_allowed": False,
    }
    reviews = {
        "pre_campaign_acceptance_gate": {
            "status": "accepted",
            "campaign_3_allowed_next": True,
            "campaign_3_active": True,
            "next_allowed_campaign": "Section 5 / Campaign 3",
        },
        "all_campaign_stage_gate_policy": {
            "status": "in_progress",
            "scope": "Campaigns 1-9 and Final Release",
            "evidence": ["tests/test_campaign_stage_gate_policy.py"],
            "boundary": "Campaign 3 is accepted only after its Final Consistency Gate; does not open Campaign 4 or allow final release",
        },
        "campaign_3_2_0_supplement": {
            "status": "accepted_for_transition_to_campaign_3_3_0_entry_gate",
            "scope": "Section 5 internal supplement only",
            "next_business_item": "Campaign 3 Supplement 3.0 Entry Gate",
            "remaining_main_items": [],
            "strengthening_items": [],
            "closure_gate_passed": True,
            "boundary": "does not change the 12-section total plan; transition only to Campaign 3 Supplement 3.0 Entry Gate; does not start Campaign 3.0 business implementation; does not accept Campaign 3; does not open Campaign 4",
        },
        "campaign_3_3_0_external_source_memory_verification": {
            "status": "accepted",
            "plan_state": "accepted_stop_pre_4_0_next",
            "next_business_item": "Pre-4.0 Workspace Partition & Knowledge Base Access Scope Foundation Gate",
            "entry_gate_passed": True,
            "p0_framework_passed": True,
            "generic_web_url_ingestion_passed": True,
            "platform_link_preflight_passed": True,
            "opencli_external_search_verification_passed": True,
            "manual_evidence_upload_passed": True,
            "unified_trace_progress_failure_isolation_passed": True,
            "authenticated_browser_connector_alpha_passed": True,
            "video_visual_foundations_passed": True,
            "knowledge_verification_foundations_passed": True,
            "knowledge_verification_dashboard_foundation_complete": True,
            "acceptance_gate_passed": True,
            "supplement_3_0_complete": True,
            "campaign_3_3_0_accepted": True,
            "activation_prerequisites": [
                "Campaign 3 Supplement 2.0 closure gate passed",
                "Campaign 3 Supplement 3.0 Entry Gate passed",
                "Campaign 3 Supplement 3.0 P0 framework passed",
                "Campaign 3 Supplement 3.0 P0 Generic Web URL Ingestion passed",
                "Campaign 3 Supplement 3.0 P0 Platform Link Preflight passed",
                "Campaign 3 Supplement 3.0 P0 OpenCLI External Search Verification passed",
                "Campaign 3 Supplement 3.0 P0 Manual Evidence Upload passed",
            ],
            "required_domains": ["link_to_knowledge_ingestion", "knowledge_verification_engine"],
            "boundary": "Campaign 3 Supplement 3.0 Acceptance Gate passed; supplement_3_0_complete=true; campaign_3_3_0_accepted=true; Campaign 3 is accepted only after its Final Consistency Gate; 12-section total plan remains unchanged",
            "local_core_bridge_complete": False,
        },
        "pre_4_0_workspace_partition_foundation_gate": {
            "status": "accepted",
            "plan_state": "passed_foundation_contract",
            "next_business_item": "Campaign 3 Supplement 4.0B Verified Knowledge-to-Skill Template passed; next is Campaign 3 Supplement 4.0C Skill Import & Dedicated Skill Composer only",
            "activation_prerequisites": ["Campaign 3 Supplement 3.0 accepted"],
            "pre_4_0_workspace_partition_complete": True,
            "workspace_manifest_ready": True,
            "kb_access_scope_ready": True,
            "workspace_partition_runtime_enforcement_ready": False,
            "campaign_4_active": False,
            "campaign_5_active": False,
        },
        "campaign_4_9_replacement_plan_v3": {
            "status": "registered_planned_not_active",
            "next_business_item": "Campaign 3 Final Consistency Gate only",
            "replacement_order": [
                "Campaign 4 Goal-Oriented Product UI Workbench",
                "Campaign 5 Chain-Level Local Core Bridge",
                "Campaign 6 Agent Runtime & Memory Platform",
                "Campaign 7 Configuration System",
                "Campaign 8 Full Testing / Full Review",
                "Campaign 9 EXE Packaging",
                "Final Release after Campaign 9 acceptance",
            ],
            **{f"campaign_{campaign}_active": False for campaign in range(4, 10)},
            "final_release_allowed": False,
        },
        "campaign_3_4_0_knowledge_to_skill_template_generator": {
            "status": "accepted",
            "plan_state": "accepted_for_campaign_3_final_consistency_gate",
            "next_business_item": "Campaign 3 Final Consistency Gate only",
            "entry_gate_passed": True,
            "verified_knowledge_to_skill_template_passed": True,
            "skill_template_draft_generated": True,
            "skill_template_validator_report_passed": True,
            "skill_testcases_generated": True,
            "skill_template_publication_state": "draft",
            "skill_template_published": False,
            "skill_import_composer_passed": True,
            "dedicated_skill_composed": True,
            "dedicated_skill_package_generated": True,
            "skill_source_binding_generated": True,
            "skill_conflict_report_passed": True,
            "document_outputs_existing_core_capability_preserved": True,
            "composed_skill_publication_state": "draft",
            "composed_skill_published": False,
            "agent_package_generated_by_4_0c": False,
            "business_implementation_complete": True,
            "acceptance_gate_passed": True,
            "activation_prerequisites": [
                "Campaign 3 Supplement 3.0 accepted",
                "Pre-4.0 Workspace Partition Foundation Gate passed",
                "Campaign 3 Supplement 4.0 Entry Reconciliation Gate passed",
            ],
            "required_domains": ["knowledge_base_profile", "explicit_user_confirmed_publication"],
            "supported_skill_types": [
                "literary_skill",
                "visual_video_skill",
                "domain_expert_skill",
                "operation_growth_skill",
                "product_business_skill",
                "research_learning_skill",
                "general_personal_skill",
            ],
            "product_handoff_bundle_passed": True,
            "agent_package_generated_by_4_0d": True,
            "campaign_4_ui_handoff_contract_passed": True,
            "campaign_5_bridge_handoff_contract_passed": True,
            "acceptance_gate_verdict": "accepted_for_campaign_3_final_consistency_gate",
            "boundary": "Acceptance Gate passed; accepts Supplement 4.0 only; UI handoff is not Campaign 4 UI completion; Bridge handoff is not Campaign 5 Bridge completion",
            "agent_package_ready": True,
            "agent_runtime_ready": False,
            "multi_agent_runtime_ready": False,
            "campaign_4_active": False,
            "campaign_5_active": False,
            "campaign_3_final_consistency_gate_passed": False,
            "campaign_3_accepted": False,
        },
        "campaign_1_2_3_integrated_closure_chain": {
            "status": "blocked_by_sequence",
            "plan_state": "waiting_for_campaign_3_final_consistency_gate",
            "next_business_item": "Campaign 3 Final Consistency Gate only",
            "campaign_1_3_stage_test_gate_passed": False,
            "campaign_1_3_integrated_closure_gate_passed": False,
            "closure_pack_generated": False,
            "repository_public_surface_cleanup_gate_passed": False,
            "repository_push_succeeded": False,
            "tag_created": False,
            "ci_green": False,
            "evidence": [],
            "boundary": "Integrated Closure remains blocked until Campaign 3 Final Consistency Gate",
        },
    }
    reviews.update(
        {
            "campaign_3_strengthening_5_S3_obsidian_compatible_vault": {
                **base_not_later,
                "status": "advanced_real_integration_local_vault_adapter_only",
                "decision": "real_integration",
                "decision_qualifier": "local_vault_adapter_only",
                "integration_mode": "local_markdown_vault_adapter_strengthening",
                "verification_state": "local_adapter_strengthening_record_only",
                "boundary": "frontmatter, wikilinks, backlinks, folder structure; No Obsidian runtime; external-source ingestion remains separate",
            },
            "campaign_3_item_5_11_seedance2_skill": {
                **base_not_later,
                "status": "advanced_reference_only",
                "decision": "reference_only",
                "integration_mode": "verified_video_skill_template_metadata",
                "verification_state": "verified_source_reference_only",
                "boundary": "exact provider api and pricing contracts remain unverified; no provider adapter",
            },
            "campaign_3_item_5_12_rag_anything": {
                **base_not_later,
                "status": "advanced_reference_only",
                "decision": "reference_only",
                "integration_mode": "cross_modal_rag_schema_reference",
                "verification_state": "verified_source_reference_only",
                "boundary": "No RAG-Anything runtime; existing RAG main chain is not replaced",
            },
            "campaign_3_item_5_13_mattpocock_skills": {
                **base_not_later,
                "status": "advanced_real_integration_rule_pack_only",
                "decision": "real_integration",
                "integration_mode": "engineering_governance_rule_pack",
                "verification_state": "verified_source_local_rule_pack_only",
                "boundary": "local engineering governance rule-pack only; No mattpocock/skills repository clone; Agent creation remains separate",
            },
            "campaign_3_item_5_14_sirchmunk": {
                **base_not_later,
                "status": "advanced_real_integration_direct_file_search_only",
                "decision": "real_integration",
                "integration_mode": "bounded_direct_file_search_provider",
                "verification_state": "verified_source_local_direct_file_search_only",
                "boundary": "bounded local direct-file-search provider candidate only; No Sirchmunk repository clone; vector DB not required; arbitrary shell execution forbidden",
            },
            "campaign_3_strengthening_5_S1_gbrain": {
                **base_not_later,
                "status": "advanced_needs_strengthening",
                "decision": "needs_strengthening",
                "integration_mode": "memory_profile_kg_strengthening_record",
                "verification_state": "verified_source_strengthening_record_only",
                "campaign_3_supplement_2_0_closure_gate_passed": False,
                "evidence": ["gbrain_integration_decision_report.json"],
                "boundary": "local memory/profile/KG strengthening record only; No GBrain repository clone; Bun dependency not bundled; MCP connector inactive; Agent creation remains separate",
            },
            "campaign_3_strengthening_5_S2_horizon": {
                **base_not_later,
                "status": "advanced_real_integration_schema_only",
                "decision": "real_integration",
                "decision_qualifier": "topic_intake_pipeline_schema_only",
                "integration_mode": "topic_intake_pipeline_schema_strengthening",
                "verification_state": "verified_source_strengthening_record_only",
                "campaign_3_supplement_2_0_closure_gate_passed": False,
                "evidence": ["horizon_integration_decision_report.json"],
                "boundary": "local Topic Intake Pipeline schema strengthening only; No Horizon repository clone; crawler inactive; MCP connector inactive; Campaign 3.0 remains separate",
            },
        }
    )
    return reviews
