import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_v25_config_run_generates_release_quality_outputs(tmp_path):
    input_dir = tmp_path / "input"
    output = tmp_path / "output"
    config = tmp_path / "v25.yaml"
    input_dir.mkdir()
    (input_dir / "001_note.md").write_text("v25 config fixture.", encoding="utf-8")
    config.write_text(
        f"""
task: build
input: {input_dir.as_posix()}
output: {output.as_posix()}
skill:
  enabled: true
agent_package:
  enabled: true
  compat: true
platform_distribution:
  enabled: true
  platform: all
quality_gate:
  enabled: true
release_blockers:
  enabled: true
regression:
  enabled: true
golden_samples:
  enabled: true
  validate: true
  samples_root: examples/golden_samples
export_certification:
  enabled: true
compatibility_matrix:
  enabled: true
llm_quality_gate_assist:
  enabled: true
  provider: mock
release_readiness:
  enabled: true
""",
        encoding="utf-8",
    )

    result = CliRunner().invoke(app, ["run", "--config", str(config)])

    assert result.exit_code == 0, result.output
    assert (output / "quality_gate_result.json").exists()
    assert (output / "release_blockers.json").exists()
    assert (output / "regression_result.json").exists()
    assert (output / "golden_sample_validation.json").exists()
    assert (output / "platform_export_certification.json").exists()
    assert (output / "compatibility_matrix.json").exists()
    assert (output / "llm_quality_gate_assist_result.json").exists()
    payload = json.loads((output / "release_readiness_result.json").read_text(encoding="utf-8"))
    assert "release_ready" in payload

