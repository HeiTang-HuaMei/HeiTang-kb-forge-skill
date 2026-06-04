from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_store_init_creates_sqlite_db(tmp_path):
    db_path = tmp_path / "kb_forge_workspace.db"

    result = CliRunner().invoke(app, ["store", "init", "--db", str(db_path)])

    assert result.exit_code == 0, result.output
    assert db_path.exists()
