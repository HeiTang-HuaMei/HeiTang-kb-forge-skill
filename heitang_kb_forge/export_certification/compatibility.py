from pathlib import Path

from heitang_kb_forge.exporters.jsonl_exporter import write_json
from heitang_kb_forge.platform_distribution.platforms import SUPPORTED_PLATFORMS

OBJECTS = ["knowledge_package", "skill_package", "derived_skill_package", "agent_package", "workspace", "platform_exports"]


def make_compatibility_matrix(workspace: Path, output: Path) -> dict:
    output.mkdir(parents=True, exist_ok=True)
    rows = []
    for name in OBJECTS:
        rows.append(_row(name, generated=(workspace / _path_for(name)).exists()))
    for platform in SUPPORTED_PLATFORMS:
        rows.append(_platform_row(platform, generated=(workspace / "platform_distribution").exists()))
    matrix = {"status": "pass", "objects": rows}
    write_json(output / "compatibility_matrix.json", matrix)
    (output / "compatibility_matrix.md").write_text(_render_matrix(rows), encoding="utf-8")
    return matrix


def _row(name: str, generated: bool) -> dict:
    return {
        "object": name,
        "generated": generated,
        "validated": generated,
        "exportable": generated,
        "certified": False,
        "offline_safe": True,
        "mock_only": False,
        "requires_real_api": False,
        "official_api": False,
        "stub_only": False,
        "runtime_not_executed": True,
        "release_ready": False,
        "known_limits": ["v2.5 release gate only"],
        "next_real_validation_version": "v2.6" if name == "provider_registry" else "v2.7",
    }


def _platform_row(platform: str, generated: bool) -> dict:
    return {
        "object": platform,
        "generated": generated,
        "validated": generated,
        "exportable": True,
        "certified": False,
        "offline_safe": True,
        "mock_only": True,
        "requires_real_api": False,
        "official_api": False,
        "stub_only": platform in {"openclaw", "codex", "claude_code", "mcp"},
        "runtime_not_executed": platform in {"openclaw", "codex", "claude_code", "mcp"},
        "release_ready": False,
        "known_limits": ["local export only"],
        "next_real_validation_version": "v2.9" if platform == "xhs" else "v2.7",
    }


def _path_for(name: str) -> str:
    return {
        "knowledge_package": "manifest.json",
        "skill_package": "skill_package",
        "derived_skill_package": "derived_skill_package",
        "agent_package": "agent_package",
        "workspace": "workspace",
        "platform_exports": "platform_distribution",
    }[name]


def _render_matrix(rows: list[dict]) -> str:
    body = "\n".join(
        f"| {row['object']} | {row['generated']} | {row['mock_only']} | {row['stub_only']} | {row['next_real_validation_version']} |"
        for row in rows
    )
    return f"""# Compatibility Matrix

| Object | Generated | Mock Only | Stub Only | Next Real Validation |
| --- | --- | --- | --- | --- |
{body}
"""

