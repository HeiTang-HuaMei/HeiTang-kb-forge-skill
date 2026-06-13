from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
GOVERNANCE = ROOT / "docs" / "governance"
PLAN_LOCK = GOVERNANCE / "PLAN_SEQUENCE_LOCK.md"
MATRIX = GOVERNANCE / "TARGET_ACCEPTANCE_MATRIX.md"
TARGET_PLAN = GOVERNANCE / "TARGET_MODE_ACCEPTANCE_PLAN.md"
CAMPAIGN_POLICY = GOVERNANCE / "CAMPAIGN_STAGE_GATE_POLICY.md"
PRE_CAMPAIGN_GATE = GOVERNANCE / "PRE_CAMPAIGN_ACCEPTANCE_GATE.md"
INTEGRATED_CLOSURE_POLICY = GOVERNANCE / "CAMPAIGN_1_2_3_INTEGRATED_CLOSURE_POLICY.md"
PRE_4_0_PLAN = GOVERNANCE / "PRE_4_0_WORKSPACE_PARTITION_FOUNDATION_GATE_PLAN.md"
CAMPAIGN_4_9_REPLACEMENT_PLAN = GOVERNANCE / "CAMPAIGN_4_9_REPLACEMENT_PLAN.md"
CAMPAIGN_4_5_REPLACEMENT_PLAN = GOVERNANCE / "CAMPAIGN_4_5_REPLACEMENT_PLAN.md"
PROJECT_AGENTS = ROOT / "AGENTS.md"
CONTROL_INDEX = GOVERNANCE / "PROJECT_CONTROL_INDEX.md"
VALIDATION_MANIFEST = ROOT / "docs" / "testing" / "VALIDATION_GATE_MANIFEST.json"


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def test_plan_sequence_lock_files_exist_and_are_indexed():
    assert PLAN_LOCK.exists()
    assert MATRIX.exists()

    agents = _read(PROJECT_AGENTS)
    index = _read(CONTROL_INDEX)
    manifest = _read(VALIDATION_MANIFEST)

    for marker in [
        "docs/governance/PLAN_SEQUENCE_LOCK.md",
        "docs/governance/CAMPAIGN_STAGE_GATE_POLICY.md",
        "docs/governance/PRE_CAMPAIGN_ACCEPTANCE_GATE.md",
        "docs/governance/TARGET_ACCEPTANCE_MATRIX.md",
        "docs/governance/CAMPAIGN_3_0_EXTERNAL_SOURCE_MEMORY_VERIFICATION_PLAN.md",
        "docs/governance/CAMPAIGN_1_2_3_INTEGRATED_CLOSURE_POLICY.md",
        "docs/governance/REPOSITORY_PUBLIC_SURFACE_CLEANUP_RENAME_PUSH_TAG_SAFETY_GATE_PLAN.md",
        "docs/governance/PRE_4_0_WORKSPACE_PARTITION_FOUNDATION_GATE_PLAN.md",
        "docs/governance/CAMPAIGN_4_9_REPLACEMENT_PLAN.md",
        "docs/governance/CAMPAIGN_4_5_REPLACEMENT_PLAN.md",
    ]:
        assert marker in agents
        assert marker in index
        assert marker in manifest

    assert "tests/test_plan_sequence_lock.py" in manifest


def test_remaining_gap_cannot_override_plan_sequence():
    lock = _read(PLAN_LOCK)

    for marker in [
        "12-section target plan is the execution-order source of truth",
        "GOAL_ACCEPTANCE_LEDGER.json` records capability status and evidence",
        "does not decide the next task",
        "remaining_gap` entry may explain risk, but it cannot override",
        "Current required advance",
        "5. 第三战役",
        "Campaign 3 active: `true`",
        "Campaign 3 accepted: `false`",
    ]:
        assert marker in lock


def test_campaign_3_sequence_completed_internal_foundations_and_next_item_is_acceptance_gate():
    lock = _read(PLAN_LOCK)
    matrix = _read(MATRIX)

    assert "Current supplement: Campaign 3 Supplement 4.0 Knowledge-to-Skill-to-Agent Package & Product Handoff Contract" in lock
    assert "Campaign 3 2.0 supplements Section 5" in lock
    assert "Campaign 3 2.0 supplements Section 5" in lock
    assert "It does not alter Campaign 1, Campaign 2, Campaign 4, or the 12-section total plan" in lock

    for text in [lock, matrix]:
        assert "Section 5" in text
        assert "Campaign 3" in text
    assert "accepted_for_campaign_3_final_consistency_gate" in lock
    assert "supplement_4_0_accepted_for_final_consistency_gate" in matrix

    for text in [lock]:
        assert "5.6 skill-prompt-generator" in text
        assert "5.7 ai-marketing-skills" in text
        assert "5.8 ai-money-maker-handbook" in text
        assert "5.9 Jellyfish" in text
        assert "5.10 story-flicks" in text
        assert "5.11 seedance2-skill" in text
        assert "5.12 RAG-Anything" in text
        assert "5.13 mattpocock/skills" in text
        assert "5.14 Sirchmunk" in text

    assert "Campaign 3 items 5.1 LLM Wiki v2 through 5.14 Sirchmunk plus strengthening records 5.S1 through 5.S3" in matrix
    assert "Campaign 3 Supplement 2.0 closure gate" in matrix
    assert "Supplement 3.0 Entry Gate" in matrix
    assert "Unified Trace / Evidence / Progress / Failure Isolation" in matrix
    assert "one project at a time" in lock or "one project at a time" in _read(CAMPAIGN_POLICY)

    assert "Next Section 5 item: `Campaign 3 Final Consistency Gate only`" in lock
    assert "Campaign 3 item 5.7 advanced: `true`" in lock
    assert "Campaign 3 item 5.8 advanced: `true`" in lock
    assert "Campaign 3 item 5.9 advanced: `true`" in lock
    assert "Campaign 3 item 5.10 advanced: `true`" in lock
    assert "Campaign 3 item 5.11 advanced: `true`" in lock
    assert "Campaign 3 item 5.12 advanced: `true`" in lock
    assert "Campaign 3 item 5.13 advanced: `true`" in lock
    assert "Campaign 3 item 5.14 advanced: `true`" in lock
    assert "Campaign 3 strengthening item 5.S1 advanced: `true`" in lock
    assert "Campaign 3 strengthening item 5.S2 advanced: `true`" in lock
    assert "Campaign 3 strengthening item 5.S3 advanced: `true`" in lock
    assert "Campaign 3 Supplement 2.0 closure gate passed: `true`" in lock
    assert "Campaign 3 Supplement 3.0 entry gate passed: `true`" in lock
    assert "Campaign 3 Supplement 3.0 P0 framework passed: `true`" in lock
    assert "Campaign 3 Supplement 3.0 P0 Generic Web URL Ingestion passed: `true`" in lock
    assert "Campaign 3 Supplement 3.0 P0 Platform Link Preflight passed: `true`" in lock
    assert "Campaign 3 Supplement 3.0 P0 OpenCLI External Search Verification passed: `true`" in lock
    assert "Campaign 3 Supplement 3.0 P0 Manual Evidence Upload passed: `true`" in lock
    assert "Campaign 3 Supplement 3.0 P1 Video-to-Knowledge and Visual Evidence Understanding foundations passed: `true`" in lock
    assert "Campaign 3 Supplement 3.0 P1 Knowledge Verification Engine and dashboard foundations passed: `true`" in lock
    assert "Campaign 3 Supplement 3.0 plan state: `accepted_stop_pre_4_0_next`" in lock
    assert "Campaign 3 Supplement 3.0 acceptance gate passed: `true`" in lock
    assert "Campaign 3 Supplement 3.0 accepted: `true`" in lock


def test_campaign_1_and_2_acceptance_reviews_gate_campaign_3():
    combined = "\n".join([_read(PLAN_LOCK), _read(MATRIX), _read(PRE_CAMPAIGN_GATE)])

    assert "Campaign 1 accepted: `true`" in combined
    assert "Campaign 2 accepted: `true`" in combined
    assert "Campaign 3 active: `true`" in combined
    assert "Campaign 3 accepted: `false`" in combined
    assert "Campaign 1 must be `accepted` before Campaign 3 can become active" in combined
    assert "Campaign 2 must be `accepted` before Campaign 3 can become active" in combined


def test_absorbed_sources_must_not_be_redone_without_compatibility_break():
    combined = "\n".join([_read(PLAN_LOCK), _read(MATRIX), _read(TARGET_PLAN)])

    for source in [
        "Anything2Skill",
        "SkillX",
        "Anthropic skill-creator",
        "P2.2 Skill Governance / Skill Suite",
    ]:
        assert source in combined

    assert "Do not redo" in combined
    assert "unless DU/KB compatibility tests explicitly break" in combined


def test_ui_core_bridge_config_and_exe_cannot_be_completed_early():
    matrix = _read(MATRIX)
    lock = _read(PLAN_LOCK)

    for marker in [
        "UI is not complete",
        "Core Bridge is not complete",
        "API/proxy configuration is not complete",
        "DB/Redis/vector DB configuration is not complete",
        "Full Testing / Full Review is not complete",
        "EXE packaging is not complete",
        "Final release is not allowed",
    ]:
        assert marker in matrix

    for marker in [
        "UI, Core Bridge, Agent Runtime/Memory, configuration, Full Testing / Full Review, and EXE work cannot be marked complete",
        "full goal-oriented desktop workflow evidence",
        "no arbitrary shell execution",
        "build, install, launch, first-run setup",
    ]:
        assert marker in lock


def test_strong_gate_sequence_lock_applies_to_later_campaigns():
    lock = _read(PLAN_LOCK)
    policy = _read(CAMPAIGN_POLICY)
    matrix = _read(MATRIX)
    combined = "\n".join([lock, policy, matrix])

    for marker in [
        "The same Entry Gate, Acceptance Gate, and Transition Gate mechanism applies after Campaign 3",
        "Campaign 4 cannot become active while Campaign 3 is `in_progress`",
        "Campaign 4 is `Goal-Oriented Product UI Workbench`",
        "Campaign 5 cannot become active from UI action entries or status cards",
        "Campaign 5 is `Chain-Level Local Core Bridge`",
        "TasteSkill and Product Design Plugin are Campaign 4.x enhancement backlog candidates only",
        "UI redesign and future Campaign Bridge allowlist changes are forbidden before CI/CL green",
        "Campaign 6 is `Agent Runtime & Memory Platform` and cannot become active from Core Bridge allowlist presence",
        "Campaign 7 is `Configuration System` and cannot become active from Agent Runtime or memory specs alone",
        "Campaign 8 is `Full Testing / Full Review` and cannot become active from configuration schema or settings files alone",
        "Campaign 9 is `EXE Packaging` and cannot become active from focused tests, Fast Gate, scoped tests, or partial packaging smoke",
        "Final Release cannot become active from a packaging script or local artifact alone",
        "`remaining_gap` and capability statuses in `GOAL_ACCEPTANCE_LEDGER.json` cannot override these transitions",
    ]:
        assert marker in combined


def test_campaign_3_2_0_extends_section_5_without_changing_total_plan():
    lock = _read(PLAN_LOCK)
    matrix = _read(MATRIX)
    policy = _read(CAMPAIGN_POLICY)
    combined = "\n".join([lock, matrix, policy])

    for marker in [
        "Campaign 3 2.0 is a supplement to Section 5, not a total-plan rewrite",
        "5.14 Sirchmunk",
        "5.S1 GBrain strengthening",
        "5.S2 Horizon strengthening",
        "5.S3 Obsidian-compatible Vault strengthening",
        "Campaign 3 final consistency gate",
        "5.S items did not interrupt or reorder the main line",
        "do not change the 12-section total plan",
        "Campaign 4 cannot open until every Section 5 item",
    ]:
        assert marker in combined


def test_campaign_3_3_0_is_inserted_after_2_0_without_changing_total_plan():
    lock = _read(PLAN_LOCK)
    matrix = _read(MATRIX)
    policy = _read(CAMPAIGN_POLICY)
    combined = "\n".join([lock, matrix, policy])

    for marker in [
        "Campaign 3 3.0 is a new Section 5 supplement, not a total-plan rewrite",
        "Campaign 3 Supplement 3.0 entry gate passed: `true`",
        "Campaign 3 Supplement 3.0 P0 framework passed: `true`",
        "Campaign 3 Supplement 3.0 plan state: `accepted_stop_pre_4_0_next`",
        "Campaign 3 Supplement 2.0 closure gate",
        "Campaign 3 Supplement 3.0 External Source Memory & Verification",
        "the Supplement 2.0 closure gate already passed",
        "Campaign 4 cannot become active from Campaign 3 2.0 or 3.0 completion alone",
        "expanded Campaign 3 final consistency gate",
    ]:
        assert marker in combined

    assert "Campaign 3 Supplement 3.0 P0 Generic Web URL Ingestion passed: `true`" in lock
    assert "Campaign 3 Supplement 3.0 P0 Platform Link Preflight passed: `true`" in lock
    assert "Campaign 3 Supplement 3.0 P0 OpenCLI External Search Verification passed: `true`" in lock
    assert "Campaign 3 Supplement 3.0 P0 Manual Evidence Upload passed: `true`" in lock
    assert "Campaign 3 Supplement 3.0 P0 unified Source Trace / Evidence Map, progress events, and failure isolation passed: `true`" in lock
    assert "Campaign 3 Supplement 3.0 P1 Authenticated Browser Connector Alpha passed: `true`" in lock
    assert "Campaign 3 Supplement 3.0 P1 Video-to-Knowledge and Visual Evidence Understanding foundations passed: `true`" in lock
    assert "Campaign 3 Supplement 3.0 P1 Knowledge Verification Engine and dashboard foundations passed: `true`" in lock
    assert "Next Section 5 item: `Campaign 3 Final Consistency Gate only`" in lock
    assert "Pre-4.0 Workspace Partition Foundation Gate passed: `true`" in lock
    assert "Campaign 3 Supplement 3.0 accepted: `true`" in lock
    assert "Campaign 3 Supplement 4.0 accepted: `true`" in lock
    assert "Campaign 4 allowed: `false`" in lock


def test_campaign_3_4_0_is_inserted_after_3_0_without_changing_total_plan():
    lock = _read(PLAN_LOCK)
    matrix = _read(MATRIX)
    policy = _read(CAMPAIGN_POLICY)
    combined = "\n".join([lock, matrix, policy])

    for marker in [
        "Campaign 3 4.0 is a new Section 5 supplement, not a total-plan rewrite",
        "Campaign 3 Supplement 4.0 plan state: `accepted_for_campaign_3_final_consistency_gate`",
        "Campaign 3 Supplement 3.0 Acceptance Gate",
        "Campaign 3 Supplement 4.0 Knowledge-to-Skill-to-Agent Package & Product Handoff Contract",
        "Generation always starts as `draft`",
        "only explicit user confirmation may establish publish-ready or published state",
        "`visual_video_skill` is one subtype among seven",
        "expanded Campaign 3 final consistency gate",
        "Campaign 3 Supplement 4.0 is not Campaign 4",
        "Campaign 4 is not 4.0",
    ]:
        assert marker in combined

    assert "Campaign 3 Supplement 4.0 entry gate passed: `true`" in lock
    assert "Campaign 3 Supplement 4.0B Knowledge-to-Skill Template Generator passed: `true`" in lock
    assert "Campaign 3 Supplement 4.0C Skill Import & Dedicated Skill Composer passed: `true`" in lock
    assert "4.0A Entry Reconciliation Gate over 3.0 verification outputs" in lock
    assert "bounded industrial-grade entry gate only" in lock
    assert "Campaign 3 Supplement 4.0D-I Product Handoff Contract Bundle passed: `true`" in lock
    assert "Campaign 3 Supplement 4.0 acceptance gate passed: `true`" in lock
    assert "Campaign 3 Supplement 4.0 accepted: `true`" in lock
    assert "Campaign 4 allowed: `false`" in lock


def test_post_3_0_closure_chain_requires_supplement_4_0_before_campaign_4():
    combined = "\n".join(
        [
            _read(PLAN_LOCK),
            _read(MATRIX),
            _read(CAMPAIGN_POLICY),
            _read(INTEGRATED_CLOSURE_POLICY),
        ]
    )

    for marker in [
        "Run Pre-4.0 Workspace Partition & Knowledge Base Access Scope Foundation Gate only.",
        "Campaign 3 Supplement 4.0 Knowledge-to-Skill-to-Agent Package & Product Handoff Contract",
        "Campaign 3 Final Consistency Gate",
        "Run Campaign 1-3 Stage Test Gate only.",
        "Campaign 1-3 Stage Test Gate",
        "Campaign 1-3 Integrated Closure Gate",
        "Repository Public Surface Cleanup / Rename / Push-Tag Safety Gate",
        "Repository push",
        "Tag creation",
        "CI/CL green",
        "Campaign 1-3 Integrated Review and New Conversation Handoff Gate",
        "Campaign 4 Goal-Oriented Product UI Workbench Entry Gate",
        "Campaign 1-3 Stage Test Gate cannot start immediately after Supplement 3.0",
        "Failure at any test, closure, pack, repository cleanup, push, tag, CI, Closure Checklist, or Campaign 1-3 Integrated Review / Handoff step must stop",
    ]:
        assert marker in combined

    assert "Campaign 3 Final Consistency Gate passed: `false`" in combined
    assert "Campaign 1-3 Stage Test Gate passed: `false`" in combined
    assert "Campaign 1-3 Integrated Closure Gate passed: `false`" in combined
    assert "Repository Public Surface Cleanup / Rename / Push-Tag Safety Gate passed: `false`" in combined
    assert "Repository push succeeded: `false`" in combined
    assert "Campaign 1-3 closure CI green: `false`" in combined


def test_campaign_4_9_replacement_plan_does_not_change_current_next_item():
    combined = "\n".join(
        [
            _read(PLAN_LOCK),
            _read(MATRIX),
            _read(CAMPAIGN_POLICY),
            _read(PRE_4_0_PLAN),
            _read(CAMPAIGN_4_9_REPLACEMENT_PLAN),
            _read(CAMPAIGN_4_5_REPLACEMENT_PLAN),
        ]
    )

    for marker in [
        "Goal-Oriented Product UI Workbench",
        "Chain-Level Local Core Bridge",
        "This replacement is governance registration only",
        "does not enter Campaigns 4-9",
        "does not change the current Campaign 3 task state",
        "Before CI/CL green",
        "TasteSkill",
        "Product Design Plugin",
        "UI redesign",
        "Bridge allowlist changes",
        "Campaign 3 Supplement 3.0 Acceptance Gate",
    ]:
        assert marker in combined


def test_target_acceptance_matrix_covers_all_12_sections_and_status_classes():
    matrix = _read(MATRIX)

    for section in [
        "1. 总目标验收标准",
        "2. 执行总规则",
        "3. 第一战役",
        "4. 第二战役",
        "5. 第三战役",
        "6. 第四战役",
        "7. 第五战役",
        "8. 第六战役",
        "9. 第七战役",
        "10. 第八战役",
        "11. 第九战役",
        "Final Release",
        "12. 禁止事项",
    ]:
        assert section in matrix

    for status in [
        "accepted",
        "partially_complete",
        "not_complete",
        "not_allowed_yet",
        "allowed_next_not_active",
        "absorbed_do_not_redo",
    ]:
        assert status in matrix


def test_target_acceptance_matrix_declares_required_plan_state_buckets():
    matrix = _read(MATRIX)

    for bucket in [
        "已证明完成",
        "部分完成",
        "未完成",
        "不得提前推进",
        "已吸收不得重做",
    ]:
        assert bucket in matrix

    for marker in [
        "Section 3 / Campaign 1 backend strengthening acceptance review",
        "Section 4 / Campaign 2 batch import and knowledge supply-chain acceptance review",
        "strengthening records 5.S1 through 5.S3",
        "Campaign 3 Supplement 2.0 closure gate",
        "Campaign 3 Supplement 3.0",
        "Campaign 3 Supplement 4.0",
        "expanded Campaign 3 final consistency gate",
        "Sections 6, 7, 8, 9, 10, and 11",
        "until Section 5 and their prerequisites are complete",
        "unless DU/KB compatibility tests explicitly break",
    ]:
        assert marker in matrix
