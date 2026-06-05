from heitang_kb_forge.agent_compat import export_agent_compat


def test_agent_compat_exports_openclaw_stub(tmp_path):
    export_agent_compat(tmp_path, "Demo Agent")

    assert (tmp_path / "compat" / "openclaw_agent.yaml").exists()
    assert "local_stub" in (tmp_path / "compat" / "openclaw_agent.yaml").read_text(encoding="utf-8")

