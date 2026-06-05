from pathlib import Path

from heitang_kb_forge.agent_compat.checker import check_agent_compat
from heitang_kb_forge.agent_compat.claude_code import render_claude_code
from heitang_kb_forge.agent_compat.codex import render_codex_instructions
from heitang_kb_forge.agent_compat.generic import render_generic
from heitang_kb_forge.agent_compat.mcp import render_mcp
from heitang_kb_forge.agent_compat.openclaw import render_openclaw
from heitang_kb_forge.agent_compat.report import render_agent_compat_report
from heitang_kb_forge.exporters.jsonl_exporter import write_json


def export_agent_compat(agent_package: Path, agent_name: str) -> dict:
    compat = agent_package / "compat"
    compat.mkdir(parents=True, exist_ok=True)
    (compat / "openclaw_agent.yaml").write_text(render_openclaw(agent_name), encoding="utf-8")
    (compat / "claude_code_instructions.md").write_text(render_claude_code(agent_name), encoding="utf-8")
    codex_instructions, codex_plan = render_codex_instructions(agent_name)
    (compat / "codex_instructions.md").write_text(codex_instructions, encoding="utf-8")
    (compat / "codex_task_plan.md").write_text(codex_plan, encoding="utf-8")
    resources, tools, manifest = render_mcp()
    write_json(compat / "mcp_resources.json", resources)
    write_json(compat / "mcp_tools_stub.json", tools)
    write_json(compat / "mcp_manifest.json", manifest)
    (compat / "generic_agent_profile.yaml").write_text(render_generic(agent_name), encoding="utf-8")
    result = check_agent_compat(compat)
    write_json(agent_package / "agent_compat_check_result.json", result)
    (agent_package / "agent_compat_check_report.md").write_text(render_agent_compat_report(result), encoding="utf-8")
    return result
