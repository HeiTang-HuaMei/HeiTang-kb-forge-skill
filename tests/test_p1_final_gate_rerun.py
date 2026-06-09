import json
from pathlib import Path

from heitang_kb_forge.workbench import P1_FINAL_GATE_RERUN_FILES, write_p1_final_gate_rerun
from heitang_kb_forge.workbench.final_gate_rerun import PROVIDER_SECRET_NETWORK_ACTION_IDS


ROOT = Path(__file__).resolve().parents[1]
AUDIT = ROOT / "docs" / "audits" / "p1_final_gate_rerun"


def test_p1_final_gate_rerun_can_be_regenerated_from_committed_evidence(tmp_path):
    report = write_p1_final_gate_rerun(ROOT, tmp_path / "rerun")

    assert report["p1_final_gate_status"] == "ready_for_v4_rc"
    assert report["p1_full_operation_gate_status"] == "ready_for_v4_rc"
    assert report["ready_for_v4_rc"] is True
    assert report["ready_for_v4_rc_candidate"] is True
    assert report["ui_full_operation_pending"] is False
    assert report["p1_real_workflow_v1_status"] == "passed"
    assert report["p1_real_workflow_v2_status"] == "passed"
    assert report["execution_target_count"] == 57
    assert report["passed_action_count"] == 57
    assert report["failed_action_count"] == 0
    assert report["user_path_count"] == 10
    assert report["user_path_passed_count"] == 10
    assert report["drift_count"] == 0
    assert report["command_surface_drift_count"] == 0
    assert report["provider_secret_network_action_ids"] == PROVIDER_SECRET_NETWORK_ACTION_IDS
    assert report["provider_secret_network_actions_real_local_passed"] is False
    assert report["v4_0_started"] is False
    assert report["tag_created"] is False
    assert report["v4_release_written"] is False
    assert report["production_release_complete"] is False
    assert report["external_project_implemented"] is False

    for filename in P1_FINAL_GATE_RERUN_FILES:
        assert (tmp_path / "rerun" / filename).exists(), filename


def test_committed_p1_final_gate_rerun_reports_ready_without_release_overclaim():
    report = _json(AUDIT / "p1_final_gate_report.json")
    core = _json(AUDIT / "p1_core_validation_summary.json")
    ui = _json(AUDIT / "p1_ui_validation_summary.json")
    provider = _json(AUDIT / "p1_provider_blocked_boundary_report.json")
    risks = _json(AUDIT / "p1_remaining_risks.json")
    security = _json(AUDIT / "p1_security_release_hygiene_report.json")

    assert report["p1_final_gate_status"] == "ready_for_v4_rc"
    assert report["p1_full_operation_gate_status"] == "ready_for_v4_rc"
    assert report["ready_for_v4_rc"] is True
    assert report["ready_for_v4_rc_candidate"] is True
    assert report["ui_full_operation_pending"] is False
    assert report["blockers"] == []
    assert report["execution_target_count"] == 57
    assert report["passed_action_count"] == 57
    assert report["failed_action_count"] == 0
    assert report["user_path_count"] == 10
    assert report["user_path_passed_count"] == 10
    assert report["drift_count"] == 0
    assert report["command_surface_drift_count"] == 0

    assert core["status"] == "pass"
    assert ui["status"] == "pass"
    assert ui["source_commit"] == report["core_commit"]
    assert ui["drift_count"] == 0
    assert ui["flutter_asset_matches_ui_fixture"] is True

    assert provider["status"] == "pass"
    assert provider["provider_secret_network_action_ids"] == PROVIDER_SECRET_NETWORK_ACTION_IDS
    assert provider["provider_secret_network_actions_real_local_passed"] is False
    assert len(provider["explicit_config_exclusions"]) == 5

    assert risks["blockers"] == []
    assert security["no_build_artifacts_committed"] is True
    assert security["no_real_secret_detected"] is True
    assert security["v4_0_started"] is False
    assert security["tag_created"] is False
    assert security["v4_release_written"] is False


def _json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))
