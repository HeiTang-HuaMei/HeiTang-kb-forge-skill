import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_store_query_packages_filters_by_domain(tmp_path):
    input_dir = tmp_path / "input"
    package = tmp_path / "package"
    db_path = tmp_path / "kb_forge_workspace.db"
    query_output = tmp_path / "query"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("Store query package fixture.", encoding="utf-8")
    runner = CliRunner()
    assert runner.invoke(app, ["build", "--input", str(input_dir), "--output", str(package), "--domain", "product"]).exit_code == 0
    assert runner.invoke(app, ["store", "import-package", "--db", str(db_path), "--package", str(package)]).exit_code == 0

    result = runner.invoke(
        app,
        ["store", "query-packages", "--db", str(db_path), "--domain", "product", "--output", str(query_output)],
    )

    assert result.exit_code == 0, result.output
    payload = json.loads((query_output / "store_query_result.json").read_text(encoding="utf-8"))
    assert payload["total"] == 1
    assert payload["packages"][0]["domain"] == "product"
