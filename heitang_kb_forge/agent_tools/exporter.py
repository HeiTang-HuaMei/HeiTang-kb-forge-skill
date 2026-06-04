from __future__ import annotations

from heitang_kb_forge.agent_tools.registry import list_agent_tools
from heitang_kb_forge.schemas.agent_tool_schema import ToolManifest


AGENT_TOOL_OUTPUT_FILES = [
    "tool_registry.yaml",
    "tool_manifest.json",
    "agent_tool_schema.json",
    "tool_safety_policy.md",
]


def make_tool_exports() -> tuple[str, dict, dict, str]:
    tools = list_agent_tools()
    manifest = ToolManifest(tools=tools)
    return _registry_yaml(tools), manifest.model_dump(mode="json"), _schema_payload(), _safety_policy(tools)


def _registry_yaml(tools) -> str:
    lines = ["tools:"]
    for tool in tools:
        lines.extend(
            [
                f"  - name: {tool.name}",
                f"    description: {tool.description}",
                "    runtime: local_cli",
            ]
        )
    return "\n".join(lines) + "\n"


def _schema_payload() -> dict:
    return {
        "schema_version": "1.6.0",
        "tool_count": len(list_agent_tools()),
        "tools": [tool.model_dump(mode="json") for tool in list_agent_tools()],
    }


def _safety_policy(tools) -> str:
    names = "\n".join(f"- {tool.name}" for tool in tools)
    return f"""# Agent Tool Safety Policy

## Scope

HeiTang KB Forge tools are local, file-based Skill entry points.

## Allowed Tools

{names}

## Safety Rules

- No external API calls are performed by tool export.
- Tools must preserve standard package output files.
- Tool invocation writes trace and result files.
- Desktop UI is not required for tool usage.
"""
