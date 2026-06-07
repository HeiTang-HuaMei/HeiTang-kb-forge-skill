import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app
from heitang_kb_forge.config.loader import load_config


def test_v311_config_defaults(tmp_path):
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

    assert loaded.golden_demo_acceptance.enabled is False
    assert loaded.golden_demo_acceptance.allow_llm is False
    assert loaded.golden_demo_acceptance.allow_network is False
    assert loaded.golden_demo_acceptance.require_v310 is True


def test_run_config_v311_full_acceptance_chain_writes_manifest(tmp_path):
    input_dir = tmp_path / "input"
    output = tmp_path / "output"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("Pricing is 20 dollars. Revenue is growing. Local runtime evidence.", encoding="utf-8")
    config = tmp_path / "run.yaml"
    config.write_text(
        f"""
task: build
input: {input_dir.as_posix()}
output: {output.as_posix()}
query_rewrite:
  enabled: true
  retrieval_purpose: validation
retrieval_quality:
  enabled: true
workspace_storage:
  enabled: true
memory_lifecycle:
  enabled: true
local_agent_runtime:
  enabled: true
  task: pricing evidence
golden_demo_acceptance:
  enabled: true
""",
        encoding="utf-8",
    )

    result = CliRunner().invoke(app, ["run", "--config", str(config)])

    assert result.exit_code == 0, result.output
    manifest = _json(output / "manifest.json")
    acceptance = _json(output / "real_acceptance_smoke_result.json")
    assert manifest["golden_demo_acceptance_enabled"] is True
    assert manifest["golden_demo_acceptance_llm_required"] is False
    assert acceptance["status"] == "pass"
    assert (output / "artifact_openability_report.json").exists()


def test_run_config_v311_rejects_llm_and_network(tmp_path):
    input_dir = tmp_path / "input"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("x", encoding="utf-8")
    config = tmp_path / "run.yaml"
    config.write_text(
        f"""
task: build
input: {input_dir.as_posix()}
output: {(tmp_path / "output").as_posix()}
golden_demo_acceptance:
  enabled: true
  allow_llm: true
""",
        encoding="utf-8",
    )

    result = CliRunner().invoke(app, ["run", "--config", str(config)])

    assert result.exit_code != 0
    assert "golden_demo_acceptance.allow_llm must remain false" in result.output


def test_default_build_does_not_emit_v311_reports(tmp_path):
    input_dir = tmp_path / "input"
    output = tmp_path / "output"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("No v3.11 opt in.", encoding="utf-8")

    result = CliRunner().invoke(app, ["build", "--input", str(input_dir), "--output", str(output)])

    assert result.exit_code == 0, result.output
    assert not (output / "real_acceptance_smoke_result.json").exists()
    assert "golden_demo_acceptance_enabled" not in _json(output / "manifest.json")


def _json(path):
    return json.loads(path.read_text(encoding="utf-8"))
