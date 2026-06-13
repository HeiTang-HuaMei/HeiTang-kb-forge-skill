from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
GOVERNANCE = ROOT / "docs" / "governance"
COMPAT_PLAN = GOVERNANCE / "CAMPAIGN_4_5_REPLACEMENT_PLAN.md"
AUTHORITY_PLAN = GOVERNANCE / "CAMPAIGN_4_9_REPLACEMENT_PLAN.md"


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def test_campaign_4_5_replacement_file_is_compatibility_pointer_only():
    text = _read(COMPAT_PLAN)

    for marker in [
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
    ]:
        assert marker in text


def test_campaign_4_9_replacement_plan_is_authority_for_future_campaigns():
    assert AUTHORITY_PLAN.exists()
    authority = _read(AUTHORITY_PLAN)

    for marker in [
        "Campaign 4-9 Replacement Plan v3.0",
        "Campaign 4 | Goal-Oriented Product UI Workbench",
        "Campaign 5 | Chain-Level Local Core Bridge",
        "Campaign 6 | Agent Runtime & Memory Platform",
        "Campaign 7 | Configuration System",
        "Campaign 8 | Full Testing / Full Review",
        "Campaign 9 | EXE Packaging",
        "Final Release",
    ]:
        assert marker in authority
