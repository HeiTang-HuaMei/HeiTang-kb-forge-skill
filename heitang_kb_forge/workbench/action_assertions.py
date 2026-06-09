from __future__ import annotations

import json
from pathlib import Path


def assert_action_run(run_dir: Path) -> dict:
    action_result = _read_json(run_dir / "action_result.json")
    artifact_index = _read_json(run_dir / "artifact_index.json")
    report_index = _read_json(run_dir / "report_index.json")
    task_events = _read_jsonl(run_dir / "task_events.jsonl")
    error_observation = _read_json(run_dir / "error_observation.json")
    checks = []
    status = action_result.get("status")
    if status == "passed":
        checks.extend(
            [
                _check("command_exit_code_zero", action_result.get("command_exit_code") == 0),
                _check("output_path_existed", action_result.get("output_path_existed") is True),
                _check("has_report_artifact_or_task_event", bool(report_index.get("reports") or artifact_index.get("artifacts") or task_events)),
                _check("not_blocked", not action_result.get("blocked_reason")),
            ]
        )
    elif status == "blocked":
        checks.extend(
            [
                _check("blocked_reason_present", bool(action_result.get("blocked_reason"))),
                _check("not_real_local_passed", action_result.get("evidence_level") != "real_local_workflow"),
            ]
        )
    elif status == "failed":
        checks.extend(
            [
                _check("error_code_present", bool(error_observation.get("error_code"))),
                _check("repair_suggestion_present", bool(error_observation.get("repair_suggestion"))),
            ]
        )
    elif status == "review_required":
        checks.append(_check("review_reason_present", bool(action_result.get("blocked_reason") or error_observation.get("review_reason"))))
    else:
        checks.append(_check("known_status", False, f"unknown status: {status}"))
    if action_result.get("evidence_level") == "deterministic_smoke":
        checks.append(_check("smoke_not_full_business_execution", bool(action_result.get("deterministic_smoke_reason"))))
    assertion_status = "passed" if all(item["passed"] for item in checks) else "failed"
    return {
        "action_id": action_result.get("action_id"),
        "status": assertion_status,
        "checks": checks,
    }


def _check(check_id: str, passed: bool, detail: str | None = None) -> dict:
    return {"check_id": check_id, "passed": bool(passed), "detail": detail}


def _read_json(path: Path) -> dict:
    if not path.exists():
        return {}
    return json.loads(path.read_text(encoding="utf-8"))


def _read_jsonl(path: Path) -> list[dict]:
    if not path.exists():
        return []
    rows = []
    for line in path.read_text(encoding="utf-8").splitlines():
        if line.strip():
            rows.append(json.loads(line))
    return rows
