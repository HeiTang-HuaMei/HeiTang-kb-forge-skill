import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_run_config_multi_kb_orchestration_defaults_to_build_output(tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    config_path = tmp_path / "v32.yaml"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("Multi KB orchestration config evidence.", encoding="utf-8")
    config_path.write_text(
        f"""
task: build
input: {input_dir.as_posix()}
output: {output_dir.as_posix()}
multi_kb_orchestration:
  enabled: true
  query: orchestration evidence
""",
        encoding="utf-8",
    )

    result = CliRunner().invoke(app, ["run", "--config", str(config_path)])

    assert result.exit_code == 0, result.output
    manifest = _json(output_dir / "multi_kb_orchestration_manifest.json")
    assert manifest["package_count"] == 1
    assert (output_dir / "multi_kb_route_map.json").exists()
    assert (output_dir / "hierarchy_trace.json").exists()


def _json(path):
    return json.loads(path.read_text(encoding="utf-8"))
