import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
REGISTRY_PATH = ROOT / "docs" / "roadmap" / "external_projects" / "external_project_registry.json"

MANDATORY_PROJECT_IDS = {
    "llm_wiki_v2",
    "weknora",
    "n8n",
    "andrej_karpathy_skills",
    "paddleocr",
    "mineru",
    "docling",
    "anysearchskill",
    "last30days_skill",
    "skill_prompt_generator",
    "mmskills",
    "jellyfish",
    "story_flicks",
    "seedance2_skill",
    "ai_marketing_skills",
    "rtk",
    "opendataloader",
    "marker",
    "surya",
    "unstructured",
    "llamaindex",
    "ragas",
    "deepeval",
    "ai_money_maker_handbook",
    "vibe_coding_cn",
    "ruflo",
    "growth_loop",
}

REQUIRED_PROJECT_FIELDS = {
    "project_id",
    "project_name",
    "github_url",
    "rating",
    "rating_reason",
    "current_repo_status",
    "current_evidence_files",
    "mapped_capabilities",
    "suitable_for_heitang",
    "not_suitable_parts",
    "pre_v4_scope",
    "post_v4_target",
    "ui_impact",
    "implementation_mode",
    "requires_api_key",
    "requires_network",
    "requires_external_runtime",
    "license_or_security_review_required",
    "can_be_ready_before_v4",
    "reason_not_ready_before_v4",
    "recommended_next_action",
}


def _registry() -> dict:
    return json.loads(REGISTRY_PATH.read_text(encoding="utf-8"))


def test_registry_json_exists_and_contains_all_required_projects():
    payload = _registry()
    projects = {project["project_id"]: project for project in payload["projects"]}

    assert REGISTRY_PATH.exists()
    assert MANDATORY_PROJECT_IDS <= set(projects)
    assert len(projects) >= len(MANDATORY_PROJECT_IDS)
    assert payload["external_features_implemented"] is False
    assert payload["v4_0_started"] is False
    assert payload["tag_created"] is False
    assert payload["release_written"] is False


def test_mandatory_project_urls_are_exact():
    projects = {project["project_id"]: project for project in _registry()["projects"]}

    assert projects["llm_wiki_v2"]["github_url"] == "https://github.com/karpathy/llm-wiki"
    assert projects["weknora"]["github_url"] == "https://github.com/tencent/weknora"
    assert projects["n8n"]["github_url"] == "https://github.com/n8n-io/n8n"
    assert projects["anysearchskill"]["github_url"] == "https://github.com/anysearch-ai/anysearch-skill"


def test_external_project_fields_and_boundaries_are_complete():
    for project in _registry()["projects"]:
        assert REQUIRED_PROJECT_FIELDS <= set(project)
        assert project["rating"] in {"S", "A", "B", "needs_verification"}
        assert project["current_repo_status"] in {
            "implemented",
            "real_workflow_evidence",
            "benchmark_mapped",
            "planned_adapter",
            "future_adapter",
            "docs_only",
            "ui_surface_only",
            "contract_only",
            "mentioned_only",
            "not_found",
            "needs_verification",
            "rejected",
        }
        assert project["mapped_capabilities"]
        assert project["pre_v4_scope"] in {"registry_only", "docs_mapping_only", "contract_mapping_only", "not_allowed"}
        if project["rating"] in {"S", "A"}:
            assert project["post_v4_target"]
        if project["requires_api_key"] or project["requires_network"]:
            assert project["can_be_ready_before_v4"] is False
        if project["current_repo_status"] == "planned_adapter":
            assert project["current_repo_status"] != "implemented"
            assert project["can_be_ready_before_v4"] is False


def test_internal_capability_anchors_include_book_to_skill():
    anchors = {anchor["anchor_id"]: anchor for anchor in _registry()["internal_capability_anchors"]}

    assert len(anchors) == 8
    assert anchors["book_to_skill"]["anchor_name"] == "Book-to-Skill"
    assert anchors["book_to_skill"]["rating"] == "S"
    assert anchors["book_to_skill"]["current_status"] == "implemented"


def test_all_s_a_projects_have_post_v4_targets():
    projects = _registry()["projects"]
    missing = [project["project_id"] for project in projects if project["rating"] in {"S", "A"} and not project["post_v4_target"]]
    assert missing == []
