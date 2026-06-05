import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_v17_pipeline_reports_governance_retrieval_and_gate_stages(tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    config_path = tmp_path / "kb_forge.v17.yaml"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("HeiTang pipeline evidence package", encoding="utf-8")
    config_path.write_text(
        f"""
task: build
input: {input_dir.as_posix()}
output: {output_dir.as_posix()}
governance:
  enabled: true
retrieval:
  enabled: true
evidence_gate:
  enabled: true
  query: HeiTang evidence
""",
        encoding="utf-8",
    )

    result = CliRunner().invoke(app, ["pipeline", "--config", str(config_path)])

    assert result.exit_code == 0, result.output
    manifest = json.loads((output_dir / "pipeline_manifest.json").read_text(encoding="utf-8"))
    stage_names = {stage["name"] for stage in manifest["stages"]}
    assert {"governance_analysis", "retrieval_index", "evidence_gate"}.issubset(stage_names)
    report = (output_dir / "pipeline_report.md").read_text(encoding="utf-8")
    assert "governance_analysis" in report
