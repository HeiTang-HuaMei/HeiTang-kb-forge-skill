import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app
from heitang_kb_forge.config.loader import load_config


def test_v312_config_defaults(tmp_path):
    input_dir = tmp_path / "input"
    input_dir.mkdir()
    config = tmp_path / "run.yaml"
    config.write_text(
        f"""
task: build
input: {input_dir.as_posix()}
output: {(tmp_path / "out").as_posix()}
""",
        encoding="utf-8",
    )

    loaded = load_config(config)

    assert loaded.product_hardening.enabled is False
    assert loaded.product_hardening.allow_llm is False
    assert loaded.product_hardening.allow_network is False
    assert loaded.product_hardening.require_v311 is True


def test_run_config_product_hardening_writes_manifest(tmp_path):
    input_dir = tmp_path / "input"
    output = tmp_path / "output"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("Product hardening config evidence.", encoding="utf-8")
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
""",
        encoding="utf-8",
    )

    result = CliRunner().invoke(app, ["run", "--config", str(config)])

    assert result.exit_code == 0, result.output
    manifest = json.loads((output / "manifest.json").read_text(encoding="utf-8"))
    assert manifest["product_hardening_enabled"] is True
    assert manifest["product_hardening_network_required"] is False
    assert (output / "v312_external_absorption_map.json").exists()


def test_run_config_product_hardening_rejects_network(tmp_path):
    input_dir = tmp_path / "input"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("x", encoding="utf-8")
    config = tmp_path / "run.yaml"
    config.write_text(
        f"""
task: build
input: {input_dir.as_posix()}
output: {(tmp_path / "output").as_posix()}
product_hardening:
  enabled: true
  allow_network: true
""",
        encoding="utf-8",
    )

    result = CliRunner().invoke(app, ["run", "--config", str(config)])

    assert result.exit_code != 0
    assert "product_hardening.allow_network must remain false" in result.output
