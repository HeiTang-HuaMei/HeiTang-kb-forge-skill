import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_batch_item_status_jsonl_records_item_outputs(tmp_path):
    input_dir = tmp_path / "input"
    output = tmp_path / "output"
    input_dir.mkdir()
    (input_dir / "001_doc.md").write_text("Status fixture.", encoding="utf-8")

    result = CliRunner().invoke(app, ["batch-run", "--input", str(input_dir), "--output", str(output)])

    assert result.exit_code == 0, result.output
    rows = [json.loads(line) for line in (output / "batch_item_status.jsonl").read_text(encoding="utf-8").splitlines()]
    assert rows[0]["item_id"] == "001"
    assert rows[0]["status"] == "success"
    assert "chunks.jsonl" in rows[0]["outputs"]

