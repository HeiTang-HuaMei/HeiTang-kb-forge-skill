from heitang_kb_forge.agent_compat import export_agent_compat


def test_agent_compat_exports_claude_code_instructions(tmp_path):
    export_agent_compat(tmp_path, "Demo Agent")

    assert (tmp_path / "compat" / "claude_code_instructions.md").exists()

