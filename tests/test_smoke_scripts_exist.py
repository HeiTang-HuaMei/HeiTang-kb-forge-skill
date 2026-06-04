from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def test_smoke_scripts_exist_and_use_python_module_cli():
    quickstart = ROOT / "scripts" / "smoke_quickstart.ps1"
    agent_flow = ROOT / "scripts" / "smoke_agent_flow.ps1"

    assert quickstart.exists()
    assert agent_flow.exists()
    agent_script = agent_flow.read_text(encoding="utf-8")
    assert "python -m heitang_kb_forge.cli build" in agent_script
    assert "tools describe --name retrieve_knowledge" in agent_script
    assert "mcp export-config" in agent_script
