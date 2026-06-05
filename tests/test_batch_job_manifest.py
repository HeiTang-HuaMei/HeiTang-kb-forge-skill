import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_batch_run_generates_v23_job_manifest_and_summaries(tmp_path):
    input_dir = tmp_path / "input"
    output = tmp_path / "output"
    input_dir.mkdir()
    (input_dir / "001_alpha.md").write_text("Alpha batch fixture.", encoding="utf-8")
    (input_dir / "002_bad.xyz").write_text("Unsupported fixture.", encoding="utf-8")

    result = CliRunner().invoke(app, ["batch-run", "--input", str(input_dir), "--output", str(output), "--profile", "production"])

    assert result.exit_code == 0, result.output
    manifest = json.loads((output / "batch_job_manifest.json").read_text(encoding="utf-8"))
    assert manifest["total_items"] == 2
    assert manifest["success_count"] == 1
    assert manifest["failed_count"] == 1
    assert manifest["profile"] == "production"
    assert (output / "batch_item_status.jsonl").exists()
    assert (output / "batch_failure_report.md").exists()
    assert (output / "batch_performance_report.md").exists()
    assert (output / "batch_quality_summary.json").exists()
    assert (output / "batch_contract_summary.json").exists()
    assert (output / "batch_governance_summary.json").exists()

