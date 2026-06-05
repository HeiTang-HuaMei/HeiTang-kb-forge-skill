import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_v21_config_generates_quality_and_eval_outputs(tmp_path):
    input_dir = tmp_path / "input"
    output = tmp_path / "output"
    config = tmp_path / "v21.yaml"
    input_dir.mkdir()
    (input_dir / "001_note.md").write_text("KB Forge v21 config fixture.", encoding="utf-8")
    config.write_text(
        f"""
task: build
input: {input_dir.as_posix()}
output: {output.as_posix()}
input_hardening:
  enabled: true
quality:
  enabled: true
review:
  workflow: true
  curation: true
retrieval_eval:
  enabled: true
evidence_benchmark:
  enabled: true
llm_quality_assist:
  enabled: true
""",
        encoding="utf-8",
    )

    result = CliRunner().invoke(app, ["run", "--config", str(config)])

    assert result.exit_code == 0, result.output
    assert json.loads((output / "knowledge_quality_report.json").read_text(encoding="utf-8"))["overall_score"] >= 0
    assert (output / "retrieval_eval_result.json").exists()
    assert (output / "evidence_benchmark_result.json").exists()
