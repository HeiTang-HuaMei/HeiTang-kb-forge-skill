from pathlib import Path


CODEX_HARNESS_SCHEMA_VERSION = "codex_execution_harness.v1"
CODEX_HARNESS_REQUIRED_FILES = [
    "codex_instructions.md",
    "codex_task_plan.md",
    "codex_harness_contract.json",
]
CODEX_HARNESS_BOUNDARY = {
    "external_codex_process": "not_started",
    "network": "not_required",
    "secrets": "not_required",
    "redis_service_packaging": "forbidden",
    "vector_service_packaging": "forbidden",
}


def render_codex_instructions(agent_name: str) -> tuple[str, str]:
    return (
        f"# Codex Instructions\n\nCall local HeiTang KB Forge outputs for {agent_name}.\n",
        "# Codex Task Plan\n\n1. Inspect package.\n2. Retrieve evidence.\n3. Answer with citations.\n",
    )


def render_codex_harness_contract(agent_name: str) -> dict:
    return {
        "schema_version": CODEX_HARNESS_SCHEMA_VERSION,
        "agent_name": agent_name,
        "execution_mode": "local_codex_handoff_contract",
        "required_files": CODEX_HARNESS_REQUIRED_FILES,
        "input_contract": {
            "agent_name": "non_empty_string",
            "agent_package": "local_directory",
            "compat_dir": "local_directory/compat",
        },
        "output_contract": {
            "instructions": "compat/codex_instructions.md",
            "task_plan": "compat/codex_task_plan.md",
            "contract": "compat/codex_harness_contract.json",
            "check_result": "compat/codex_harness_check_result.json",
        },
        "allowed_operations": [
            "inspect_package",
            "retrieve_local_evidence",
            "answer_with_citations",
        ],
        "error_handling": {
            "missing_files": "failed_with_missing_files",
            "empty_files": "failed_with_empty_files",
        },
        "boundary": CODEX_HARNESS_BOUNDARY,
    }


def check_codex_harness(compat_dir: Path) -> dict:
    missing = [name for name in CODEX_HARNESS_REQUIRED_FILES if not (compat_dir / name).exists()]
    empty = [
        name
        for name in CODEX_HARNESS_REQUIRED_FILES
        if (compat_dir / name).exists() and not (compat_dir / name).read_text(encoding="utf-8").strip()
    ]
    failed_checks = []
    if missing:
        failed_checks.append("missing_required_files")
    if empty:
        failed_checks.append("empty_required_files")
    return {
        "schema_version": CODEX_HARNESS_SCHEMA_VERSION,
        "status": "passed" if not failed_checks else "failed",
        "execution_mode": "local_codex_handoff_contract",
        "required_files": CODEX_HARNESS_REQUIRED_FILES,
        "missing_files": missing,
        "empty_files": empty,
        "failed_checks": failed_checks,
        "boundary": CODEX_HARNESS_BOUNDARY,
    }
