import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_pipeline_shows_product_hardening_when_enabled(tmp_path):
    input_dir = tmp_path / "input"
    output = tmp_path / "output"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("Product hardening pipeline evidence.", encoding="utf-8")
    config = tmp_path / "run.yaml"
    config.write_text(
        f"""
task: build
input: {input_dir.as_posix()}
output: {output.as_posix()}
golden_demo_acceptance:
  enabled: true
  require_v37: false
  require_v38: false
  require_v39: false
  require_v310: false
product_hardening:
  enabled: true
  require_v37: false
  require_v38: false
  require_v39: false
  require_v310: false
workbench_contracts:
  enabled: true
""",
        encoding="utf-8",
    )

    result = CliRunner().invoke(app, ["pipeline", "--config", str(config)])

    assert result.exit_code == 0, result.output
    manifest = json.loads((output / "pipeline_manifest.json").read_text(encoding="utf-8"))
    stage = next(item for item in manifest["stages"] if item["name"] == "product_hardening_release_readiness")
    assert stage["enabled"] is True
    assert stage["status"] == "success"
    status = json.loads((output / "workbench_status_contract.json").read_text(encoding="utf-8"))
    assert status["product_hardening_available"] is True
    assert status["local_release_readiness_available"] is True
