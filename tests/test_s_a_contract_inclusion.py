import json
from pathlib import Path

from heitang_kb_forge.workbench import make_external_capability_bundle


ROOT = Path(__file__).resolve().parents[1]
AUDIT_DIR = ROOT / "docs" / "audits" / "s_a_contract_inclusion"

EXPECTED_STATUS = {
    "llm_wiki_v2": ["future_adapter", "capability_anchor"],
    "weknora": ["future_adapter", "capability_anchor"],
    "n8n": ["future_adapter", "provider_required", "workflow_export"],
    "anysearchskill": ["provider_required", "planned_adapter"],
    "andrej_karpathy_skills": ["benchmark_only", "capability_anchor"],
    "last30days_skill": ["provider_required", "future_adapter"],
    "skill_prompt_generator": ["benchmark_only", "future_adapter"],
    "mmskills": ["future_adapter"],
    "jellyfish": ["template_reference", "future_adapter"],
    "story_flicks": ["template_reference", "future_adapter"],
    "seedance2_skill": ["provider_required", "template_reference", "future_adapter"],
    "ai_marketing_skills": ["template_reference"],
    "rtk": ["benchmark_only"],
    "opendataloader": ["planned_adapter"],
    "paddleocr": ["planned_adapter", "optional_runtime_adapter"],
    "mineru": ["planned_adapter"],
    "docling": ["planned_adapter", "optional_runtime_adapter"],
    "marker": ["planned_adapter"],
    "surya": ["planned_adapter"],
    "unstructured": ["planned_adapter", "optional_runtime_adapter"],
    "llamaindex": ["benchmark_only"],
    "ragas": ["benchmark_only", "future_adapter"],
    "deepeval": ["benchmark_only", "future_adapter"],
}


def _json(name: str) -> dict:
    return json.loads((AUDIT_DIR / name).read_text(encoding="utf-8"))


def test_committed_s_a_contract_outputs_match_generator():
    generated = make_external_capability_bundle(ROOT)

    for filename, payload in generated.items():
        path = AUDIT_DIR / filename
        assert path.exists(), filename
        if filename.endswith(".json"):
            assert json.loads(path.read_text(encoding="utf-8")) == payload
        else:
            assert path.read_text(encoding="utf-8") == payload


def test_contract_statuses_match_s_a_inclusion_policy():
    projects = {project["project_id"]: project for project in _json("external_capability_registry.json")["projects"]}

    assert set(projects) == set(EXPECTED_STATUS)
    for project_id, statuses in EXPECTED_STATUS.items():
        assert projects[project_id]["contract_status"] == statuses


def test_s_a_contract_matrix_exposes_workbench_pages_without_execution():
    matrix = _json("s_a_contract_inclusion_matrix.json")

    assert matrix["external_project_count"] == 23
    for entry in matrix["entries"]:
        assert entry["workbench_page_ids"]
        assert entry["workbench_pages"]
        assert entry["can_execute_locally_before_v4"] is False
        assert entry["p1_gate_impact"] == "none_not_p1_blocker"
        assert entry["ui_visibility"] == "visible_boundary_only"


def test_workbench_p1_gate_report_is_boundary_only():
    report = _json("workbench_p1_gate_report.json")

    assert report["p1_gate_changed"] is False
    assert report["p1_gate_impact"] == "none"
    assert report["p1_full_operation_gate_status"] == "unchanged_by_s_a_contract_inclusion"
    assert report["not_v4_0_workbench_rc"] is True
    assert report["external_capability_boundary"]["planned_adapters_marked_ready"] is False
    assert report["external_capability_boundary"]["provider_network_api_ready"] is False
    assert report["external_capability_boundary"]["ui_visibility_only"] is True
