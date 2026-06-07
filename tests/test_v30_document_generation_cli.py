import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_generate_format_commands_write_outputs_and_reports(tmp_path):
    package = _build_package(tmp_path)
    commands = [
        ("generate-md", "generated.md"),
        ("generate-docx", "generated.docx"),
        ("generate-pdf", "generated.pdf"),
        ("generate-pptx", "generated.pptx"),
    ]

    for command, file_name in commands:
        output = tmp_path / command
        result = CliRunner().invoke(
            app,
            [
                command,
                "--package",
                str(package),
                "--output",
                str(output),
                "--template",
                "default_report",
                "--grounding-policy",
                "strict_grounded",
            ],
        )

        assert result.exit_code == 0, result.output
        assert (output / file_name).exists()
        assert (output / "generated_file_report.json").exists()
        assert (output / "generated_file_report.md").exists()
        assert (output / "document_generation_trace.json").exists()
        assert (output / "document_quality_report.json").exists()
        assert (output / "export_validation_report.json").exists()
        assert (output / "export_validation_report.md").exists()


def test_generate_documents_wrapper_accepts_multiple_formats(tmp_path):
    package = _build_package(tmp_path)
    output = tmp_path / "documents"

    result = CliRunner().invoke(
        app,
        [
            "generate-documents",
            "--package",
            str(package),
            "--output",
            str(output),
            "--formats",
            "md,pdf",
        ],
    )

    assert result.exit_code == 0, result.output
    assert (output / "generated.md").exists()
    assert (output / "generated.pdf").exists()
    trace = _json(output / "document_generation_trace.json")
    assert set(trace["generated_files"]) == {"md", "pdf"}


def _build_package(tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "package"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("Reviewed document generation evidence for v3.0.", encoding="utf-8")
    result = CliRunner().invoke(
        app,
        [
            "build",
            "--input",
            str(input_dir),
            "--output",
            str(output_dir),
            "--parser-backend",
            "builtin",
            "--allow-untrusted",
        ],
    )
    assert result.exit_code == 0, result.output
    return output_dir


def _json(path):
    return json.loads(path.read_text(encoding="utf-8"))
