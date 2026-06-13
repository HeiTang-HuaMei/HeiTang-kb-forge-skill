import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
GOVERNANCE = ROOT / "docs" / "governance"
PLAN = GOVERNANCE / "PRE_4_0_WORKSPACE_PARTITION_FOUNDATION_GATE_PLAN.md"
LOCK = GOVERNANCE / "PLAN_SEQUENCE_LOCK.md"
MATRIX = GOVERNANCE / "TARGET_ACCEPTANCE_MATRIX.md"
LEDGER = GOVERNANCE / "GOAL_ACCEPTANCE_LEDGER.json"


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def test_pre_4_0_gate_is_passed_between_supplements_3_0_and_4_0():
    combined = "\n".join([_read(PLAN), _read(LOCK), _read(MATRIX)])

    for marker in [
        "Campaign 3 Supplement 3.0 Acceptance Gate",
        "Pre-4.0 Workspace Partition & Knowledge Base Access Scope Foundation Gate",
        "Campaign 3 Supplement 4.0 Knowledge-to-Skill-to-Agent Package & Product Handoff Contract",
        "Supplement 3.0 is accepted",
        "has passed as a foundation contract",
        "Supplement 4.0 business implementation must not start until its Entry Reconciliation Gate runs",
    ]:
        assert marker in combined


def test_pre_4_0_foundation_gate_does_not_claim_runtime_or_later_campaigns():
    text = _read(PLAN)

    for marker in [
        "Plan state: `passed_foundation_contract`",
        "Campaign 4 active: `false`",
        "Campaign 5 active: `false`",
        "Supplement 4.0 active: `false`",
        "pre_4_0_workspace_partition_complete = true",
        "kb_access_scope_ready = true",
        "workspace_partition_runtime_enforcement_ready = false",
        "kb_access_scope_runtime_enforcement_ready = false",
        "agent_runtime_ready = false",
        "campaign_4_ui_complete = false",
        "campaign_5_bridge_complete = false",
        "future_bridge_action_added_to_current_allowlist = false",
        "not_goal_complete = true",
    ]:
        assert marker in text


def test_pre_4_0_ledger_record_is_passed_foundation_contract_after_3_0_acceptance():
    ledger = json.loads(LEDGER.read_text(encoding="utf-8"))
    review = ledger["campaign_acceptance_reviews"][
        "pre_4_0_workspace_partition_foundation_gate"
    ]

    assert review["status"] == "accepted"
    assert review["plan_state"] == "passed_foundation_contract"
    assert review["next_business_item"] == "Campaign 3 Supplement 4.0B Verified Knowledge-to-Skill Template passed; next is Campaign 3 Supplement 4.0C Skill Import & Dedicated Skill Composer only"
    assert review["activation_prerequisites"] == [
        "Campaign 3 Supplement 3.0 accepted"
    ]
    assert review["pre_4_0_workspace_partition_complete"] is True
    assert review["workspace_manifest_ready"] is True
    assert review["kb_access_scope_ready"] is True
    assert review["campaign_4_active"] is False
    assert review["campaign_5_active"] is False
