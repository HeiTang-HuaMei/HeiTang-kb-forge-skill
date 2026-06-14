import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
GATE_JSON = ROOT / "docs" / "governance" / "PRODUCT_OUTPUT_SURFACE_AND_EXTERNAL_TREND_ALIGNMENT_GATE.json"
GATE_MD = ROOT / "docs" / "governance" / "PRODUCT_OUTPUT_SURFACE_AND_EXTERNAL_TREND_ALIGNMENT_GATE.md"
FINAL_CONSISTENCY = ROOT / "docs" / "governance" / "CAMPAIGN_3_FINAL_CONSISTENCY_GATE_POLICY.md"
TARGET_MATRIX = ROOT / "docs" / "governance" / "TARGET_ACCEPTANCE_MATRIX.md"
CURRENT_TRUTH = ROOT / "docs" / "CURRENT_TRUTH.md"
CAPABILITY_MATRIX = ROOT / "docs" / "CAPABILITY_MATRIX.md"
REGISTRY = ROOT / "docs" / "roadmap" / "external_projects" / "external_project_registry.json"
LEDGER = ROOT / "docs" / "governance" / "GOAL_ACCEPTANCE_LEDGER.json"
VALIDATION_MANIFEST = ROOT / "docs" / "testing" / "VALIDATION_GATE_MANIFEST.json"

EXPECTED_SURFACES = {
    "knowledge_package",
    "document_outputs",
    "skill_outputs",
    "agent_creation_package",
}

EXPECTED_FORMATS = {
    "Markdown",
    "DOCX / Word",
    "PDF",
    "PPTX / PowerPoint",
}

EXPECTED_QUEUE = {
    "andrej_karpathy_skills": True,
    "presenton": False,
    "codegraph": False,
    "understand_anything": False,
    "nvlabs_longlive": False,
    "claude_plugins_official": False,
    "pi_mono": False,
}


def _json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def _text(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def test_gate_registers_four_distinct_product_output_surfaces():
    gate = _json(GATE_JSON)
    surfaces = {item["surface_id"]: item for item in gate["product_output_surfaces"]}

    assert gate["status"] == "registered_for_campaign_3_final_consistency"
    assert set(surfaces) == EXPECTED_SURFACES
    assert surfaces["document_outputs"]["current_recognition"] == "existing_core_capability"
    assert surfaces["document_outputs"]["covered_by_skill_outputs"] is False
    assert set(surfaces["document_outputs"]["formats"]) == EXPECTED_FORMATS
    assert surfaces["document_outputs"]["core_command"] == "generate-documents"
    assert surfaces["document_outputs"]["not_audit_report_side_effect"] is True
    assert surfaces["skill_outputs"]["covered_by_document_outputs"] is False
    assert surfaces["agent_creation_package"]["agent_runtime_ready"] is False
    assert gate["next_safe_action"] == "Campaign 3 Final Consistency Gate only"
    assert gate["campaign_4_active"] is False
    assert gate["campaign_5_active"] is False
    assert gate["push_tag_ci_active"] is False


def test_product_boundary_is_visible_in_truth_matrix_and_final_consistency_gate():
    combined = "\n".join(
        [
            _text(CURRENT_TRUTH),
            _text(CAPABILITY_MATRIX),
            _text(TARGET_MATRIX),
            _text(FINAL_CONSISTENCY),
            _text(GATE_MD),
        ]
    )

    for surface in EXPECTED_SURFACES:
        assert surface in combined
    for fmt in EXPECTED_FORMATS:
        assert fmt in combined
    assert "generate-documents" in combined
    assert "existing_core_capability" in combined
    assert "not an audit-report side effect" in combined
    assert "not covered by Skill Outputs" in combined
    assert "Campaign 3 Final Consistency Gate" in combined


def test_existing_generate_documents_is_registered_without_new_implementation_scope():
    gate = _json(GATE_JSON)
    document_surface = next(
        item for item in gate["product_output_surfaces"] if item["surface_id"] == "document_outputs"
    )

    assert document_surface["existing_smoke_tests"] == [
        "tests/test_v30_document_generation.py",
        "tests/test_v30_document_generation_cli.py",
    ]
    assert "Presenton" in _text(GATE_MD)
    assert "does not implement document generation inside 4.0A or 4.0B" in _text(GATE_MD)
    assert "must not implement a new document generator" in _text(FINAL_CONSISTENCY)
    assert "pull document/PPT runtime from an external project" in _text(FINAL_CONSISTENCY)


def test_external_reference_queue_is_not_integrated_and_has_no_runtime_dependencies():
    registry = _json(REGISTRY)
    queue = {item["project_id"]: item for item in registry["future_reference_queue"]}

    assert set(queue) == set(EXPECTED_QUEUE)
    for project_id, current_version_required in EXPECTED_QUEUE.items():
        item = queue[project_id]
        assert item["status"] in {"needs_verification", "reference_only"}
        assert item["implementation_mode"] == "not_integrated"
        assert item["current_version_required"] is current_version_required
        assert item["runtime_dependency_added"] is False
        assert item["npm_install_required"] is False
        assert item["gpu_runtime_integration"] is False
        assert item["mcp_or_plugin_execution"] is False
        assert item["no_runtime_dependency_added"] is True
        assert item["no_npm_install"] is True
        assert item["no_gpu_runtime_integration"] is True
        assert item["no_mcp_plugin_execution"] is True

    assert queue["andrej_karpathy_skills"]["status"] == "reference_only"
    assert queue["presenton"]["project_name"] == "Presenton"
    assert "not integrated as PPT runtime" in queue["presenton"]["boundary"]
    assert "no long-video generation runtime" in queue["nvlabs_longlive"]["boundary"]
    assert "no knowledge graph runtime" in queue["codegraph"]["boundary"]
    assert "no interactive knowledge graph runtime" in queue["understand_anything"]["boundary"]
    assert "no Claude plugin runtime" in queue["claude_plugins_official"]["boundary"]
    assert "no Agent runtime" in queue["pi_mono"]["boundary"]


def test_guard_forbids_external_runtime_overclaims_and_campaign_advancement():
    gate = _json(GATE_JSON)
    forbidden = gate["forbidden"]
    ledger_review = _json(LEDGER)["last_goal_drift_review"]

    assert forbidden["real_external_project_integration"] is True
    assert forbidden["presenton_ppt_runtime_integrated"] is False
    assert forbidden["longlive_video_generation_integrated"] is False
    assert forbidden["codegraph_knowledge_graph_integrated"] is False
    assert forbidden["understand_anything_knowledge_graph_integrated"] is False
    assert forbidden["claude_plugin_runtime_integrated"] is False
    assert forbidden["pi_mono_runtime_integrated"] is False
    assert forbidden["campaign_4_entered"] is False
    assert forbidden["push_tag_ci_executed"] is False
    assert "external_project_real_integration" in ledger_review["states_forbidden_in_this_task"]
    assert "presenton_ppt_runtime_integrated" in ledger_review["states_forbidden_in_this_task"]
    next_gap = ledger_review["next_e2e_gap"]
    assert (
        "Campaign 3 Final Consistency Gate only" in next_gap
        or "Tag naming policy correction and campaign baseline CI validation only" in next_gap
    )
    assert "Campaign 4" in next_gap


def test_validation_manifest_routes_product_output_guard_to_governance_fast_gate():
    manifest = _json(VALIDATION_MANIFEST)
    governance_rule = next(rule for rule in manifest["impact_rules"] if rule["name"] == "test_governance")
    fast_gate = next(gate for gate in manifest["gates"] if gate["name"] == "core_fast_test_governance")

    for path in [
        "docs/governance/PRODUCT_OUTPUT_SURFACE_AND_EXTERNAL_TREND_ALIGNMENT_GATE.md",
        "docs/governance/PRODUCT_OUTPUT_SURFACE_AND_EXTERNAL_TREND_ALIGNMENT_GATE.json",
        "tests/test_product_output_surface_external_trend_alignment.py",
    ]:
        assert path in governance_rule["patterns"]

    assert "product_output_surface_guard" in governance_rule["impacted_surfaces"]
    assert "external_trend_reference_queue" in governance_rule["impacted_surfaces"]
    assert "tests/test_product_output_surface_external_trend_alignment.py" in fast_gate["command"]
