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

    assert payload["rating_counts"] == {
        "S": sum(1 for project in source["projects"] if project["rating"] == "S"),
        "A": sum(1 for project in source["projects"] if project["rating"] == "A"),
    }
    assert payload["external_project_count"] == 26
    assert payload["internal_capability_anchor_count"] == 8
    assert included_ids == source_ids


def test_external_capability_registry_entries_preserve_runtime_and_ui_boundaries():
    payload = _json(CAPABILITY_REGISTRY)
    integrated = {
        "llm_wiki_v2",
        "weknora",
        "n8n",
        "anysearchskill",
        "skill_prompt_generator",
        "mmskills",
        "jellyfish",
        "story_flicks",
        "seedance2_skill",
        "rag_anything",
        "mattpocock_skills",
        "sirchmunk",
        "ai_marketing_skills",
    }

    for project in payload["projects"]:
        assert REQUIRED_FIELDS <= set(project)
        assert project["contract_status"]
        assert project["post_v4_target"]
        assert project["blocked_reason"] in project["blocked_reasons"]
        assert project["implemented"] is (project["project_id"] in integrated)
        assert project["ready"] is False
        if project["project_id"] in {
            "llm_wiki_v2",
            "weknora",
            "n8n",
            "skill_prompt_generator",
            "mmskills",
            "jellyfish",
            "story_flicks",
            "seedance2_skill",
            "rag_anything",
            "mattpocock_skills",
            "sirchmunk",
            "ai_marketing_skills",
        }:
            assert project["local_ready"] is True
        else:
            assert project["local_ready"] is False
        assert project["executable_action"] is False
        assert project["can_execute_locally_before_v4"] is False
        assert project["can_execute_after_provider_config"] is (
            project["project_id"] == "anysearchskill"
        )
        assert project["p1_gate_impact"] == "none_not_p1_blocker"
        assert project["ui_visibility"] in {
            "visible_boundary_only",
            "visible_status_only",
        }


def test_mandatory_external_capability_urls_are_exact():
    projects = {project["project_id"]: project for project in _json(CAPABILITY_REGISTRY)["projects"]}

    assert projects["llm_wiki_v2"]["github_url"] == "https://github.com/karpathy/llm-wiki"
    assert projects["weknora"]["github_url"] == "https://github.com/tencent/weknora"
    assert projects["n8n"]["github_url"] == "https://github.com/n8n-io/n8n"
    assert projects["anysearchskill"]["github_url"] == "https://github.com/anysearch-ai/anysearch-skill"
    assert projects["skill_prompt_generator"]["github_url"] == "https://github.com/huangserva/skill-prompt-generator"
    assert projects["ai_marketing_skills"]["github_url"] == "https://github.com/ericosiu/ai-marketing-skills"
    assert projects["ai_marketing_skills"]["contract_status"] == [
        "marketing_skill_pattern_library",
        "real_integration",
        "runtime_not_bundled",
    ]
    assert projects["ai_marketing_skills"]["implemented"] is True
    assert projects["ai_marketing_skills"]["ready"] is False
    assert projects["ai_marketing_skills"]["local_ready"] is True
    assert projects["ai_marketing_skills"]["executable_action"] is False
    assert projects["ai_marketing_skills"]["ui_visibility"] == "visible_status_only"
    assert projects["story_flicks"]["github_url"] == "https://github.com/alecm20/story-flicks"
    assert projects["story_flicks"]["contract_status"] == [
        "aigc_video_pipeline_schema_reference",
        "reference_only",
        "runtime_not_bundled",
    ]
    assert projects["story_flicks"]["implemented"] is True
    assert projects["story_flicks"]["ready"] is False
    assert projects["story_flicks"]["local_ready"] is True
    assert projects["story_flicks"]["executable_action"] is False
    assert projects["story_flicks"]["ui_visibility"] == "visible_status_only"
    assert projects["seedance2_skill"]["github_url"] == "https://github.com/dexhunter/seedance2-skill"
    assert projects["seedance2_skill"]["contract_status"] == [
        "verified_video_skill_template_metadata",
        "reference_only",
        "template_reference",
        "provider_not_integrated",
        "runtime_not_bundled",
    ]
    assert projects["seedance2_skill"]["implemented"] is True
    assert projects["seedance2_skill"]["ready"] is False
    assert projects["seedance2_skill"]["local_ready"] is True
    assert projects["seedance2_skill"]["executable_action"] is False
    assert projects["seedance2_skill"]["requires_api_key"] is True
    assert projects["seedance2_skill"]["requires_network"] is True
    assert projects["seedance2_skill"]["ui_visibility"] == "visible_status_only"
    assert projects["rag_anything"]["github_url"] == "https://github.com/HKUDS/RAG-Anything"
    assert projects["rag_anything"]["contract_status"] == [
        "cross_modal_rag_schema_reference",
        "reference_only",
        "runtime_not_bundled",
    ]
    assert projects["rag_anything"]["implemented"] is True
    assert projects["rag_anything"]["ready"] is False
    assert projects["rag_anything"]["local_ready"] is True
    assert projects["rag_anything"]["executable_action"] is False
    assert projects["rag_anything"]["requires_api_key"] is False
    assert projects["rag_anything"]["requires_network"] is False
    assert projects["rag_anything"]["requires_external_runtime"] is False
    assert projects["rag_anything"]["ui_visibility"] == "visible_status_only"
    assert projects["mattpocock_skills"]["github_url"] == "https://github.com/mattpocock/skills"
    assert projects["mattpocock_skills"]["contract_status"] == [
        "engineering_governance_rule_pack",
        "real_integration",
        "runtime_not_bundled",
    ]
    assert projects["mattpocock_skills"]["implemented"] is True
    assert projects["mattpocock_skills"]["ready"] is False
    assert projects["mattpocock_skills"]["local_ready"] is True
    assert projects["mattpocock_skills"]["executable_action"] is False
    assert projects["mattpocock_skills"]["requires_api_key"] is False
    assert projects["mattpocock_skills"]["requires_network"] is False
    assert projects["mattpocock_skills"]["requires_external_runtime"] is False
    assert projects["mattpocock_skills"]["ui_visibility"] == "visible_status_only"
    assert projects["sirchmunk"]["github_url"] == "https://github.com/modelscope/sirchmunk"
    assert projects["sirchmunk"]["contract_status"] == [
        "bounded_direct_file_search_provider",
        "real_integration",
        "runtime_not_bundled",
        "embedding_free",
        "vector_db_not_required",
    ]
    assert projects["sirchmunk"]["implemented"] is True
    assert projects["sirchmunk"]["ready"] is False
    assert projects["sirchmunk"]["local_ready"] is True
    assert projects["sirchmunk"]["executable_action"] is False
    assert projects["sirchmunk"]["requires_api_key"] is False
    assert projects["sirchmunk"]["requires_network"] is False
    assert projects["sirchmunk"]["requires_external_runtime"] is False
    assert projects["sirchmunk"]["ui_visibility"] == "visible_status_only"


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
    assert boundary["external_features_implemented"] is True
    assert boundary["planned_adapters_marked_ready"] is False
    assert boundary["provider_network_api_ready"] is False
