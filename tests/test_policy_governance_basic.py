from pathlib import Path

from heitang_kb_forge.policy_governance import check_policy_governance
from tests.v17_helpers import read_json


def test_policy_governance_passes_current_repository(tmp_path):
    repo = Path(__file__).resolve().parents[1]
    report = check_policy_governance(repo, tmp_path)

    persisted = read_json(tmp_path / "policy_governance_basic_report.json")
    assert report.status == "passed"
    assert report.failed_checks == []
    assert report.queue_status["current_gate"] == report.queue_status["first_remaining"]
    assert report.queue_status["remaining_count"] >= 1
    assert report.queue_status["checks"]["global_goal_complete_false"] is True
    assert report.blocker_policy["soft_blockers_present"] is True
    assert report.blocker_policy["hard_blockers_present"] is True
    assert report.forbidden_claims["allowed_final_status_present"] is True
    assert persisted["schema_version"] == "policy_governance_basic.v1"
    assert persisted["boundary"]["ui_change"] == "not_required"
    assert persisted["boundary"]["runtime_change"] == "not_required"


def test_policy_governance_fails_when_required_file_missing(tmp_path):
    report = check_policy_governance(tmp_path, tmp_path / "out")

    assert report.status == "failed"
    assert "missing_required_policy_files" in report.failed_checks
    assert "capability_chain_status.json" in report.missing_files
