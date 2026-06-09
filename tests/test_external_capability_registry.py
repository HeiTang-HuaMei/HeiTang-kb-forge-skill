import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SOURCE_REGISTRY = ROOT / "docs" / "roadmap" / "external_projects" / "external_project_registry.json"
CAPABILITY_REGISTRY = ROOT / "docs" / "audits" / "s_a_contract_inclusion" / "external_capability_registry.json"

REQUIRED_FIELDS = {
    "project_id",
    "project_name",
    "rating",
    "github_url",
    "contract_status",
    "mapped_capabilities",
    "related_workbench_pages",
    "related_core_actions",
    "related_templates",
    "related_error_codes",
    "blocked_reason",
    "blocked_reasons",
    "requires_api_key",
    "requires_network",
    "requires_external_runtime",
    "can_execute_locally_before_v4",
    "can_execute_after_provider_config",
    "p1_gate_impact",
    "post_v4_target",
    "ui_visibility",
    "implementation_boundary",
}


def _json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def test_all_s_a_source_projects_are_in_external_capability_registry():
    source = _json(SOURCE_REGISTRY)
    payload = _json(CAPABILITY_REGISTRY)
    source_ids = {project["project_id"] for project in source["projects"] if project["rating"] in {"S", "A"}}
    included_ids = {project["project_id"] for project in payload["projects"]}

    assert payload["rating_counts"] == {"S": 7, "A": 16}
    assert payload["external_project_count"] == 23
    assert payload["internal_capability_anchor_count"] == 8
    assert included_ids == source_ids


def test_external_capability_registry_entries_are_contract_only():
    payload = _json(CAPABILITY_REGISTRY)

    for project in payload["projects"]:
        assert REQUIRED_FIELDS <= set(project)
        assert project["contract_status"]
        assert project["post_v4_target"]
        assert project["blocked_reason"] in project["blocked_reasons"]
        assert project["implemented"] is False
        assert project["ready"] is False
        assert project["local_ready"] is False
        assert project["executable_action"] is False
        assert project["can_execute_locally_before_v4"] is False
        assert project["can_execute_after_provider_config"] is False
        assert project["p1_gate_impact"] == "none_not_p1_blocker"
        assert project["ui_visibility"] == "visible_boundary_only"


def test_mandatory_external_capability_urls_are_exact():
    projects = {project["project_id"]: project for project in _json(CAPABILITY_REGISTRY)["projects"]}

    assert projects["llm_wiki_v2"]["github_url"] == "https://github.com/karpathy/llm-wiki"
    assert projects["weknora"]["github_url"] == "https://github.com/tencent/weknora"
    assert projects["n8n"]["github_url"] == "https://github.com/n8n-io/n8n"
    assert projects["anysearchskill"]["github_url"] == "https://github.com/anysearch-ai/anysearch-skill"


def test_internal_capability_anchors_are_present_with_book_to_skill():
    anchors = {anchor["anchor_id"]: anchor for anchor in _json(CAPABILITY_REGISTRY)["internal_capability_anchors"]}

    assert len(anchors) == 8
    assert anchors["book_to_skill"]["anchor_name"] == "Book-to-Skill"
    assert anchors["book_to_skill"]["contract_status"] == ["internal_capability", "implemented"]
    assert anchors["book_to_skill"]["ready"] is True


def test_external_capability_release_boundary_does_not_start_v4_or_change_gate():
    boundary = _json(CAPABILITY_REGISTRY)["release_boundary"]

    assert boundary["p1_gate_changed"] is False
    assert boundary["v4_0_started"] is False
    assert boundary["tag_created"] is False
    assert boundary["release_written"] is False
    assert boundary["external_features_implemented"] is False
    assert boundary["planned_adapters_marked_ready"] is False
    assert boundary["provider_network_api_ready"] is False
