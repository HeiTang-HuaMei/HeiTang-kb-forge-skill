import json
import shutil
from pathlib import Path

from heitang_kb_forge.stop_handoff_gate import (
    REQUIRED_STOP_HANDOFF_FILES,
    check_stop_handoff_gate,
)
from tests.v17_helpers import read_json


def test_stop_handoff_gate_passes_current_repository(tmp_path):
    repo = Path(__file__).resolve().parents[1]
    report = check_stop_handoff_gate(repo, tmp_path)

    persisted = read_json(tmp_path / "stop_handoff_gate_report.json")
    assert report.status == "passed"
    assert report.failed_checks == []
    assert report.queue_status["current_gate"] == report.queue_status["first_remaining"]
    assert report.queue_status["remaining_count"] >= 1
    assert report.queue_status["checks"]["global_goal_complete_false_while_remaining"] is True
    assert report.handoff_contract["checks"]["stop_fields_present"] is True
    assert report.registry_status["checks"]["close_allowed_true"] is True
    assert report.registry_status["checks"]["next_gate_in_chain"] is True
    assert report.forbidden_claims["allowed_final_status_present"] is True
    assert persisted["schema_version"] == "stop_handoff_gate.v1"
    assert persisted["boundary"]["ui_change"] == "not_required"
    assert persisted["boundary"]["runtime_change"] == "not_required"


def test_stop_handoff_gate_fails_when_status_file_missing(tmp_path):
    report = check_stop_handoff_gate(tmp_path, tmp_path / "out")

    assert report.status == "failed"
    assert "missing_required_stop_handoff_files" in report.failed_checks
    assert "capability_chain_status.json" in report.missing_files


def test_stop_handoff_gate_rejects_completed_remaining_overlap(tmp_path):
    repo = _copy_required_repo(tmp_path)
    status_path = repo / "capability_chain_status.json"
    state = json.loads(status_path.read_text(encoding="utf-8"))
    state["completed_with_owner_review_needed"].append(state["remaining_gates"][0])
    status_path.write_text(json.dumps(state, ensure_ascii=False, indent=2), encoding="utf-8")

    report = check_stop_handoff_gate(repo)

    assert report.status == "failed"
    assert "completed_and_remaining_disjoint" in report.failed_checks


def test_stop_handoff_gate_rejects_missing_handoff_contract_field(tmp_path):
    repo = _copy_required_repo(tmp_path)
    policy_path = repo / "docs/capability_registry/Full_Target_Mode_Blocker_Policy.md"
    text = policy_path.read_text(encoding="utf-8").replace("blocked_reason", "blocked cause")
    policy_path.write_text(text, encoding="utf-8")

    report = check_stop_handoff_gate(repo)

    assert report.status == "failed"
    assert "stop_fields_present" in report.failed_checks
    assert "blocked_reason" in report.handoff_contract["missing_stop_fields"]


def _copy_required_repo(tmp_path) -> Path:
    source = Path(__file__).resolve().parents[1]
    repo = tmp_path / "repo"
    for relative in REQUIRED_STOP_HANDOFF_FILES:
        source_path = source / relative
        target_path = repo / relative
        target_path.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source_path, target_path)
    release_gates = source / "docs/capability_registry/Release_Gates.md"
    release_target = repo / "docs/capability_registry/Release_Gates.md"
    release_target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(release_gates, release_target)
    return repo
