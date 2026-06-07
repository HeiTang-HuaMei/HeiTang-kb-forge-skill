import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app


DOCUMENT_FILES = {
    "generated.md",
    "generated.docx",
    "generated.pdf",
    "generated.pptx",
    "generated_file_report.json",
    "generated_file_report.md",
    "document_generation_trace.json",
    "document_quality_report.json",
    "export_validation_report.json",
    "export_validation_report.md",
}


def test_default_build_does_not_emit_document_generation_outputs(tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("Default build stays unchanged.", encoding="utf-8")

    result = CliRunner().invoke(app, ["build", "--input", str(input_dir), "--output", str(output_dir)])

    assert result.exit_code == 0, result.output
    assert not any((output_dir / name).exists() for name in DOCUMENT_FILES)
    manifest = _json(output_dir / "manifest.json")
    assert "document_generation_enabled" not in manifest


def test_run_config_document_generation_writes_requested_formats(tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    config_path = tmp_path / "run.yaml"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("Reviewed document generation evidence for config.", encoding="utf-8")
    config_path.write_text(
        f"""
task: build
input: {input_dir.as_posix()}
output: {output_dir.as_posix()}
parser_backend:
  use_for_build: true
  default: builtin
  allow_untrusted: true
document_generation:
  enabled: true
  formats:
    - md
    - docx
    - pdf
    - pptx
  template: default_report
  grounding_policy: creative_grounded
""",
        encoding="utf-8",
    )

    result = CliRunner().invoke(app, ["run", "--config", str(config_path)])

    assert result.exit_code == 0, result.output
    assert all((output_dir / name).exists() for name in DOCUMENT_FILES)
    manifest = _json(output_dir / "manifest.json")
    assert manifest["document_generation_enabled"] is True
    assert set(manifest["document_generation_formats"]) == {"md", "docx", "pdf", "pptx"}
    assert manifest["document_generation_status"] == "pass"


def _json(path):
    return json.loads(path.read_text(encoding="utf-8"))
