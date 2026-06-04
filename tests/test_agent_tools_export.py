import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_agent_tools_export_writes_registry_manifest_schema_and_policy(tmp_path):
    output = tmp_path / "tool_exports"

    result = CliRunner().invoke(app, ["tools", "export", "--output", str(output)])

    assert result.exit_code == 0, result.output
    for name in ["tool_registry.yaml", "tool_manifest.json", "agent_tool_schema.json", "tool_safety_policy.md"]:
        assert (output / name).exists()
    manifest = json.loads((output / "tool_manifest.json").read_text(encoding="utf-8"))
    assert any(tool["name"] == "retrieve_knowledge" for tool in manifest["tools"])
