import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_mcp_export_config_writes_server_and_tools_manifest(tmp_path):
    output = tmp_path / "mcp_config"

    result = CliRunner().invoke(app, ["mcp", "export-config", "--output", str(output)])

    assert result.exit_code == 0, result.output
    assert (output / "mcp_server_config.yaml").exists()
    manifest = json.loads((output / "mcp_tools_manifest.json").read_text(encoding="utf-8"))
    assert manifest["tools"]
    assert any(tool["name"] == "build_knowledge_package" for tool in manifest["tools"])
