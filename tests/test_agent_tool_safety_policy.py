from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_agent_tool_safety_policy_documents_boundaries(tmp_path):
    output = tmp_path / "tool_exports"

    result = CliRunner().invoke(app, ["tools", "export", "--output", str(output)])

    assert result.exit_code == 0, result.output
    policy = (output / "tool_safety_policy.md").read_text(encoding="utf-8")
    assert "No external API calls" in policy
    assert "Desktop UI is not required" in policy
