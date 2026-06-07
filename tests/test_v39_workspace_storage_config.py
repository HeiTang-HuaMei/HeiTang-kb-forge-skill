from typer.testing import CliRunner

from heitang_kb_forge.cli import app
from heitang_kb_forge.config.loader import load_config
from tests.v39_helpers import read_json


def test_v39_config_defaults(tmp_path):
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

    assert loaded.workspace_storage.enabled is False
    assert loaded.memory_lifecycle.enabled is False
    assert loaded.document_parsing.no_cloud_upload_required is True


def test_run_config_v39_writes_reports_and_manifest(tmp_path):
    input_dir = tmp_path / "input"
    output = tmp_path / "output"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("Local storage and memory evidence.", encoding="utf-8")
    config = tmp_path / "run.yaml"
    config.write_text(
        f"""
task: build
input: {input_dir.as_posix()}
output: {output.as_posix()}
workspace_storage:
  enabled: true
memory_lifecycle:
  enabled: true
  max_context_memory_items: 7
document_parsing:
  local_pdf_markdown: true
  parser_backend_benchmark: true
  pdf_token_reduction_report: true
""",
        encoding="utf-8",
    )

    result = CliRunner().invoke(app, ["run", "--config", str(config)])

    assert result.exit_code == 0, result.output
    manifest = read_json(output / "manifest.json")
    assert manifest["workspace_storage_enabled"] is True
    assert manifest["memory_lifecycle_enabled"] is True
    assert manifest["document_parsing_enabled"] is True
    assert manifest["v39_tests_require_real_llm_api_network"] is False
    assert read_json(output / "token_budget_policy.json")["max_context_memory_items"] == 7
    assert (output / "v39_external_absorption_map.json").exists()


def test_run_config_rejects_destructive_cleanup(tmp_path):
    input_dir = tmp_path / "input"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("x", encoding="utf-8")
    config = tmp_path / "run.yaml"
    config.write_text(
        f"""
task: build
input: {input_dir.as_posix()}
output: {(tmp_path / "output").as_posix()}
workspace_storage:
  enabled: true
  destructive_cleanup: true
""",
        encoding="utf-8",
    )

    result = CliRunner().invoke(app, ["run", "--config", str(config)])

    assert result.exit_code != 0
    assert "workspace_storage.destructive_cleanup must remain false" in result.output


def test_default_build_does_not_emit_v39_reports(tmp_path):
    input_dir = tmp_path / "input"
    output = tmp_path / "output"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("No v3.9 opt in.", encoding="utf-8")

    result = CliRunner().invoke(app, ["build", "--input", str(input_dir), "--output", str(output)])

    assert result.exit_code == 0, result.output
    assert not (output / "v39_external_absorption_map.json").exists()
    assert "workspace_storage_enabled" not in read_json(output / "manifest.json")
