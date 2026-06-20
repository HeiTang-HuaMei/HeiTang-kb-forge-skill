import json

from heitang_kb_forge.exporters.jsonl_exporter import write_json, write_jsonl
from heitang_kb_forge.workbench.action_executor import _command_output_manifest, _read_json
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


def test_command_output_manifest_records_binary_size_before_omitting(tmp_path):
    command_output = tmp_path / "command_outputs" / "generate_manual_user_guide"
    command_output.mkdir(parents=True)
    pdf = command_output / "generated.pdf"
    pdf.write_bytes(b"%PDF-1.4\n")
    markdown = command_output / "generated.md"
    markdown.write_text("# Generated", encoding="utf-8")

    manifest = _command_output_manifest(command_output)

    files = {item["path"]: item for item in manifest["files"]}
    assert files["generated.pdf"]["size_bytes"] == 9
    assert files["generated.pdf"]["commit_policy"] == "omitted_binary_or_raw_command_output"
    assert files["generated.md"]["size_bytes"] == len("# Generated")
    assert files["generated.md"]["commit_policy"] == "summarized_only"
    assert not pdf.exists()
    assert markdown.exists()


def test_atomic_json_writer_leaves_readable_final_file_without_tmp(tmp_path):
    path = tmp_path / "reports" / "result.json"

    write_json(path, {"status": "passed", "count": 2})

    assert _read_json(path) == {"status": "passed", "count": 2}
    assert list(path.parent.glob("*.tmp")) == []
