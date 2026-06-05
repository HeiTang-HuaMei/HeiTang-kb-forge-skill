from pathlib import Path

REQUIRED_COMPAT_FILES = [
    "openclaw_agent.yaml",
    "claude_code_instructions.md",
    "codex_instructions.md",
    "codex_task_plan.md",
    "mcp_resources.json",
    "mcp_tools_stub.json",
    "mcp_manifest.json",
    "generic_agent_profile.yaml",
]


def check_agent_compat(compat_dir: Path) -> dict:
    missing = [name for name in REQUIRED_COMPAT_FILES if not (compat_dir / name).exists()]
    return {"status": "passed" if not missing else "failed", "missing_files": missing, "required_files": REQUIRED_COMPAT_FILES}
