from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def test_agent_integration_docs_cover_required_targets_and_boundaries():
    text = (ROOT / "docs" / "AGENT_INTEGRATION.md").read_text(encoding="utf-8")

    assert "OpenClaw" in text
    assert "Claude Code" in text
    assert "Codex" in text
    assert "Generic Agent" in text
    assert "SKILL.md" in text
    assert "skill.json" in text
    assert "mcp_server_config.yaml" in text
    assert "does not require network access by default" in text
