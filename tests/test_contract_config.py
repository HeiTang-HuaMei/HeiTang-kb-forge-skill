import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_config_multimodal_and_contract_blocks(tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    config = tmp_path / "v16.yaml"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("Config v16 fixture.", encoding="utf-8")
    (input_dir / "chart.webp").write_bytes(b"fake image")
    config.write_text(
        f"""
task: build
input: {input_dir.as_posix()}
output: {output_dir.as_posix()}
multimodal:
  enabled: true
contract:
  version: v2
  check: true
""",
        encoding="utf-8",
    )

    result = CliRunner().invoke(app, ["run", "--config", str(config)])

    assert result.exit_code == 0, result.output
    assert (output_dir / "multimodal_assets.jsonl").exists()
    assert json.loads((output_dir / "manifest.json").read_text(encoding="utf-8"))["contract_version"] == "2.0"
    assert json.loads((output_dir / "contract_check_result.json").read_text(encoding="utf-8"))["status"] == "pass"
