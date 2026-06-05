from heitang_kb_forge.agent_compat import export_agent_compat


def test_agent_compat_exports_codex_files(tmp_path):
    export_agent_compat(tmp_path, "Demo Agent")

    assert (tmp_path / "compat" / "codex_instructions.md").exists()
    assert (tmp_path / "compat" / "codex_task_plan.md").exists()

