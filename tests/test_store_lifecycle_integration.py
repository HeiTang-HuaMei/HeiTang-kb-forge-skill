import sqlite3

from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_store_imports_lifecycle_source_registry(tmp_path):
    input_dir = tmp_path / "input"
    package = tmp_path / "package"
    db_path = tmp_path / "kb_forge_workspace.db"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("Store lifecycle source registry fixture.", encoding="utf-8")
    runner = CliRunner()
    assert runner.invoke(app, ["build", "--input", str(input_dir), "--output", str(package), "--lifecycle"]).exit_code == 0

    result = runner.invoke(app, ["store", "import-package", "--db", str(db_path), "--package", str(package)])

    assert result.exit_code == 0, result.output
    with sqlite3.connect(db_path) as connection:
        source_count = connection.execute("SELECT COUNT(*) FROM sources").fetchone()[0]
    assert source_count == 1
