import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_batch_retry_only_failed_updates_retry_count(tmp_path):
    input_dir = tmp_path / "input"
    output = tmp_path / "output"
    input_dir.mkdir()
    (input_dir / "001_bad.xyz").write_text("Unsupported fixture.", encoding="utf-8")
    assert CliRunner().invoke(app, ["batch-run", "--input", str(input_dir), "--output", str(output)]).exit_code == 0

    result = CliRunner().invoke(app, ["batch-retry", "--batch-job", str(output / "batch_job_manifest.json"), "--retry-only-failed"])

    assert result.exit_code == 0, result.output
    rows = [json.loads(line) for line in (output / "batch_item_status.jsonl").read_text(encoding="utf-8").splitlines()]
    assert rows[0]["retry_count"] == 1
    assert (output / "batch_retry_report.md").exists()

