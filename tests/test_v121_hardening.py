import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_build_quality_gate_and_run_manifest_outputs(tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("V1.2.1 hardening fixture.", encoding="utf-8")

    result = CliRunner().invoke(
        app,
        [
            "build",
            "--input",
            str(input_dir),
            "--output",
            str(output_dir),
            "--quality-gate",
            "--run-manifest",
        ],
    )

    assert result.exit_code == 0, result.output
    for name in [
        "quality_gate_report.json",
        "quality_gate_summary.md",
        "package_acceptance_report.md",
        "package_validation_report.json",
        "package_readiness_report.md",
        "run_manifest.json",
        "stage_trace.jsonl",
        "error_report.json",
    ]:
        assert (output_dir / name).exists()

    manifest = json.loads((output_dir / "manifest.json").read_text(encoding="utf-8"))
    assert manifest["quality_gate_enabled"] is True
    assert manifest["quality_gate_status"] in {"pass", "warning", "fail"}
    assert "quality_gate_report.json" in manifest["files"]
    run_manifest = json.loads((output_dir / "run_manifest.json").read_text(encoding="utf-8"))
    assert run_manifest["run_manifest_version"] == "1.2.1"
    assert run_manifest["status"] in {"success", "failed"}


def test_quality_gate_strict_fails_zero_chunk_package(tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    input_dir.mkdir()
    (input_dir / "empty.md").write_text("", encoding="utf-8")

    result = CliRunner().invoke(
        app,
        [
            "build",
            "--input",
            str(input_dir),
            "--output",
            str(output_dir),
            "--quality-gate-strict",
            "--run-manifest",
        ],
    )

    assert result.exit_code != 0
    gate = json.loads((output_dir / "quality_gate_report.json").read_text(encoding="utf-8"))
    assert gate["status"] == "fail"
    assert "chunk_count_is_zero" in gate["reasons"]


def test_batch_writes_hardening_outputs_and_supports_fail_fast(tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    input_dir.mkdir()
    (input_dir / "001_bad.xyz").write_text("Unsupported.", encoding="utf-8")
    (input_dir / "002_good.md").write_text("Should not run when fail-fast is enabled.", encoding="utf-8")

    result = CliRunner().invoke(
        app,
        [
            "batch",
            "--input",
            str(input_dir),
            "--output",
            str(output_dir),
            "--fail-fast",
        ],
    )

    assert result.exit_code == 0, result.output
    for name in ["batch_run_summary.json", "batch_run_report.md", "failed_items.jsonl", "retry_manifest.json"]:
        assert (output_dir / name).exists()

    manifest = json.loads((output_dir / "batch_manifest.json").read_text(encoding="utf-8"))
    assert manifest["total_files"] == 2
    assert len(manifest["items"]) == 1
    assert manifest["items"][0]["sequence_id"] == "001"
    assert manifest["items"][0]["status"] == "failed"
    summary = json.loads((output_dir / "batch_run_summary.json").read_text(encoding="utf-8"))
    assert summary["failed"] == 1
    assert summary["fail_fast"] is True
