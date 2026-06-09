import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
AUDIT = ROOT / "docs" / "audits" / "p1_real_workflow_v1"


def test_committed_p1_real_workflow_v1_audit_keeps_gate_boundaries():
    report = _json(AUDIT / "p1_real_workflow_v1_report.json")
    command_surface = _json(AUDIT / "command_surface_truth_report.json")
    evidence = _json(AUDIT / "real_vs_fixture_evidence_report.json")

    assert report["p1_real_workflow_v1_status"] == "passed"
    assert report["p1_full_operation_gate_status"] == "blocked"
    assert report["ready_for_v4_rc"] is False
    assert report["not_v4_0_workbench_rc"] is True
    assert command_surface["drift_count"] == 0
    assert evidence["fixture_only_counted_as_real"] is False
    assert evidence["full_57_ready_action_execution_complete"] is False


def test_committed_p1_real_workflow_v1_audit_contains_required_workflow_outputs():
    for workflow_id in [
        "workspace_lifecycle",
        "import_parse_build",
        "rag_retrieval_verification_smoke",
        "document_generation_smoke",
        "skill_factory_smoke",
        "agent_factory_runtime_smoke",
        "error_repair_task_artifact",
        "template_to_workflow",
    ]:
        run_dir = AUDIT / workflow_id
        assert (run_dir / "workflow_result.json").exists(), workflow_id
        assert (run_dir / "task_events.jsonl").exists(), workflow_id
        assert (run_dir / "artifact_index.json").exists(), workflow_id

    generated_docs = AUDIT / "document_generation_smoke" / "artifacts" / "generated_documents"
    for filename in ["generated.md", "generated_file_report.json", "document_generation_trace.json"]:
        assert (generated_docs / filename).exists()
    assert not list(AUDIT.rglob("*.docx"))
    assert not list(AUDIT.rglob("*.pdf"))
    assert not list(AUDIT.rglob("*.pptx"))


def _json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))
