import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_store_export_index_writes_standard_store_outputs(tmp_path):
    input_dir = tmp_path / "input"
    package = tmp_path / "package"
    db_path = tmp_path / "kb_forge_workspace.db"
    export_output = tmp_path / "store_export"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("Store export index fixture.", encoding="utf-8")
    runner = CliRunner()
    assert runner.invoke(app, ["build", "--input", str(input_dir), "--output", str(package)]).exit_code == 0
    assert runner.invoke(app, ["store", "import-package", "--db", str(db_path), "--package", str(package)]).exit_code == 0

    result = runner.invoke(app, ["store", "export-index", "--db", str(db_path), "--output", str(export_output)])

    assert result.exit_code == 0, result.output
    for name in [
        "store_manifest.json",
        "store_package_index.jsonl",
        "store_source_index.jsonl",
        "store_chunk_index.jsonl",
        "store_status_report.md",
    ]:
        assert (export_output / name).exists()
    manifest = json.loads((export_output / "store_manifest.json").read_text(encoding="utf-8"))
    assert manifest["package_count"] == 1
