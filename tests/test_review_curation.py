import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_review_create_and_apply(tmp_path):
    input_dir = tmp_path / "input"
    package = tmp_path / "package"
    review = tmp_path / "review"
    curated = tmp_path / "curated"
    input_dir.mkdir()
    (input_dir / "scan.md").write_text("[Page 1]\nOCR table content for review.", encoding="utf-8")
    runner = CliRunner()
    assert runner.invoke(app, ["build", "--input", str(input_dir), "--output", str(package), "--risk-labels"]).exit_code == 0

    create = runner.invoke(app, ["review-create", "--package", str(package), "--output", str(review)])
    decisions = [json.loads(line) for line in (review / "review_decisions.jsonl").read_text(encoding="utf-8").splitlines() if line]
    decisions[0]["decision"] = "revise"
    decisions[0]["revised_text"] = "Curated text."
    (review / "review_decisions.jsonl").write_text("\n".join(json.dumps(item) for item in decisions) + "\n", encoding="utf-8")
    apply = runner.invoke(app, ["review-apply", "--package", str(package), "--decisions", str(review / "review_decisions.jsonl"), "--output", str(curated)])

    assert create.exit_code == 0, create.output
    assert apply.exit_code == 0, apply.output
    assert "Curated text" in (curated / "curated_chunks.jsonl").read_text(encoding="utf-8")
    assert (curated / "curation_report.md").exists()
