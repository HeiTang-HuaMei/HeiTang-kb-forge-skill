import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_build_retrieval_eval_export_writes_eval_files(tmp_path):
    input_dir = tmp_path / "input"
    output = tmp_path / "output"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("Retrieval eval fixture with enough content for QA generation.", encoding="utf-8")

    result = CliRunner().invoke(app, ["build", "--input", str(input_dir), "--output", str(output), "--retrieval-eval-export"])

    assert result.exit_code == 0, result.output
    for name in ["retrieval_eval_set.jsonl", "golden_qa.jsonl", "citation_eval_set.jsonl"]:
        assert (output / name).exists()
    rows = [json.loads(line) for line in (output / "retrieval_eval_set.jsonl").read_text(encoding="utf-8").splitlines() if line]
    assert rows
    assert rows[0]["expected_citation"]
