from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_build_risk_labels_writes_reliability_report(tmp_path):
    input_dir = tmp_path / "input"
    output = tmp_path / "output"
    input_dir.mkdir()
    (input_dir / "scan.md").write_text("[Page 1]\nOCR table Column A content.", encoding="utf-8")

    result = CliRunner().invoke(app, ["build", "--input", str(input_dir), "--output", str(output), "--risk-labels"])

    assert result.exit_code == 0, result.output
    labels = (output / "risk_labels.jsonl").read_text(encoding="utf-8")
    assert "ocr_uncertain" in labels or "table_best_effort" in labels
    assert (output / "source_reliability_report.md").exists()
