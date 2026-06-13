import json
import subprocess
from pathlib import Path

from typer.testing import CliRunner

from heitang_kb_forge.cli import app
from heitang_kb_forge.parser_backends import marker_adapter
from heitang_kb_forge.parser_backends.document_backend_contract import AdapterResult


def _json(path):
    return json.loads(path.read_text(encoding="utf-8"))


def _install_fake_marker_cli(monkeypatch, expected_cache=None):
    monkeypatch.setattr(marker_adapter, "find_spec", lambda name: object())
    monkeypatch.setattr(marker_adapter.shutil, "which", lambda name: "marker_single")

    def fake_run(command, cwd, env, text, stdout, stderr, timeout):
        assert "--use_llm" not in command
        assert command[command.index("--output_format") + 1] == "json"
        assert env["TORCH_DEVICE"] == "cpu"
        assert env["MODEL_CACHE_DIR"] == env["HEITANG_MARKER_MODEL_CACHE"]
        if expected_cache is not None:
            assert env["MODEL_CACHE_DIR"] == str(expected_cache.resolve())
        output_dir = Path(command[command.index("--output_dir") + 1])
        source = Path(command[1])
        target = output_dir / source.stem
        target.mkdir(parents=True, exist_ok=True)
        (target / f"{source.stem}.json").write_text(
            json.dumps(
                {
                    "children": [
                        {
                            "id": "/page/0/SectionHeader/0",
                            "block_type": "SectionHeader",
                            "html": "<h2>Marker document</h2>",
                        },
                        {
                            "id": "/page/0/Text/1",
                            "block_type": "Text",
                            "html": "<p>Normalized Marker text.</p>",
                        },
                        {
                            "id": "/page/0/Table/2",
                            "block_type": "Table",
                            "html": "<table><tr><td>Table value</td></tr></table>",
                        },
                    ]
                }
            ),
            encoding="utf-8",
        )
        return subprocess.CompletedProcess(command, 0, stdout="ok", stderr="")

    monkeypatch.setattr(marker_adapter.subprocess, "run", fake_run)


def test_check_marker_backend_reports_missing_dependency_truthfully(tmp_path, monkeypatch):
    monkeypatch.setattr(marker_adapter, "find_spec", lambda name: None)
    monkeypatch.setattr(marker_adapter.shutil, "which", lambda name: None)
    output = tmp_path / "check"
    model_cache = tmp_path / "model_cache"

    result = CliRunner().invoke(
        app,
        ["check-marker-backend", "--output", str(output), "--model-cache", str(model_cache)],
    )

    assert result.exit_code == 0, result.output
    payload = _json(output / "marker_integration_decision_report.json")
    assert payload["decision"] == "real_integration"
    assert payload["current_environment_status"] == "blocked_by_dependency"
    assert payload["dependency_status"] == "missing"
    assert payload["runtime_status"] == "blocked_by_dependency"
    assert payload["smoke_status"] == "not_run"
    assert payload["capabilities"]["stable_markdown_or_json_output"] is True
    assert payload["capabilities"]["runtime_invocation_blocked_until_strengthened"] is False
    assert payload["capabilities"]["model_cache_path"] == str(model_cache.resolve())
    remediation = _json(output / "marker_dependency_remediation_report.json")
    assert remediation["new_cache_path"] == str(model_cache.resolve())
    assert "old_cache_path" in remediation
    assert "cache_size" in remediation
    assert "migration_performed" in remediation
    assert "migration_needed" in remediation
    assert remediation["cleanup_suggestion"]
    ui_note = _json(output / "marker_ui_impact_note.json")
    assert ui_note["ui_status"] == "dependency_missing"
    assert ui_note["model_cache_path"] == str(model_cache.resolve())
    assert (output / "marker_integration_decision_report.md").exists()


def test_marker_check_requires_real_cli_even_when_package_is_importable(tmp_path, monkeypatch):
    monkeypatch.setattr(marker_adapter, "find_spec", lambda name: object())
    monkeypatch.setattr(marker_adapter.shutil, "which", lambda name: None)
    monkeypatch.setattr(marker_adapter.sys, "executable", str(tmp_path / "python.exe"))

    available, reason = marker_adapter.MarkerParserBackend().is_available()

    assert available is False
    assert "CLI" in reason


def test_smoke_marker_backend_passes_with_runtime_fixture(tmp_path, monkeypatch):
    source = tmp_path / "document.pdf"
    source.write_bytes(b"%PDF fake fixture")
    output = tmp_path / "smoke"
    model_cache = tmp_path / "model_cache"
    _install_fake_marker_cli(monkeypatch, model_cache)

    result = CliRunner().invoke(
        app,
        [
            "smoke-marker-backend",
            "--input",
            str(source),
            "--output",
            str(output),
            "--model-cache",
            str(model_cache),
        ],
    )

    assert result.exit_code == 0, result.output
    payload = _json(output / "marker_smoke_report.json")
    adapter_result = payload["adapter_smoke_report"]["result"]
    run_record = payload["run"]["records"][0]
    assert payload["status"] == "pass"
    assert payload["adapter_smoke_report"]["status"] == "pass"
    assert payload["output_non_empty"] is True
    assert payload["output_schema_readable"] is True
    assert payload["llm_request_count"] == 0
    assert payload["llm_tokens_used"] == 0
    decision = _json(output / "marker_integration_decision_report.json")
    assert decision["runtime_status"] == "available"
    assert decision["smoke_status"] == "passed"
    assert adapter_result["status"] == "success"
    assert "Normalized Marker text" in run_record["text"]
    assert run_record["metadata"]["runtime_invoked"] is True
    assert run_record["metadata"]["use_llm"] is False
    assert run_record["metadata"]["llm_request_count"] == 0
    assert run_record["metadata"]["llm_tokens_used"] == 0
    assert run_record["metadata"]["model_cache_path"] == str(model_cache.resolve())
    assert run_record["metadata"]["layout_block_count"] == 3
    assert run_record["metadata"]["table_count"] == 1
    assert adapter_result["source_trace"][0]["page"] == 1
    remediation = _json(output / "marker_dependency_remediation_report.json")
    assert remediation["smoke_status"] == "passed"
    assert remediation["license_gate_status"] == "license_gate_pending"
    ui_note = _json(output / "marker_ui_impact_note.json")
    assert ui_note["ui_status"] == "available_smoke_passed_license_gate_pending"
    AdapterResult.model_validate(adapter_result)


def test_run_marker_convert_records_cache_and_zero_llm_usage(tmp_path, monkeypatch):
    source = tmp_path / "document.pdf"
    source.write_bytes(b"%PDF fake fixture")
    output = tmp_path / "run"
    model_cache = tmp_path / "model_cache"
    _install_fake_marker_cli(monkeypatch, model_cache)

    result = CliRunner().invoke(
        app,
        [
            "run-marker-convert",
            "--input",
            str(source),
            "--output",
            str(output),
            "--model-cache",
            str(model_cache),
        ],
    )

    assert result.exit_code == 0, result.output
    payload = _json(output / "marker_convert_result.json")
    assert payload["status"] == "success"
    assert payload["output_non_empty"] is True
    assert payload["output_schema_readable"] is True
    assert payload["llm_request_count"] == 0
    assert payload["llm_tokens_used"] == 0
    assert payload["model_cache_path"] == str(model_cache.resolve())
