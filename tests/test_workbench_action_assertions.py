import json

from heitang_kb_forge.exporters.jsonl_exporter import write_json, write_jsonl
from heitang_kb_forge.workbench.action_assertions import assert_action_run


def test_action_assertion_handles_empty_error_observation_as_failed_assertion(tmp_path):
    run_dir = tmp_path / "run"
    run_dir.mkdir()
    write_json(
        run_dir / "action_result.json",
        {
            "action_id": "provider_failure_fixture",
            "status": "failed",
            "evidence_level": "blocked",
        },
    )
    write_json(run_dir / "artifact_index.json", {"artifacts": []})
    write_json(run_dir / "report_index.json", {"reports": []})
    write_jsonl(run_dir / "task_events.jsonl", [])
    (run_dir / "error_observation.json").write_text("", encoding="utf-8")

    assertion = assert_action_run(run_dir)

    assert assertion["status"] == "failed"
    assert [item["check_id"] for item in assertion["checks"]] == [
        "error_code_present",
        "repair_suggestion_present",
    ]
    assert all(item["passed"] is False for item in assertion["checks"])


def test_action_assertion_handles_malformed_error_observation_as_failed_assertion(tmp_path):
    run_dir = tmp_path / "run"
    run_dir.mkdir()
    write_json(
        run_dir / "action_result.json",
        {
            "action_id": "provider_failure_fixture",
            "status": "failed",
            "evidence_level": "blocked",
        },
    )
    write_json(run_dir / "artifact_index.json", {"artifacts": []})
    write_json(run_dir / "report_index.json", {"reports": []})
    write_jsonl(run_dir / "task_events.jsonl", [])
    (run_dir / "error_observation.json").write_text(
        json.dumps({"bad": "json"}) + "\ntrailing",
        encoding="utf-8",
    )

    assertion = assert_action_run(run_dir)

    assert assertion["status"] == "failed"
