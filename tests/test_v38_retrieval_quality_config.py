from typer.testing import CliRunner

from heitang_kb_forge.cli import app
from heitang_kb_forge.config.loader import load_config
from tests.v38_helpers import read_json


def test_retrieval_quality_config_defaults(tmp_path):
    config = tmp_path / "run.yaml"
    input_dir = tmp_path / "input"
    input_dir.mkdir()
    config.write_text(
        f"""
task: build
input: {input_dir.as_posix()}
output: {(tmp_path / "out").as_posix()}
""",
        encoding="utf-8",
    )

    loaded = load_config(config)

    assert loaded.retrieval_quality.enabled is False
    assert loaded.retrieval_quality.top_k == 5
    assert loaded.retrieval_quality.allow_external_network is False
    assert loaded.retrieval_quality.allow_llm_judge is False


def test_run_config_retrieval_quality_writes_reports_and_manifest(tmp_path):
    input_dir = tmp_path / "input"
    output = tmp_path / "output"
    config = tmp_path / "run.yaml"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("Pricing is 20 dollars. Revenue is growing.", encoding="utf-8")
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
  top_k: 3
  max_candidates: 20
""",
        encoding="utf-8",
    )

    result = CliRunner().invoke(app, ["run", "--config", str(config)])

    assert result.exit_code == 0, result.output
    manifest = read_json(output / "manifest.json")
    report = read_json(output / "retrieval_quality_report.json")
    assert manifest["retrieval_quality_enabled"] is True
    assert manifest["retrieval_quality_no_network"] is True
    assert report["retrieval_purpose"] == "validation"
    assert (output / "v38_external_absorption_map.json").exists()


def test_default_build_does_not_emit_v38_reports(tmp_path):
    input_dir = tmp_path / "input"
    output = tmp_path / "output"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("Pricing is 20 dollars.", encoding="utf-8")

    result = CliRunner().invoke(app, ["build", "--input", str(input_dir), "--output", str(output)])

    assert result.exit_code == 0, result.output
    assert not (output / "v38_external_absorption_map.json").exists()
    assert "retrieval_quality_enabled" not in read_json(output / "manifest.json")
