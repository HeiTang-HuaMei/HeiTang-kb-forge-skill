import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_build_validate_package_writes_readiness_reports(tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("# Validation Fixture\n\nGrounded content for validation.", encoding="utf-8")

    result = CliRunner().invoke(
        app,
        ["build", "--input", str(input_dir), "--output", str(output_dir), "--validate-package"],
    )

    assert result.exit_code == 0, result.output
    report = json.loads((output_dir / "package_validation_report.json").read_text(encoding="utf-8"))
    readiness = (output_dir / "package_readiness_report.md").read_text(encoding="utf-8")
    manifest = json.loads((output_dir / "manifest.json").read_text(encoding="utf-8"))
    assert report["standard_files_present"] is True
    assert "hallucination_risk_level" in report
    assert "Readiness level" in readiness
    assert "package_validation_report.json" in manifest["files"]


def test_run_config_supports_validation(tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    config_path = tmp_path / "config.yaml"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("Config validation fixture", encoding="utf-8")
    config_path.write_text(
        f"""
task: build
input: {input_dir.as_posix()}
output: {output_dir.as_posix()}
validation:
  enabled: true
""",
        encoding="utf-8",
    )

    result = CliRunner().invoke(app, ["run", "--config", str(config_path)])

    assert result.exit_code == 0, result.output
    assert (output_dir / "package_validation_report.json").exists()
