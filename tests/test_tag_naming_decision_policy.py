from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
GOVERNANCE = ROOT / "docs" / "governance"
REPORT = GOVERNANCE / "TAG_NAMING_DECISION_REPORT.md"
CLOSURE_POLICY = GOVERNANCE / "CAMPAIGN_1_2_3_INTEGRATED_CLOSURE_POLICY.md"
REPO_SURFACE_PLAN = GOVERNANCE / "REPOSITORY_PUBLIC_SURFACE_CLEANUP_RENAME_PUSH_TAG_SAFETY_GATE_PLAN.md"
STAGE_POLICY = GOVERNANCE / "CAMPAIGN_STAGE_GATE_POLICY.md"
PLAN_LOCK = GOVERNANCE / "PLAN_SEQUENCE_LOCK.md"


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8-sig")


def test_tag_naming_decision_report_records_superseded_validation_tags():
    text = _read(REPORT)

    for marker in [
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
    ]:
        assert marker in text


def test_campaign_baseline_tags_are_separate_from_product_version_tags():
    combined = "\n".join([
        _read(REPORT),
        _read(CLOSURE_POLICY),
        _read(REPO_SURFACE_PLAN),
    ])

    for marker in [
        "campaign-1-3-baseline-rc.1",
        "campaign-1-3-baseline-rc.2",
        "campaign-1-3-baseline",
        "Product version tags remain reserved for real product releases",
        "`v4.2.x`",
        "`v4.3.x`",
        "not final releases",
        "not product version releases",
        "not Campaign 4 completion",
    ]:
        assert marker in combined


def test_sequence_lock_uses_campaign_baseline_rc_tag_before_ci():
    combined = "\n".join([
        _read(CLOSURE_POLICY),
        _read(STAGE_POLICY),
        _read(PLAN_LOCK),
    ])

    for marker in [
        "repository push",
        "campaign baseline RC tag creation",
        "CI/CL green verification",
        "Closure Checklist green verification",
        "Campaign 1-3 Integrated Review and New Conversation Handoff Gate",
        "Campaign 4 Goal-Oriented Product UI Workbench Entry Gate",
        "attempted tag uses the superseded `v3.0.x-integrated-closure` naming pattern",
    ]:
        assert marker in combined
