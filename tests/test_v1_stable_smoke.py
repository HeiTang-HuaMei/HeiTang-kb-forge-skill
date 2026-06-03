import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app
from heitang_kb_forge.parsers.ocr_table import extract_image_table_text
from heitang_kb_forge.parsers.pdf_table_parser import extract_pdf_tables


def test_v1_build_smoke_with_runtime_exports(tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("# V1 Smoke\n\nThis fixture validates the v1 stable pipeline.", encoding="utf-8")

    result = CliRunner().invoke(
        app,
        [
            "build",
            "--input",
            str(input_dir),
            "--output",
            str(output_dir),
            "--llm",
            "--llm-provider",
            "fake",
            "--llm-quality-report",
            "--rag-export",
            "--embedding",
            "--vector-export",
            "--agent-template",
            "--agent-type",
            "book_marketing_agent",
            "--demo-report",
            "--validate-package",
            "--downstream-export",
        ],
    )

    assert result.exit_code == 0, result.output
    for name in [
        "llm_quality_report.json",
        "rag_manifest.json",
        "embeddings.jsonl",
        "vector_store_manifest.json",
        "agent_profile.yaml",
        "demo_report.md",
        "package_validation_report.json",
        "generic_rag_package.json",
    ]:
        assert (output_dir / name).exists()


def test_v1_run_and_pipeline_config_smoke(tmp_path):
    input_dir = tmp_path / "input"
    run_output = tmp_path / "run_output"
    pipeline_output = tmp_path / "pipeline_output"
    run_config = tmp_path / "run.yaml"
    pipeline_config = tmp_path / "pipeline.yaml"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("Config smoke fixture", encoding="utf-8")
    config_template = """
task: build
input: {input}
output: {output}
rag:
  enabled: true
embedding:
  enabled: true
vector:
  enabled: true
validation:
  enabled: true
downstream:
  enabled: true
"""
    run_config.write_text(config_template.format(input=input_dir.as_posix(), output=run_output.as_posix()), encoding="utf-8")
    pipeline_config.write_text(
        config_template.format(input=input_dir.as_posix(), output=pipeline_output.as_posix()),
        encoding="utf-8",
    )

    run_result = CliRunner().invoke(app, ["run", "--config", str(run_config)])
    pipeline_result = CliRunner().invoke(app, ["pipeline", "--config", str(pipeline_config)])

    assert run_result.exit_code == 0, run_result.output
    assert pipeline_result.exit_code == 0, pipeline_result.output
    pipeline_manifest = json.loads((pipeline_output / "pipeline_manifest.json").read_text(encoding="utf-8"))
    stages = {stage["name"]: stage for stage in pipeline_manifest["stages"]}
    assert stages["package_validation"]["status"] == "success"
    assert stages["downstream_export"]["status"] == "success"


def test_v1_table_parser_smoke(monkeypatch, tmp_path):
    import sys
    import types

    pdf_path = tmp_path / "table.pdf"
    pdf_path.write_bytes(b"%PDF-1.4\n")

    class FakePage:
        def extract_tables(self):
            return [[["Column A"], ["Value"]]]

    class FakePDF:
        pages = [FakePage()]

        def __enter__(self):
            return self

        def __exit__(self, exc_type, exc, tb):
            return False

    monkeypatch.setitem(sys.modules, "pdfplumber", types.SimpleNamespace(open=lambda path: FakePDF()))
    table_text, _ = extract_pdf_tables(pdf_path)
    assert "Page 1. Table 1." in table_text


def test_v1_ocr_table_smoke(monkeypatch):
    import sys
    import types

    fake_pytesseract = types.SimpleNamespace(
        Output=types.SimpleNamespace(DICT="dict"),
        image_to_data=lambda image, output_type=None: {
            "text": ["A", "B"],
            "conf": ["90", "90"],
            "left": [10, 80],
            "top": [10, 10],
            "width": [10, 10],
        },
    )
    monkeypatch.setitem(sys.modules, "pytesseract", fake_pytesseract)

    text, warnings = extract_image_table_text(object())

    assert warnings == []
    assert "Image Table 1." in text
