from pathlib import Path

from heitang_kb_forge.agent_compat.codex import check_codex_harness

REQUIRED_COMPAT_FILES = [
    "openclaw_agent.yaml",
    "claude_code_instructions.md",
    "codex_instructions.md",
    "codex_task_plan.md",
    "codex_harness_contract.json",
    "codex_harness_check_result.json",
    "mcp_resources.json",
    "mcp_tools_stub.json",
    "mcp_manifest.json",
    "generic_agent_profile.yaml",
]


def check_agent_compat(compat_dir: Path) -> dict:
    missing = [name for name in REQUIRED_COMPAT_FILES if not (compat_dir / name).exists()]
    codex_harness = check_codex_harness(compat_dir)
    failed_checks = []
    if missing:
        failed_checks.append("missing_required_files")
    if codex_harness["status"] != "passed":
        failed_checks.append("codex_harness_failed")
    return {
        "status": "passed" if not failed_checks else "failed",
        "missing_files": missing,
        "required_files": REQUIRED_COMPAT_FILES,
        "failed_checks": failed_checks,
        "codex_harness": codex_harness,
    }
