import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
MATRIX_PATH = ROOT / "artifacts" / "audits" / "knowledge_supply_chain_acceptance_review" / "campaign_2_acceptance_matrix.json"
SUMMARY_PATH = ROOT / "artifacts" / "audits" / "knowledge_supply_chain_acceptance_review" / "run_summary.md"


def _matrix() -> dict:
    return json.loads(MATRIX_PATH.read_text(encoding="utf-8"))


def _stages() -> dict[str, dict]:
    return {item["stage"]: item for item in _matrix()["stages"]}


def test_campaign_2_acceptance_matrix_exists_and_is_accepted():
    matrix = _matrix()

    assert matrix["verdict"] == "accepted"
    assert matrix["summary"]["campaign_2_acceptance_verdict"] == "accepted"
    assert matrix["summary"]["real_multi_file_e2e"] is True
    assert matrix["summary"]["failure_isolation_evidence"] is True
    assert matrix["summary"]["governed_report_export"] is True
    assert SUMMARY_PATH.exists()


def test_campaign_2_reviews_required_stage_set():
    expected = {
        "batch-import-documents",
        "preflight-documents",
        "select-document-backend",
        "run-document-understanding",
        "build-knowledge-base",
        "build-knowledge-package",
        "build-search-index",
        "export-knowledge-report",
        "export-workflow-report",
    }

    assert set(_stages()) == expected


def test_report_export_cannot_substitute_campaign_2_acceptance():
    matrix = _matrix()
    rules = matrix["non_substitution_rules"]

    assert rules["report_export_replaces_campaign_2_acceptance"] is False
    assert rules["single_file_pass_replaces_multi_file_e2e"] is False
    assert rules["fixture_only_replaces_real_mixed_e2e"] is False
    report_run = next(run for run in matrix["reviewed_runs"] if run["run_id"] == "report_export_20260612_135600")
    assert "not standalone Campaign 2 substitute" in report_run["role"]


def test_every_campaign_2_stage_has_trace_quality_and_no_llm_vector_dependency():
    for stage in _matrix()["stages"]:
        assert stage["command_or_core_action_exists"] is True
        assert stage["real_e2e_run"] is True
        assert stage["source_trace_preserved"] is True
        assert stage["quality_report_present"] is True
        assert stage["evidence_map_present"] is True
        assert stage["works_without_llm"] is True
        assert stage["works_without_vector_db"] is True
        assert stage["progress_log_failure_report_present"] is True
        assert stage["can_count_as_campaign_2_accepted"] is True
        assert stage["remaining_gap"]


def test_select_backend_and_search_index_are_core_actions_not_false_cli_claims():
    stages = _stages()

    assert "not as a standalone CLI command" in stages["select-document-backend"]["command_or_core_action_note"]
    assert "Search index is produced by build-knowledge-base/build-knowledge-package" in stages["build-search-index"]["command_or_core_action_note"]
    assert stages["build-search-index"]["works_without_vector_db"] is True


def test_campaign_2_reviewed_runs_prove_mixed_and_office_inputs():
    runs = {run["run_id"]: run for run in _matrix()["reviewed_runs"]}

    assert set(runs["real_mixed_e2e_20260612_102508"]["input_mix"]) == {
        "diagnostics.txt",
        "sample_marker_pdf.pdf",
        "sample_paddleocr_image.png",
        "supply_chain_notes.md",
    }
    assert set(runs["office_table_e2e_20260612_105706"]["input_mix"]) == {
        "001_table_claims.xlsx",
        "002_table_claims.csv",
        "003_methodology.md",
    }
    assert "kb-query" in runs["real_mixed_e2e_20260612_102508"]["covered_chain"]
    assert "verify-claims" in runs["office_table_e2e_20260612_105706"]["covered_chain"]
