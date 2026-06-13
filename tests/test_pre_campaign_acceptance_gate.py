import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
GOVERNANCE = ROOT / "docs" / "governance"
PRE_GATE = GOVERNANCE / "PRE_CAMPAIGN_ACCEPTANCE_GATE.md"
PLAN_LOCK = GOVERNANCE / "PLAN_SEQUENCE_LOCK.md"
LEDGER = GOVERNANCE / "GOAL_ACCEPTANCE_LEDGER.json"
CAMPAIGN_1_MATRIX = ROOT / "artifacts" / "audits" / "backend_remediation_acceptance_review" / "backend_remediation_acceptance_matrix.json"
CAMPAIGN_2_MATRIX = ROOT / "artifacts" / "audits" / "knowledge_supply_chain_acceptance_review" / "campaign_2_acceptance_matrix.json"


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def _ledger() -> dict:
    return json.loads(LEDGER.read_text(encoding="utf-8"))


def test_pre_campaign_gate_requires_campaign_1_and_2_acceptance():
    text = _read(PRE_GATE)

    for marker in [
        "Campaign 1 must be `accepted` before Campaign 3 can become active",
        "Campaign 2 must be `accepted` before Campaign 3 can become active",
        "Campaign 3 is allowed next only when both previous reviews are accepted",
        "`GOAL_ACCEPTANCE_LEDGER.json` records status only and does not decide order",
        "`PLAN_SEQUENCE_LOCK.md` decides the plan sequence",
        "`TARGET_ACCEPTANCE_MATRIX.md` decides acceptance conditions",
    ]:
        assert marker in text


def test_pre_campaign_gate_records_allowed_next_and_current_active_state():
    text = _read(PRE_GATE)
    ledger = _ledger()
    review = ledger["campaign_acceptance_reviews"]["pre_campaign_acceptance_gate"]

    assert "Campaign 3 allowed next: `yes`" in text
    assert "Campaign 3 active now: `yes`" in text
    assert "Campaign 3 accepted now: `no_until_final_consistency_gate`" in text
    assert review["status"] == "accepted"
    assert review["campaign_3_allowed_next"] is True
    assert review["campaign_3_active"] is True
    assert review["next_allowed_campaign"] == "Section 5 / Campaign 3"


def test_campaign_3_is_not_entered_when_any_previous_campaign_is_not_accepted():
    campaign_1 = json.loads(CAMPAIGN_1_MATRIX.read_text(encoding="utf-8"))
    campaign_2 = json.loads(CAMPAIGN_2_MATRIX.read_text(encoding="utf-8"))

    def can_enter(c1: str, c2: str) -> bool:
        return c1 == "accepted" and c2 == "accepted"

    assert can_enter(campaign_1["verdict"], campaign_2["verdict"]) is True
    assert can_enter("partial", campaign_2["verdict"]) is False
    assert can_enter(campaign_1["verdict"], "partial") is False
    assert can_enter("failed", "accepted") is False


def test_plan_lock_says_pre_4_0_passed_and_supplement_4_0_entry_is_next():
    text = _read(PLAN_LOCK)

    for marker in [
        "Current campaign: Campaign 3 project-by-project processing",
        "Current completed Section 5 items: `5.1 LLM Wiki v2`, `5.2 WeKnora`, `5.3 AnySearchSkill`, `5.4 n8n`, `5.5 MMSkills`, `5.6 skill-prompt-generator`, `5.7 ai-marketing-skills`, `5.8 ai-money-maker-handbook`, `5.9 Jellyfish`, `5.10 story-flicks`, `5.11 seedance2-skill`, `5.12 RAG-Anything`, `5.13 mattpocock/skills`, `5.14 Sirchmunk`, `5.S1 GBrain`, `5.S2 Horizon`, `5.S3 Obsidian-compatible Vault`",
        "Next business item: `Campaign 3 Final Consistency Gate only`",
        "Campaign 3 active: `true`",
        "Campaign 3 accepted: `false`",
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
        "Completed entry gate: Campaign 3 Supplement 4.0 Entry Reconciliation Gate passed",
        "Next locked item: Campaign 3 Final Consistency Gate only",
        "Campaign 3 Supplement 3.0 entry gate passed: `true`",
        "Campaign 3 Supplement 3.0 P0 framework passed: `true`",
        "Campaign 3 Supplement 3.0 P0 Manual Evidence Upload passed: `true`",
        "Campaign 3 Supplement 3.0 plan state: `accepted_stop_pre_4_0_next`",
        "Campaign 3 Supplement 3.0 accepted: `true`",
        "Pre-4.0 Workspace Partition Foundation Gate passed: `true`",
    ]:
        assert marker in text


def test_pre_campaign_gate_records_3_0_acceptance_and_keeps_later_work_blocked():
    text = _read(PRE_GATE)

    for marker in [
        "completed Campaign 3 Supplement 3.0, its dedicated Acceptance Gate, the Pre-4.0 Workspace Partition Foundation Gate, Campaign 3 Supplement 4.0 Entry Reconciliation Gate, Campaign 3 Supplement 4.0B Verified Knowledge-to-Skill Template, Campaign 3 Supplement 4.0C Skill Import & Dedicated Skill Composer, Campaign 3 Supplement 4.0D-I Product Handoff Contract Bundle, and the Campaign 3 Supplement 4.0 Acceptance Gate",
        "Pre-4.0 accepts only workspace partition and KB access-scope foundation contracts",
        "4.0A accepts only a bounded industrial-grade entry gate",
        "4.0B accepts only a source-traced draft Skill Template plus validator/testcase evidence",
        "Supplement 4.0 Acceptance accepted Supplement 4.0 only",
        "PLAN_SEQUENCE_LOCK now permits only Campaign 3 Final Consistency Gate only",
    ]:
        assert marker in text


def test_pre_campaign_gate_blocks_later_campaigns_and_release():
    text = _read(PRE_GATE)

    for marker in [
        "Campaign 4 remains blocked until Campaign 3 is accepted",
        "Campaign 5 remains blocked until Campaign 4 is accepted",
        "Campaign 6 remains blocked until Campaign 5 is accepted",
        "Campaign 7 remains blocked until Campaign 6 is accepted",
        "Campaign 8 remains blocked until Campaign 7 is accepted",
        "Final Release remains blocked until Campaign 9 is accepted",
    ]:
        assert marker in text
