from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
GOVERNANCE = ROOT / "docs" / "governance"
PLAN = GOVERNANCE / "CAMPAIGN_3_0_EXTERNAL_SOURCE_MEMORY_VERIFICATION_PLAN.md"
SEQUENCE = GOVERNANCE / "PLAN_SEQUENCE_LOCK.md"
MATRIX = GOVERNANCE / "TARGET_ACCEPTANCE_MATRIX.md"
POLICY = GOVERNANCE / "CAMPAIGN_STAGE_GATE_POLICY.md"


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def test_campaign_3_0_plan_records_acceptance_without_later_activation():
    text = _read(PLAN)

    for marker in [
        "without changing the user-approved 12-section total plan",
        "Plan state: `accepted_stop_pre_4_0_next`",
        "Current business item: `STOP before Campaign 3 Supplement 4.0 Entry Reconciliation Gate`",
        "Campaign 3 accepted: `true`",
        "Campaign 4 allowed: `false`",
        "Authenticated Browser Connector Alpha",
        "`supplement_3_0_complete=true`",
        "`campaign_4_active`, `campaign_5_active`",
        "`bridge_execution_accepted` remain `false",
    ]:
        assert marker in text


def test_campaign_3_0_starts_after_all_campaign_3_2_0_remaining_work():
    combined = "\n".join([_read(PLAN), _read(SEQUENCE), _read(MATRIX), _read(POLICY)])

    ordered_markers = [
        "5.11 seedance2-skill",
        "5.12 RAG-Anything",
        "5.13 mattpocock/skills",
        "5.14 Sirchmunk",
        "5.S1 GBrain strengthening",
        "5.S2 Horizon strengthening",
        "5.S3 Obsidian-compatible Vault strengthening",
        "Campaign 3 Supplement 2.0 closure gate",
        "Campaign 3 Supplement 3.0 External Source Memory & Verification",
        "Campaign 3 Supplement 4.0 Knowledge-to-Skill-to-Agent Package & Product Handoff Contract",
        "Campaign 3 final consistency gate",
        "Campaign 1-3 Stage Test Gate",
        "Campaign 1-3 Integrated Closure Gate",
        "Repository Public Surface Cleanup / Rename / Push-Tag Safety Gate, repository push, tag, and CI/CL green verification",
        "Campaign 4 Goal-Oriented Product UI Workbench",
    ]

    for marker in ordered_markers:
        assert marker in combined

    assert "Supplement 3.0 is inserted after the passed Supplement 2.0 closure gate" in combined
    assert "The P0 framework, Generic Web URL Ingestion, Platform Link Preflight, OpenCLI External Search Verification, Manual Evidence Upload" in combined
    assert "Knowledge Verification Engine/dashboard foundations have passed" in combined
    assert "Execution stops before Campaign 3 Supplement 4.0 Entry Reconciliation Gate" in combined
    assert "After Supplement 3.0 acceptance, do not run Campaign 1-3 total closure directly" in combined
    assert "Campaign 3 Supplement 4.0 may start only after the Pre-4.0 Workspace Partition Foundation Gate passes" in combined


def test_campaign_3_0_covers_ingestion_verification_visual_and_browser_boundaries():
    text = _read(PLAN)

    for marker in [
        "Link-to-Knowledge Ingestion",
        "Generic Web URL Ingestion",
        "Platform Link Preflight",
        "OpenCLI External Search Verification",
        "Authenticated Browser Connector",
        "Manual Evidence Upload",
        "Video-to-Knowledge Ingestion",
        "Visual Evidence Understanding",
        "Knowledge Verification Engine",
        "source_trace",
        "evidence_map",
        "content_hash",
        "timestamp trace",
        "image trace",
        "progress events",
        "failure isolation",
        "External Link Import entry",
        "real Core Bridge allowlist registrations",
    ]:
        assert marker in text

    for forbidden_boundary in [
        "Do not bypass login",
        "Do not bypass paywalls",
        "Do not bypass CAPTCHA",
        "Do not save or upload user cookies",
        "Do not provide cookie import",
        "Do not implement an unlimited crawler",
        "Arbitrary shell execution is forbidden",
    ]:
        assert forbidden_boundary in text


def test_campaign_3_0_locks_required_states_metadata_and_defaults():
    text = _read(PLAN)

    for state in [
        "public_readable",
        "partial_readable",
        "login_required",
        "anti_crawl_detected",
        "needs_manual_evidence",
        "user_authorized_session",
        "session_expired",
        "verified",
        "partially_verified",
        "unsupported",
        "outdated",
        "conflicting",
        "low_confidence",
        "needs_human_review",
    ]:
        assert f"`{state}`" in text

    for chunk_type in [
        "text",
        "image_ocr",
        "video_segment",
        "video_keyframe_ocr",
        "table_ocr",
        "layout_block",
        "mixed_multimodal",
    ]:
        assert chunk_type in text

    for default in [
        "url_depth = 0",
        "max_pages = 1",
        "same_domain_only = true",
        "timeout = 30s",
        "respect_robots = true",
    ]:
        assert default in text


def test_campaign_3_0_acceptance_cannot_be_substituted_by_contract_or_ui_entry():
    text = _read(PLAN)

    for marker in [
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
    ]:
        assert marker in text
