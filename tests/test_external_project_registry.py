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
    "rag_anything",
    "mattpocock_skills",
    "sirchmunk",
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
    assert payload["external_features_implemented"] is True
    assert payload["v4_0_started"] is False
    assert payload["tag_created"] is False
    assert payload["release_written"] is False


def test_mandatory_project_urls_are_exact():
    projects = {project["project_id"]: project for project in _registry()["projects"]}

    assert projects["llm_wiki_v2"]["github_url"] == "https://github.com/karpathy/llm-wiki"
    assert projects["weknora"]["github_url"] == "https://github.com/tencent/weknora"
    assert projects["n8n"]["github_url"] == "https://github.com/n8n-io/n8n"
    assert projects["n8n"]["current_repo_status"] == "real_workflow_evidence"
    assert projects["n8n"]["implementation_mode"] == "workflow_export"
    assert projects["n8n"]["requires_external_runtime"] is True
    assert projects["anysearchskill"]["github_url"] == "https://github.com/anysearch-ai/anysearch-skill"
    assert projects["anysearchskill"]["current_repo_status"] == "real_workflow_evidence"
    assert projects["anysearchskill"]["requires_api_key"] is False
    assert projects["anysearchskill"]["requires_network"] is True
    assert projects["skill_prompt_generator"]["github_url"] == "https://github.com/huangserva/skill-prompt-generator"
    assert projects["skill_prompt_generator"]["current_repo_status"] == "real_workflow_evidence"
    assert projects["skill_prompt_generator"]["implementation_mode"] == "prompt_asset_library_enhancer"
    assert projects["skill_prompt_generator"]["requires_network"] is False
    assert projects["ai_marketing_skills"]["github_url"] == "https://github.com/ericosiu/ai-marketing-skills"
    assert projects["ai_marketing_skills"]["current_repo_status"] == "real_workflow_evidence"
    assert projects["ai_marketing_skills"]["implementation_mode"] == "marketing_skill_pattern_library"
    assert projects["ai_marketing_skills"]["requires_api_key"] is False
    assert projects["ai_marketing_skills"]["requires_network"] is False
    assert projects["ai_marketing_skills"]["requires_external_runtime"] is False
    assert "heitang_kb_forge/marketing_skill_patterns/builder.py" in projects["ai_marketing_skills"]["current_evidence_files"]
    assert "tests/test_marketing_skill_patterns.py" in projects["ai_marketing_skills"]["current_evidence_files"]
    assert (
        "artifacts/audits/section_5/ai_marketing_skills_pattern_library/ai_marketing_skills_integration_decision_report.json"
        in projects["ai_marketing_skills"]["current_evidence_files"]
    )
    assert projects["jellyfish"]["github_url"] == "https://github.com/Forget-C/Jellyfish"
    assert projects["jellyfish"]["current_repo_status"] == "reference_schema_evidence"
    assert projects["jellyfish"]["implementation_mode"] == "content_asset_schema_reference"
    assert projects["jellyfish"]["requires_api_key"] is False
    assert projects["jellyfish"]["requires_network"] is False
    assert projects["jellyfish"]["requires_external_runtime"] is False
    assert "heitang_kb_forge/content_asset_schema/builder.py" in projects["jellyfish"]["current_evidence_files"]
    assert "tests/test_content_asset_schema.py" in projects["jellyfish"]["current_evidence_files"]
    assert (
        "artifacts/audits/section_5/jellyfish_content_asset_schema/jellyfish_integration_decision_report.json"
        in projects["jellyfish"]["current_evidence_files"]
    )
    assert projects["story_flicks"]["github_url"] == "https://github.com/alecm20/story-flicks"
    assert projects["story_flicks"]["current_repo_status"] == "reference_schema_evidence"
    assert projects["story_flicks"]["implementation_mode"] == "aigc_video_pipeline_schema_reference"
    assert projects["story_flicks"]["requires_api_key"] is False
    assert projects["story_flicks"]["requires_network"] is False
    assert projects["story_flicks"]["requires_external_runtime"] is False
    assert "heitang_kb_forge/video_pipeline_schema/builder.py" in projects["story_flicks"]["current_evidence_files"]
    assert "tests/test_video_pipeline_schema.py" in projects["story_flicks"]["current_evidence_files"]
    assert (
        "artifacts/audits/section_5/story_flicks_video_pipeline_schema/story_flicks_integration_decision_report.json"
        in projects["story_flicks"]["current_evidence_files"]
    )
    assert projects["seedance2_skill"]["github_url"] == "https://github.com/dexhunter/seedance2-skill"
    assert projects["seedance2_skill"]["current_repo_status"] == "reference_schema_evidence"
    assert projects["seedance2_skill"]["implementation_mode"] == "verified_video_skill_template_metadata"
    assert projects["seedance2_skill"]["requires_api_key"] is True
    assert projects["seedance2_skill"]["requires_network"] is True
    assert projects["seedance2_skill"]["requires_external_runtime"] is False
    assert "heitang_kb_forge/video_skill_template_metadata/builder.py" in projects["seedance2_skill"]["current_evidence_files"]
    assert "tests/test_video_skill_template_metadata.py" in projects["seedance2_skill"]["current_evidence_files"]
    assert (
        "artifacts/audits/section_5/seedance2_skill_template_metadata/seedance2_skill_integration_decision_report.json"
        in projects["seedance2_skill"]["current_evidence_files"]
    )
    assert projects["rag_anything"]["github_url"] == "https://github.com/HKUDS/RAG-Anything"
    assert projects["rag_anything"]["current_repo_status"] == "reference_schema_evidence"
    assert projects["rag_anything"]["implementation_mode"] == "cross_modal_rag_schema_reference"
    assert projects["rag_anything"]["requires_api_key"] is False
    assert projects["rag_anything"]["requires_network"] is False
    assert projects["rag_anything"]["requires_external_runtime"] is False
    assert "heitang_kb_forge/cross_modal_rag_schema/builder.py" in projects["rag_anything"]["current_evidence_files"]
    assert "tests/test_cross_modal_rag_schema.py" in projects["rag_anything"]["current_evidence_files"]
    assert (
        "artifacts/audits/section_5/rag_anything_cross_modal_rag_schema/rag_anything_integration_decision_report.json"
        in projects["rag_anything"]["current_evidence_files"]
    )
    assert projects["mattpocock_skills"]["github_url"] == "https://github.com/mattpocock/skills"
    assert projects["mattpocock_skills"]["current_repo_status"] == "real_workflow_evidence"
    assert projects["mattpocock_skills"]["implementation_mode"] == "engineering_governance_rule_pack"
    assert projects["mattpocock_skills"]["requires_api_key"] is False
    assert projects["mattpocock_skills"]["requires_network"] is False
    assert projects["mattpocock_skills"]["requires_external_runtime"] is False
    assert "heitang_kb_forge/engineering_governance_rules/builder.py" in projects["mattpocock_skills"]["current_evidence_files"]
    assert "tests/test_engineering_governance_rules.py" in projects["mattpocock_skills"]["current_evidence_files"]
    assert (
        "artifacts/audits/section_5/mattpocock_skills_engineering_governance/mattpocock_skills_integration_decision_report.json"
        in projects["mattpocock_skills"]["current_evidence_files"]
    )
    assert projects["sirchmunk"]["github_url"] == "https://github.com/modelscope/sirchmunk"
    assert projects["sirchmunk"]["current_repo_status"] == "real_workflow_evidence"
    assert projects["sirchmunk"]["implementation_mode"] == "bounded_direct_file_search_provider"
    assert projects["sirchmunk"]["requires_api_key"] is False
    assert projects["sirchmunk"]["requires_network"] is False
    assert projects["sirchmunk"]["requires_external_runtime"] is False
    assert "heitang_kb_forge/external_retrieval/sirchmunk.py" in projects["sirchmunk"]["current_evidence_files"]
    assert "tests/test_sirchmunk_direct_file_search.py" in projects["sirchmunk"]["current_evidence_files"]
    assert (
        "artifacts/audits/section_5/sirchmunk_direct_file_search/sirchmunk_integration_decision_report.json"
        in projects["sirchmunk"]["current_evidence_files"]
    )
    assert all(
        "anysearch" not in evidence.lower()
        for evidence in projects["llm_wiki_v2"]["current_evidence_files"]
    )
    assert all(
        "n8n" not in evidence.lower()
        for project_id in ["llm_wiki_v2", "weknora", "anysearchskill"]
        for evidence in projects[project_id]["current_evidence_files"]
    )


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
            "reference_schema_evidence",
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
