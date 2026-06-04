import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_pipeline_reports_multimodal_and_contract_stages(tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    config = tmp_path / "pipeline.yaml"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("Pipeline v16 fixture.", encoding="utf-8")
    (input_dir / "diagram.png").write_bytes(b"fake image")
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

    result = CliRunner().invoke(app, ["pipeline", "--config", str(config)])

    assert result.exit_code == 0, result.output
    manifest = json.loads((output_dir / "pipeline_manifest.json").read_text(encoding="utf-8"))
    stages = {stage["name"]: stage for stage in manifest["stages"]}
    assert stages["multimodal_asset_extraction"]["status"] == "success"
    assert stages["multimodal_evidence_mapping"]["status"] == "success"
    assert stages["package_contract_check"]["status"] == "success"
