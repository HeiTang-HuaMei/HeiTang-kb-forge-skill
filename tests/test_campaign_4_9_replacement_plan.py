import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
GOVERNANCE = ROOT / "docs" / "governance"
PLAN = GOVERNANCE / "CAMPAIGN_4_9_REPLACEMENT_PLAN.md"
LOCK = GOVERNANCE / "PLAN_SEQUENCE_LOCK.md"
MATRIX = GOVERNANCE / "TARGET_ACCEPTANCE_MATRIX.md"
STAGE_GATE = GOVERNANCE / "CAMPAIGN_STAGE_GATE_POLICY.md"
CLOSURE = GOVERNANCE / "CAMPAIGN_1_2_3_INTEGRATED_CLOSURE_POLICY.md"
CONTROL_INDEX = GOVERNANCE / "PROJECT_CONTROL_INDEX.md"
PROJECT_AGENTS = ROOT / "AGENTS.md"
VALIDATION_MANIFEST = ROOT / "docs" / "testing" / "VALIDATION_GATE_MANIFEST.json"


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def test_replacement_plan_v3_exists_and_registers_campaigns_4_to_9():
    text = _read(PLAN)

    for marker in [
        "Campaign 4-9 Replacement Plan v3.0",
        "does not start any future campaign",
        "does not redesign UI",
        "does not change the current Campaign 3 task state",
        "does not change the Bridge allowlist",
        "Campaign 4 | Goal-Oriented Product UI Workbench",
        "Campaign 5 | Chain-Level Local Core Bridge",
        "Campaign 6 | Agent Runtime & Memory Platform",
        "Campaign 7 | Configuration System",
        "Campaign 8 | Full Testing / Full Review",
        "Campaign 9 | EXE Packaging",
        "Final Release | GitHub Release after Campaign 9 acceptance",
    ]:
        assert marker in text


def test_v3_preconditions_keep_campaign_4_blocked_until_closure_checklist_green():
    combined = "\n".join([_read(PLAN), _read(LOCK), _read(MATRIX), _read(STAGE_GATE), _read(CLOSURE)])

    for marker in [
        "Campaign 3 Supplement 3.0 External Source Memory & Verification complete",
        "Pre-4.0 Workspace Partition & Knowledge Base Access Scope Foundation Gate complete",
        "Campaign 3 Supplement 4.0 Knowledge-to-Skill-to-Agent Package & Product Handoff complete",
        "Campaign 3 Final Consistency Gate passed",
        "Campaign 1-3 Stage Test Gate passed",
        "Campaign 1-3 Integrated Closure passed",
        "Closure Pack generated",
        "Repository Public Surface Cleanup / Rename / Push-Tag Safety Gate passed",
        "Repository push succeeded",
        "Baseline Tag created",
        "GitHub CI Green",
        "Closure Checklist Green",
        "Campaign 4 Entry Gate",
    ]:
        assert marker in combined

    assert "Campaign 3 Supplement 4.0 Knowledge-to-Skill Template Generator implementation" in combined
    assert "Campaign 4 allowed: `false`" in combined


def test_campaign_4_is_product_workbench_not_runtime_or_bridge():
    text = _read(PLAN)

    for marker in [
        "Goal-Oriented Product UI Workbench",
        "not Bridge completion",
        "not Agent Runtime completion",
        "not EXE packaging",
        "Top-level navigation must have no more than seven entries",
        "Agent package spec is runtime ready",
        "Agent runtime is ready",
        "Multi-Agent spec is executable",
        "TasteSkill or Product Design Plugin is active base scope",
    ]:
        assert marker in text


def test_campaign_5_is_chain_bridge_and_excludes_runtime_actions():
    text = _read(PLAN)

    for marker in [
        "Chain-Level Local Core Bridge",
        "import_to_kb_flow",
        "external_source_verification_flow",
        "agent_package_generation_flow",
        "agent_output_verification_flow",
        "generate-agent",
        "validate-agent-package",
        "run-agent-task",
        "agent-memory-read",
        "belong to Campaign 6",
        "no arbitrary shell execution",
    ]:
        assert marker in text


def test_campaign_6_agent_runtime_memory_is_new_required_gate():
    combined = "\n".join([_read(PLAN), _read(MATRIX), _read(STAGE_GATE), _read(LOCK)])

    for marker in [
        "Campaign 6: Agent Runtime & Memory Platform",
        "simple_single_agent_mode_runtime",
        "advanced_single_agent_mode_runtime",
        "multi_agent_runtime_ready = false",
        "Agent A cannot read Agent B private memory",
        "Workspace A cannot read Workspace B data",
        "Redis config, or Vector DB config alone is not Agent Runtime & Memory acceptance",
        "Campaign 7 cannot open until `agent_runtime_memory_accepted = true`",
    ]:
        assert marker in combined


def test_campaign_7_8_9_and_release_are_locked_after_runtime():
    combined = "\n".join([_read(PLAN), _read(MATRIX), _read(STAGE_GATE), _read(LOCK)])

    for marker in [
        "Campaign 7: Configuration System",
        "check-agent-runtime",
        "check-agent-memory-backend",
        "check-opencli",
        "Campaign 8: Full Testing / Full Review",
        "Agent memory isolation tests",
        "Fast Gate, focused tests, scoped tests, or a single green command do not count",
        "Campaign 9: EXE Packaging",
        "real install or run smoke",
        "Final Release may start only after Campaign 9 acceptance",
        "Campaigns 1-9 accepted",
    ]:
        assert marker in combined


def test_v3_registration_is_indexed_and_routed_to_governance_gate():
    combined = "\n".join([_read(PROJECT_AGENTS), _read(CONTROL_INDEX), _read(VALIDATION_MANIFEST)])

    for marker in [
        "docs/governance/CAMPAIGN_4_9_REPLACEMENT_PLAN.md",
        "tests/test_campaign_4_9_replacement_plan.py",
    ]:
        assert marker in combined

    manifest = json.loads(VALIDATION_MANIFEST.read_text(encoding="utf-8"))
    governance_rule = next(rule for rule in manifest["impact_rules"] if rule["name"] == "test_governance")
    assert "docs/governance/CAMPAIGN_4_9_REPLACEMENT_PLAN.md" in governance_rule["patterns"]
    assert "tests/test_campaign_4_9_replacement_plan.py" in governance_rule["patterns"]
