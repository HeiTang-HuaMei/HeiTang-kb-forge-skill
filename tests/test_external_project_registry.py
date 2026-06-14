from pathlib import Path

from heitang_kb_forge.campaign_3_closure.review_handoff import (
    ALLOWED_INTEGRATION_STATUSES,
    _external_project_rows,
)


ROOT = Path(__file__).resolve().parents[1]
REVIEW = ROOT / "docs" / "治理" / "Campaign_1_3_外部项目集成审查.md"


MANDATORY_PROJECT_NAMES = {
    "LLM Wiki v2",
    "WeKnora",
    "AnySearchSkill",
    "n8n",
    "MMSkills",
    "skill-prompt-generator",
    "ai-marketing-skills",
    "ai-money-maker-handbook",
    "Jellyfish",
    "story-flicks",
    "seedance2-skill",
    "RAG-Anything",
    "mattpocock/skills",
    "Sirchmunk",
    "andrej-karpathy-skills",
    "Presenton",
    "CodeGraph",
    "Understand Anything",
    "NVlabs/LongLive",
    "claude-plugins-official",
    "pi-mono",
    "Redis / Vector DB / external database-backed Memory Store Connector",
}

REQUIRED_ROW_FIELDS = {
    "project_name",
    "source_url_or_registry_id",
    "campaign_section",
    "capability_domain",
    "integration_status",
    "implementation_mode",
    "runtime_dependency_added",
    "tests_added",
    "evidence_path",
    "current_boundary",
    "future_target",
}


def _rows() -> dict[str, dict]:
    return {row["project_name"]: row for row in _external_project_rows()}


def test_external_project_registry_is_now_concise_public_summary_plus_rebuildable_rows():
    rows = _rows()
    text = REVIEW.read_text(encoding="utf-8")

    assert MANDATORY_PROJECT_NAMES <= set(rows)
    assert "详细历史证据由 Git history 保存，不在 main 中保留审计堆" in text
    for project_name in [
        "LLM Wiki v2",
        "andrej-karpathy-skills",
        "Presenton",
        "CodeGraph",
        "Understand Anything",
        "LongLive",
        "pi-mono",
        "claude-plugins-official",
        "Redis / Vector DB memory store",
    ]:
        assert project_name in text


def test_external_project_fields_and_statuses_are_complete():
    for row in _external_project_rows():
        assert REQUIRED_ROW_FIELDS <= set(row)
        assert row["integration_status"] in ALLOWED_INTEGRATION_STATUSES
        assert isinstance(row["runtime_dependency_added"], bool)
        assert row["campaign_section"]
        assert row["capability_domain"]
        assert row["current_boundary"]
        assert row["future_target"]


def test_mandatory_external_project_boundaries_are_truthful():
    rows = _rows()

    assert rows["LLM Wiki v2"]["integration_status"] == "real_integration"
    assert rows["LLM Wiki v2"]["implementation_mode"] == "local_capability_fusion"
    assert "Campaign 3 Section 5.1" in rows["LLM Wiki v2"]["campaign_section"]
    assert rows["LLM Wiki v2"]["runtime_dependency_added"] is False

    assert rows["ai-money-maker-handbook"]["integration_status"] == "real_integration"
    assert rows["ai-money-maker-handbook"]["implementation_mode"] == "local_original_library"
    assert "no financial automation" in rows["ai-money-maker-handbook"]["current_boundary"]

    assert rows["Jellyfish"]["integration_status"] == "reference_only"
    assert rows["Jellyfish"]["implementation_mode"] == "not_integrated"
    assert "no media runtime" in rows["Jellyfish"]["current_boundary"]

    assert rows["story-flicks"]["integration_status"] == "reference_only"
    assert rows["story-flicks"]["implementation_mode"] == "not_integrated"
    assert "no provider execution" in rows["story-flicks"]["current_boundary"]

    assert rows["andrej-karpathy-skills"]["integration_status"] == "reference_only"
    assert rows["andrej-karpathy-skills"]["implementation_mode"] == "not_integrated"
    assert rows["Presenton"]["implementation_mode"] == "not_integrated"
    assert rows["Presenton"]["runtime_dependency_added"] is False
    assert rows["CodeGraph"]["implementation_mode"] == "not_integrated"
    assert rows["Understand Anything"]["implementation_mode"] == "not_integrated"
    assert rows["NVlabs/LongLive"]["integration_status"] == "stopped_or_rejected"
    assert rows["NVlabs/LongLive"]["future_target"] == "No current target"
    assert rows["pi-mono"]["implementation_mode"] == "not_integrated"
    assert rows["claude-plugins-official"]["implementation_mode"] == "not_integrated"
    assert rows["Redis / Vector DB / external database-backed Memory Store Connector"]["integration_status"] == "planned_not_active"
    assert rows["Redis / Vector DB / external database-backed Memory Store Connector"]["future_target"] == "Campaign 8"


def test_no_reference_project_is_written_as_runtime_dependency():
    for row in _external_project_rows():
        if row["integration_status"] in {"reference_only", "planned_not_active", "needs_verification", "stopped_or_rejected"}:
            assert row["runtime_dependency_added"] is False
        if row["project_name"] in {"Presenton", "NVlabs/LongLive", "CodeGraph", "Understand Anything", "pi-mono", "claude-plugins-official"}:
            assert row["implementation_mode"] == "not_integrated"
