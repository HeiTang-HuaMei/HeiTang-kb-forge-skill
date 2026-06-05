import json

from heitang_kb_forge.agent_compat import export_agent_compat


def test_agent_compat_exports_mcp_stubs(tmp_path):
    export_agent_compat(tmp_path, "Demo Agent")

    manifest = json.loads((tmp_path / "compat" / "mcp_manifest.json").read_text(encoding="utf-8"))
    assert manifest["server"] == "not_started"

