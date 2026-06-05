import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_package_lineage_generates_version_graph(tmp_path):
    workspace = tmp_path / "workspace"
    package = workspace / "package_a"
    output = tmp_path / "lineage"
    package.mkdir(parents=True)
    (package / "manifest.json").write_text('{"package_id":"package_a","package_version":"1.0.0"}', encoding="utf-8")

    result = CliRunner().invoke(app, ["package-lineage", "--workspace", str(workspace), "--output", str(output)])

    assert result.exit_code == 0, result.output
    graph = json.loads((output / "package_version_graph.json").read_text(encoding="utf-8"))
    assert graph["nodes"][0]["package_id"] == "package_a"
    assert (output / "package_lineage_report.md").exists()
    assert (output / "package_dependency_report.md").exists()

