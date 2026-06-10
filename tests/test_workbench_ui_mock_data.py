import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
MOCK_DATA = ROOT / "examples" / "ui_mock_data"
CORE_COMMIT = "f5fa13bb11211abb0bcecaccd845e545a2dacad3"
PARSER_RUNTIME_BASELINE_COMMIT = "576a62075dc1ecbe00388bb0569fd1fc767be7cb"


def read_json(name):
    return json.loads((MOCK_DATA / name).read_text(encoding="utf-8"))


def test_required_mock_data_files_exist_and_are_json():
    for file_name in [
        "knowledge_bases.json",
        "agents.json",
        "workflows.json",
        "memory_scopes.json",
        "jobs.json",
        "review_queue.json",
        "generated_docs.json",
        "provider_status.json",
        "parser_backend_status.json",
        "parser_backends/parser_backend_matrix.json",
        "answer_policies.json",
        "p1_core_contract_fixture.json",
        "p1_real_workflow_v1_evidence.json",
        "p1_real_workflow_v2_evidence.json",
    ]:
        assert (MOCK_DATA / file_name).exists()
        assert isinstance(read_json(file_name), dict)


def test_mock_data_represents_knowledge_bases_agents_and_bindings():
    knowledge_bases = read_json("knowledge_bases.json")["knowledge_bases"]
    agents = read_json("agents.json")["agents"]
    kb_ids = {kb["id"] for kb in knowledge_bases}
    agent_ids = {agent["id"] for agent in agents}

    assert len(knowledge_bases) >= 2
    assert {"draft", "trusted"} <= {kb["status"] for kb in knowledge_bases}
    assert len(agents) >= 2

    for kb in knowledge_bases:
        assert kb["bound_agents"]
        assert set(kb["bound_agents"]) <= agent_ids

    for agent in agents:
        assert agent["bound_kbs"]
        assert set(agent["bound_kbs"]) <= kb_ids
        assert agent["private_memory_scope"].startswith("mem-agent-")


def test_mock_data_represents_providers_policies_and_parser_status():
    providers = read_json("provider_status.json")["providers"]
    parser_status = read_json("parser_backend_status.json")
    parser_backends = parser_status["parser_backends"]
    policies = read_json("answer_policies.json")

    assert len(providers) >= 3
    assert {"available", "degraded", "offline"} <= {provider["status"] for provider in providers}
    assert parser_status["source"]["derived_from"] == "examples/ui_mock_data/parser_backends/parser_backend_matrix.json"
    assert parser_status["source"]["core_runtime_baseline_commit"] == PARSER_RUNTIME_BASELINE_COMMIT
    assert {backend["id"] for backend in parser_backends} == {"builtin", "docling", "paddleocr", "unstructured"}
    assert {backend["status"] for backend in parser_backends} == {"builtin_passed", "real_runtime_integrated"}
    assert all(backend["static_workbench_executable"] is False for backend in parser_backends)
    assert next(backend for backend in parser_backends if backend["id"] == "unstructured")["supports"] == [".md", ".txt"]
    assert {"grounded_only", "cite_or_abstain", "needs_review"} <= {
        policy["id"] for policy in policies["answer_policies"]
    }
    assert policies["memory_policies"]


def test_parser_backend_matrix_fixture_matches_flutter_asset_and_core_boundaries():
    fixture = read_json("parser_backends/parser_backend_matrix.json")
    asset = json.loads(
        (ROOT / "web" / "workbench" / "flutter_app" / "assets" / "parser_backends" / "parser_backend_matrix.json").read_text(
            encoding="utf-8"
        )
    )

    assert fixture == asset
    assert fixture["schema_version"] == "p2.1.parser_backend_matrix.v1"
    assert fixture["release_version"] == "v4.1.0"
    assert fixture["runtime_baseline_commit"] == PARSER_RUNTIME_BASELINE_COMMIT
    assert fixture["default_heavy_dependencies_bundled"] is False
    assert fixture["static_workbench_runtime_execution_claimed"] is False
    assert {backend["backend_id"] for backend in fixture["backends"]} == {"builtin", "docling", "paddleocr", "unstructured"}
    assert all(backend["static_workbench_executable"] is False for backend in fixture["backends"])
    assert all("evidence_path" in backend and backend["evidence_path"] for backend in fixture["backends"])

    unstructured = next(backend for backend in fixture["backends"] if backend["backend_id"] == "unstructured")
    assert unstructured["validated_stable_surface"] == [".md", ".txt"]
    assert any(".md/.txt" in limitation for limitation in unstructured["known_limitations"])
    assert not any(
        extension in unstructured["validated_stable_surface"]
        for extension in [".pdf", ".docx", ".png", ".jpg", ".jpeg"]
    )


def test_mock_data_represents_p1_core_contract_alignment_fixture():
    fixture = read_json("p1_core_contract_fixture.json")

    assert fixture["source"]["core_commit"] == CORE_COMMIT
    assert fixture["not_full_operation_yet"] is True
    assert fixture["not_v4_0_workbench_rc"] is True
    assert fixture["counts"]["actions"] == 110
    assert fixture["counts"]["reports"] == 109
    assert fixture["counts"]["artifacts"] == 101
    assert fixture["counts"]["errors"] == 20
    assert fixture["counts"]["templates"] == 6


def test_mock_data_represents_p1_real_workflow_v1_evidence():
    evidence = read_json("p1_real_workflow_v1_evidence.json")

    assert evidence["source"]["core_commit"] == CORE_COMMIT
    assert evidence["p1_real_workflow_v1_status"] == "passed"
    assert evidence["p1_full_operation_gate_status"] == "blocked"
    assert evidence["ready_for_v4_rc"] is False
    assert evidence["drift_count"] == 0
    assert evidence["fixture_only_counted_as_real"] is False
    assert evidence["full_57_ready_action_execution_complete"] is False


def test_mock_data_represents_p1_real_workflow_v2_evidence_and_reports():
    evidence = read_json("p1_real_workflow_v2_evidence.json")
    report_dir = MOCK_DATA / "p1_real_workflow_v2"
    matrix = json.loads((report_dir / "full_ready_action_execution_matrix.json").read_text(encoding="utf-8"))
    action_results = json.loads((report_dir / "action_execution_result_index.json").read_text(encoding="utf-8"))
    user_paths = json.loads((report_dir / "full_local_user_path_closure_report.json").read_text(encoding="utf-8"))
    errors = json.loads((report_dir / "action_error_boundary_report.json").read_text(encoding="utf-8"))

    assert evidence["source"]["core_commit"] == CORE_COMMIT
    assert evidence["p1_real_workflow_v2_status"] == "passed"
    assert evidence["p1_final_gate_status"] == "ready_for_v4_rc"
    assert evidence["p1_full_operation_gate_status"] == "ready_for_v4_rc"
    assert evidence["ui_full_operation_pending"] is False
    assert evidence["ready_for_v4_rc_candidate"] is True
    assert evidence["ready_for_v4_rc"] is True
    assert evidence["not_v4_0_workbench_rc"] is True
    assert evidence["v4_0_started"] is False
    assert evidence["tag_created"] is False
    assert evidence["v4_release_written"] is False
    assert evidence["drift_count"] == 0
    assert evidence["ready_core_cli_action_count"] == 62
    assert evidence["execution_target_count"] == 57
    assert evidence["passed_action_count"] == 57
    assert evidence["failed_action_count"] == 0
    assert evidence["blocked_action_count"] == 5
    assert evidence["full_57_ready_action_execution_complete"] is True
    assert evidence["remaining_blockers"] == []
    assert matrix["execution_target_count"] == 57
    assert action_results["passed_count"] == 57
    assert user_paths["status"] == "pass"
    assert user_paths["user_path_count"] == 10
    assert errors["external_provider_or_secret_actions_not_executed"] is True


def test_mock_data_represents_review_generated_docs_workflow_and_exports():
    review_items = read_json("review_queue.json")["review_items"]
    docs = read_json("generated_docs.json")
    workflows = read_json("workflows.json")["workflows"]

    assert {"high", "medium", "low"} <= {item["risk"] for item in review_items}
    assert all(item["corrected_text"] for item in review_items)
    assert docs["generated_docs"]
    assert docs["export_items"]
    assert workflows

    for workflow in workflows:
        assert workflow["shared_memory_scope"].startswith("mem-workflow-")
        assert workflow["steps"]
        assert workflow["handoff_trace"]


def test_mock_data_represents_memory_isolation():
    memory_scopes = read_json("memory_scopes.json")["memory_scopes"]
    scope_types = {scope["type"] for scope in memory_scopes}
    isolations = {scope["isolation"] for scope in memory_scopes}

    assert {"agent_private", "workflow_shared"} <= scope_types
    assert "private" in isolations
    assert "shared_with_workflow_agents" in isolations
