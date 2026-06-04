import sqlite3

from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_store_sync_workspace_imports_nested_packages(tmp_path):
    workspace = tmp_path / "workspace"
    input_one = tmp_path / "input_one"
    input_two = tmp_path / "input_two"
    package_one = workspace / "package_one"
    package_two = workspace / "package_two"
    db_path = tmp_path / "kb_forge_workspace.db"
    input_one.mkdir()
    input_two.mkdir()
    (input_one / "one.md").write_text("Store workspace one.", encoding="utf-8")
    (input_two / "two.md").write_text("Store workspace two.", encoding="utf-8")
    runner = CliRunner()
    assert runner.invoke(app, ["build", "--input", str(input_one), "--output", str(package_one)]).exit_code == 0
    assert runner.invoke(app, ["build", "--input", str(input_two), "--output", str(package_two)]).exit_code == 0

    result = runner.invoke(app, ["store", "sync-workspace", "--db", str(db_path), "--workspace", str(workspace)])

    assert result.exit_code == 0, result.output
    with sqlite3.connect(db_path) as connection:
        package_count = connection.execute("SELECT COUNT(*) FROM packages").fetchone()[0]
    assert package_count == 2
