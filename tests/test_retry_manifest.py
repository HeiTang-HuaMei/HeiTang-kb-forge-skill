import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_lifecycle_writes_retry_manifest_and_report(tmp_path):
    input_dir = tmp_path / "input"
    output = tmp_path / "output"
    retry_source = tmp_path / "retry_source.json"
    input_dir.mkdir()
    retry_source.write_text('{"retry_items":[]}', encoding="utf-8")
    (input_dir / "lesson.md").write_text("Lifecycle retry fixture.", encoding="utf-8")

    result = CliRunner().invoke(
        app,
        [
            "build",
            "--input",
            str(input_dir),
            "--output",
            str(output),
            "--lifecycle",
            "--retry-manifest",
            str(retry_source),
        ],
    )

    assert result.exit_code == 0, result.output
    manifest = json.loads((output / "retry_manifest.json").read_text(encoding="utf-8"))
    assert manifest["failed_source_count"] == 0
    assert manifest["retry_source_manifest"].endswith("retry_source.json")
    assert (output / "retry_report.md").exists()
