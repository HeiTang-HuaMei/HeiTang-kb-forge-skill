from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
GOVERNANCE = ROOT / "docs" / "governance"
POLICY = GOVERNANCE / "CAMPAIGN_STAGE_GATE_POLICY.md"
MATRIX = GOVERNANCE / "TARGET_ACCEPTANCE_MATRIX.md"
PRE_GATE = GOVERNANCE / "PRE_CAMPAIGN_ACCEPTANCE_GATE.md"
INTEGRATED_CLOSURE_POLICY = GOVERNANCE / "CAMPAIGN_1_2_3_INTEGRATED_CLOSURE_POLICY.md"


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def test_campaign_stage_gate_policy_exists_and_defines_universal_gates():
    policy = _read(POLICY)

    for marker in [
        "The same strong gate mechanism applies to Campaigns 1-9 and Final Release",
        "Entry Gate",
        "Acceptance Gate",
        "Transition Gate",
        "Every campaign must have all three gates",
        "previous campaign must be accepted",
        "current campaign must be accepted",
        "No campaign can inherit acceptance from a previous local E2E",
    ]:
        assert marker in policy


def test_campaign_stage_gate_policy_covers_all_campaigns_and_final_release():
    policy = _read(POLICY)

    for marker in [
        "Campaign 1: Document Backend",
        "Campaign 2: Batch Import",
        "Campaign 3: Not-Yet-Integrated Projects",
        "Campaign 4: Goal-Oriented Product UI Workbench",
        "Campaign 5: Chain-Level Local Core Bridge",
        "Campaign 6: Agent Runtime & Memory Platform",
        "Campaign 7: Configuration System",
        "Campaign 8: Full Testing / Full Review",
        "Final Release",
    ]:
        assert marker in policy


def test_campaign_3_acceptance_uses_2_0_dedup_and_extended_section_5_scope():
    policy = _read(POLICY)

    for marker in [
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
    ]:
        assert marker in policy


def test_campaign_stage_gate_policy_forbids_substitution_shortcuts():
    policy = _read(POLICY)

    for marker in [
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
    ]:
        assert marker in policy


def test_campaign_stage_gate_policy_defines_normative_transition_predicates():
    policy = _read(POLICY)

    for marker in [
        "Transition Predicate Table",
        "Campaign 3 active",
        "Campaign 1 accepted and Campaign 2 accepted",
        "Campaign 4 active",
        "Campaign 3 accepted, Campaign 1-3 closure tag exists, tag-related CI/CL is green",
        "Campaign 1-3 Stage Test Gate active",
        "Campaign 1-3 Integrated Closure Gate active",
        "Repository Public Surface Cleanup / Rename / Push-Tag Safety Gate active",
        "Repository push",
        "Closure tag creation",
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
    ]:
        assert marker in policy


def test_later_campaigns_are_blocked_by_previous_acceptance():
    combined = "\n".join([_read(POLICY), _read(MATRIX), _read(PRE_GATE)])

    for marker in [
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
        "Later campaigns still require their own Entry Gate, Acceptance Gate, and Transition Gate",
    ]:
        assert marker in combined


def test_current_gate_status_tracks_campaign_3_in_progress_not_accepted():
    combined = "\n".join([_read(POLICY), _read(MATRIX), _read(PRE_GATE)])

    assert "Campaign 1 acceptance review: `accepted`" in combined
    assert "Campaign 2 acceptance review: `accepted`" in combined
    assert "Campaign 3 status: `in_progress`" in combined
    assert "Campaign 3 active: `true`" in combined
    assert "Campaign 3 item 5.1 LLM Wiki v2: `advanced`" in combined
    assert "Campaign 3 item 5.2 WeKnora: `advanced`" in combined
    assert "Campaign 3 item 5.3 AnySearchSkill: `advanced_needs_strengthening`" in combined
    assert "Campaign 3 item 5.4 n8n: `advanced`" in combined
    assert "Campaign 3 item 5.5 MMSkills: `advanced_reference_only`" in combined
    assert "Campaign 3 item 5.6 skill-prompt-generator: `advanced`" in combined
    assert "Campaign 3 item 5.7 ai-marketing-skills: `advanced`" in combined
    assert "Campaign 3 item 5.8 ai-money-maker-handbook: `advanced`" in combined
    assert "Campaign 3 item 5.9 Jellyfish: `advanced_reference_only`" in combined
    assert "Campaign 3 item 5.10 story-flicks: `advanced_reference_only`" in combined
    assert "Campaign 3 item 5.11 seedance2-skill: `advanced_reference_only`" in combined
    assert "Campaign 3 item 5.12 RAG-Anything: `advanced_reference_only`" in combined
    assert "Campaign 3 item 5.13 mattpocock/skills: `advanced_real_integration_rule_pack_only`" in combined
    assert "Campaign 3 item 5.14 Sirchmunk: `advanced_real_integration_direct_file_search_only`" in combined
    assert "Campaign 3 strengthening item 5.S1 GBrain: `advanced_strengthening_record_only`" in combined
    assert "Campaign 3 strengthening item 5.S2 Horizon: `advanced_topic_intake_schema_only`" in combined
    assert "Campaign 3 strengthening item 5.S3 Obsidian-compatible Vault: `advanced_local_vault_adapter_only`" in combined
    assert "Campaign 3 Supplement 2.0 closure gate: `passed`" in combined
    assert "Campaign 3 next business item: `Campaign 3 Final Consistency Gate only`" in combined
    assert "Campaign 3 Supplement 3.0 Entry Gate: `passed`" in combined
    assert "Campaign 3 Supplement 3.0 P0 framework: `passed_framework_only`" in combined
    assert "Campaign 3 Supplement 3.0 P0 Generic Web URL Ingestion: `passed_generic_web_url_only`" in combined
    assert "Campaign 3 Supplement 3.0 P0 Platform Link Preflight: `passed_platform_preflight_only`" in combined
    assert "Campaign 3 Supplement 3.0 P0 OpenCLI External Search Verification: `passed_opencli_verification_only`" in combined
    assert "Campaign 3 Supplement 3.0 P0 Manual Evidence Upload: `passed_manual_evidence_only`" in combined
    assert "Campaign 3 Supplement 3.0 P0 unified Source Trace / Evidence Map, progress events, and failure isolation: `passed_unified_trace_only`" in combined
    assert "Campaign 3 Supplement 3.0 P0 External Link Import entry and completed-P0 allowlist/no-shell: `passed_entry_bridge_allowlist_only`" in combined
    assert "Campaign 3 Supplement 3.0 P1 Authenticated Browser Connector Alpha: `passed_authenticated_visible_content_alpha_only`" in combined
    assert "Campaign 3 Supplement 3.0 P1 Video-to-Knowledge and Visual Evidence Understanding foundations: `passed_video_visual_foundations_only`" in combined
    assert "Campaign 3 Supplement 3.0 P1 Knowledge Verification Engine and dashboard foundations: `passed_knowledge_verification_foundations_only`" in combined
    assert "Campaign 3 Supplement 3.0: `accepted_stop_pre_4_0_next`" in combined
    assert "Campaign 3 Supplement 3.0 accepted: `true`" in combined
    assert "Pre-4.0 Workspace Partition Foundation Gate: `passed_foundation_contract`" in combined
    assert "Pre-4.0 Workspace Partition Foundation Gate passed: `true`" in combined
    assert "Campaign 3 Supplement 4.0: `accepted_for_campaign_3_final_consistency_gate`" in combined
    assert "Campaign 3 Supplement 4.0 entry gate: `passed`" in combined
    assert "Campaign 3 Supplement 4.0B Knowledge-to-Skill Template Generator: `passed`" in combined
    assert "Campaign 3 Supplement 4.0C Skill Import & Dedicated Skill Composer: `passed`" in combined
    assert "Campaign 3 Supplement 4.0D-I Product Handoff Contract Bundle: `passed`" in combined
    assert "Campaign 3 Supplement 4.0 accepted: `true`" in combined
    assert "Campaign 3 Final Consistency Gate: `next_required`" in combined
    assert "Campaign 1-3 Stage Test Gate: `blocked_by_sequence`" in combined
    assert "Campaign 1-3 Integrated Closure Gate: `blocked_by_sequence`" in combined
    assert "Repository Public Surface Cleanup / Rename / Push-Tag Safety Gate: `not_started`" in combined
    assert "Repository push: `not_started`" in combined
    assert "Campaign 1-3 closure tag: `not_created`" in combined
    assert "Campaign 1-3 closure CI: `not_checked`" in combined
    assert "Campaign 3 accepted: `false`" in combined
    assert "Campaigns 4-9 status: `blocked_by_sequence`" in combined
    assert "Final Release status: `blocked_until_campaigns_1_to_9_accepted`" in combined


def test_campaign_transition_predicates_block_unaccepted_previous_campaigns_through_final_release():
    def can_activate_campaign_3(campaign_1: str, campaign_2: str) -> bool:
        return campaign_1 == "accepted" and campaign_2 == "accepted"

    def can_activate_next(previous_campaign: str) -> bool:
        return previous_campaign == "accepted"

    def can_release(campaigns: dict[str, str]) -> bool:
        return all(campaigns.get(f"campaign_{index}") == "accepted" for index in range(1, 10))

    def blocked_transition(previous_campaign: str, attempted_next: str) -> tuple[str, bool]:
        return attempted_next, can_activate_next(previous_campaign)

    assert can_activate_campaign_3("accepted", "accepted") is True
    assert can_activate_campaign_3("not_accepted", "accepted") is False
    assert can_activate_campaign_3("accepted", "not_accepted") is False

    for blocked in [
        blocked_transition("in_progress", "campaign_4_active"),
        blocked_transition("not_started", "campaign_5_active"),
        blocked_transition("partially_complete", "campaign_6_active"),
        blocked_transition("config_schema_present", "campaign_7_active"),
        blocked_transition("focused_tests_passed", "campaign_8_active"),
        blocked_transition("packaging_script_present", "campaign_9_active"),
    ]:
        assert blocked[1] is False, blocked[0]

    for blocked_previous in ["not_started", "partially_complete", "local_e2e_passed"]:
        assert can_activate_next(blocked_previous) is False

    assert can_activate_next("accepted") is True

    assert can_activate_next("campaign_3_in_progress") is False
    assert can_activate_next("ui_action_entry_present") is False
    assert can_activate_next("bridge_allowlist_present") is False
    assert can_activate_next("config_schema_present") is False
    assert can_activate_next("focused_tests_passed") is False
    assert can_activate_next("packaging_script_present") is False

    accepted_until_8 = {f"campaign_{index}": "accepted" for index in range(1, 9)}
    accepted_until_8["campaign_9"] = "packaging_script_present"
    assert can_release(accepted_until_8) is False

    all_accepted = {f"campaign_{index}": "accepted" for index in range(1, 10)}
    assert can_release(all_accepted) is True


def test_evidence_shortcuts_do_not_satisfy_acceptance_predicates():
    def campaign_accepted(evidence: dict) -> bool:
        return evidence.get("campaign_accepted") is True

    def full_gate_passed(evidence: dict) -> bool:
        return evidence.get("full_gate_passed") is True

    def goal_oriented_ui_workbench_accepted(evidence: dict) -> bool:
        return evidence.get("goal_oriented_ui_workbench_accepted") is True

    def bridge_execution_accepted(evidence: dict) -> bool:
        return evidence.get("bridge_execution_accepted") is True

    def exe_accepted(evidence: dict) -> bool:
        return evidence.get("exe_accepted") is True

    assert campaign_accepted({"local_e2e_passed": True}) is False
    assert full_gate_passed({"focused_tests_passed": True}) is False
    assert goal_oriented_ui_workbench_accepted({"ui_action_entry_present": True}) is False
    assert bridge_execution_accepted({"bridge_allowlist_present": True}) is False
    assert exe_accepted({"packaging_script_present": True}) is False

    assert campaign_accepted({"campaign_accepted": True}) is True
    assert full_gate_passed({"full_gate_passed": True}) is True
    assert goal_oriented_ui_workbench_accepted({"goal_oriented_ui_workbench_accepted": True}) is True
    assert bridge_execution_accepted({"bridge_execution_accepted": True}) is True
    assert exe_accepted({"exe_accepted": True}) is True


def test_target_acceptance_matrix_keeps_strong_gates_for_later_campaigns():
    matrix = _read(MATRIX)

    for marker in [
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
        "closure tag is created",
        "tag-related CI/CL is green",
        "Full goal-oriented desktop UI workbench with product-line task cards",
        "Real user-task bridge flow execution with path validation, timeout, structured error, audit log, recovery path, and no arbitrary shell execution",
        "Real Agent runtime with KB/Skill use, tool permission enforcement, run logs, audit trace, output verification, memory fallback, and Agent/workspace memory isolation",
        "Real API/proxy, DB, Redis, vector DB, workspace path, Agent runtime, Agent memory backend, and OpenCLI checks plus settings export/import and diagnostics",
        "Full validation over Core, UI, Bridge, config, external source, Skill, Agent Package, Agent runtime, Agent memory, Multi-Agent, packaging smoke, Release Check, Full Review, and `git diff --check`",
        "Windows EXE, installer, portable package, first-run setup, install/run smoke, dependency checker, config wizard, Agent task smoke, output verification, guides, checksums, and release artifact manifest",
        "Campaigns 1-9 accepted, final sync complete",
    ]:
        assert marker in matrix


def test_target_acceptance_matrix_records_campaign_3_2_0_supplement_without_opening_campaign_4():
    matrix = _read(MATRIX)

    for marker in [
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
    ]:
        assert marker in matrix


def test_campaign_stage_gate_policy_requires_closure_upload_tag_ci_before_campaign_4():
    combined = "\n".join([_read(POLICY), _read(MATRIX), _read(INTEGRATED_CLOSURE_POLICY)])

    for marker in [
        "Campaign 1-3 Stage Test Gate may start only after Supplement 4.0 acceptance and the Campaign 3 Final Consistency Gate pass",
        "Campaign 1-3 Integrated Closure Gate may start only after Stage Test Gate is green",
        "Closure Pack generation, Repository Public Surface Cleanup / Rename / Push-Tag Safety Gate, repository push, tag creation, CI/CL green verification, Closure Checklist green verification, and Campaign 1-3 Integrated Review and New Conversation Handoff Gate must run in that order before Campaign 4 Goal-Oriented Product UI Workbench Entry Gate",
        "Campaign 4 cannot open until every Section 5 item",
        "Closure Pack generation",
        "Repository Public Surface Cleanup / Rename / Push-Tag Safety Gate",
        "repository push",
        "closure tag creation",
        "tag-related CI/CL green verification",
        "Closure Checklist green verification",
        "Campaign 1-3 Integrated Review and New Conversation Handoff Gate",
        "Campaign 3 Supplement 4.0 is not Campaign 4",
        "Campaign 4 is not `4.0`",
        "Any test, closure, repository cleanup, push, tag, or CI failure must stop",
    ]:
        assert marker in combined
