from __future__ import annotations

from pathlib import Path

from heitang_kb_forge.exporters.jsonl_exporter import write_json
from heitang_kb_forge.workbench.full_action_matrix import (
    build_full_ready_action_matrix,
    classify_ready_action,
    is_p1_v2_execution_target,
    ready_core_cli_actions,
)
from heitang_kb_forge.workbench.golden_workflows import _write_demo_assets


DEMO_QUERY = "What local evidence is available in the deterministic P1 demo package?"
DEMO_TASK = "Summarize the deterministic P1 demo package and cite local evidence."


def ensure_v2_demo_workspace(workspace: Path) -> dict:
    workspace.mkdir(parents=True, exist_ok=True)
    _write_demo_assets(workspace)
    for dirname in ["command_outputs", "config"]:
        (workspace / dirname).mkdir(parents=True, exist_ok=True)
    numbered_source = workspace / "data" / "001_demo_source.md"
    numbered_source.write_text(
        "# Demo Source 001\n\nLocal deterministic P1-RWF-V2 action execution input.\n",
        encoding="utf-8",
    )
    corrected_text = workspace / "data" / "corrected_text.md"
    corrected_text.write_text(
        "# Corrected Parser Output\n\nReviewed local text used for deterministic parse repair.\n",
        encoding="utf-8",
    )
    verification_source = workspace / "data" / "verification_source.md"
    verification_source.write_text(
        "# Verification Source\n\nLocal deterministic evidence confirms P1-RWF-V2 uses no network calls.\n",
        encoding="utf-8",
    )
    package = workspace / "artifacts" / "demo_kb_package"
    write_json(
        workspace / "package_registry.json",
        {
            "packages": [
                {
                    "package_path": _path(package),
                    "source_file_hashes": {},
                    "registered_at": "2026-06-09T00:00:00+00:00",
                    "readiness_level": "ready",
                    "risk_level": "low",
                    "quality_score": 90,
                }
            ]
        },
    )
    pipeline_config = workspace / "config" / "pipeline.yaml"
    pipeline_output = workspace / "artifacts" / "pipeline_package"
    pipeline_config.write_text(
        "\n".join(
            [
                "task: build",
                f'input: "{(workspace / "data").as_posix()}"',
                f'output: "{pipeline_output.as_posix()}"',
                "domain: demo",
                "mode: reference",
                "contract:",
                "  version: v2",
                "  check: true",
                "parser_backend:",
                "  use_for_build: true",
                "  default: builtin",
                "  allow_untrusted: false",
                "  trust_policy:",
                "    default_status: reviewed_knowledge_base",
                "",
            ]
        ),
        encoding="utf-8",
    )
    return {
        "workspace": workspace,
        "source": workspace / "data" / "demo_source.md",
        "numbered_source": numbered_source,
        "input": workspace / "data",
        "package": package,
        "skill": workspace / "artifacts" / "demo_skill",
        "agent": workspace / "artifacts" / "demo_agent",
        "file": corrected_text,
        "verification_source": verification_source,
        "config": pipeline_config,
        "repo": Path.cwd(),
        "name": "Demo Knowledge Skill",
        "query": DEMO_QUERY,
        "task": DEMO_TASK,
    }


def build_action_execution_plan(workspace: Path | None = None, output: Path | None = None) -> dict:
    matrix = build_full_ready_action_matrix()
    contexts = None
    if workspace is not None:
        contexts = ensure_v2_demo_workspace(workspace)
    actions = [
        _plan_item(action, contexts, output)
        for action in ready_core_cli_actions()
    ]
    return {
        "report_id": "p1_rwf_v2_action_input_plan",
        "status": "pass" if matrix["status"] == "pass" and all(item["classification"] for item in actions) else "fail",
        "execution_target_count": matrix["execution_target_count"],
        "ready_core_cli_action_count": matrix["ready_core_cli_action_count"],
        "actions": actions,
        "tests_require_real_llm_api_network": False,
        "network_required": False,
    }


def write_action_execution_plan(output: Path, workspace: Path | None = None) -> dict:
    output.mkdir(parents=True, exist_ok=True)
    plan = build_action_execution_plan(workspace, output)
    write_json(output / "action_input_plan.json", plan)
    return plan


def build_action_run_plan(action_id: str, workspace: Path, action_run_dir: Path) -> dict:
    contexts = ensure_v2_demo_workspace(workspace)
    action = next(action for action in ready_core_cli_actions() if action.action_id == action_id)
    return _plan_item(action, contexts, action_run_dir)


def command_args_for_action(action, contexts: dict, command_output: Path) -> list[str]:
    if not action.command:
        return []
    parts = action.command.split()
    values = _placeholder_values(contexts, command_output)
    return [str(values.get(part, part)) for part in parts]


def redact_command_args(args: list[str], workspace: Path, command_output: Path) -> list[str]:
    return [_redact_value(arg, workspace, command_output) for arg in args]


def _plan_item(action, contexts: dict | None, output: Path | None) -> dict:
    classification = classify_ready_action(action)
    execution_target = is_p1_v2_execution_target(action)
    placeholders = _placeholders(action.command or "")
    if contexts and output is not None:
        command_output = contexts["workspace"] / "command_outputs" / action.action_id
        args = command_args_for_action(action, contexts, command_output)
        resolved_command = redact_command_args(args, contexts["workspace"], command_output)
        input_artifacts = _input_artifacts(placeholders, contexts, contexts["workspace"], command_output)
    else:
        resolved_command = _placeholder_command(action.command)
        input_artifacts = [{"placeholder": item, "path": item} for item in placeholders]
    return {
        "action_id": action.action_id,
        "command": action.command,
        "resolved_command": resolved_command,
        "classification": classification,
        "execution_target": execution_target,
        "input_source": _input_source(classification),
        "input_artifacts": input_artifacts,
        "dependencies": _dependencies(placeholders),
        "expected_reports": action.report_ids,
        "expected_artifacts": action.artifact_ids,
        "blocked_reason": None if execution_target else _blocked_reason(classification),
    }


def _placeholder_values(contexts: dict, command_output: Path) -> dict[str, object]:
    return {
        "<workspace>": contexts["workspace"],
        "<source>": contexts["source"],
        "<output>": command_output,
        "<package>": contexts["package"],
        "<packages>": contexts["package"],
        "<input>": contexts["input"],
        "<query>": contexts["query"],
        "<task>": contexts["task"],
        "<agent>": contexts["agent"],
        "<skill>": contexts["skill"],
        "<old>": contexts["skill"],
        "<new>": contexts["skill"],
        "<file>": contexts["file"],
        "<config>": contexts["config"],
        "<repo>": contexts["repo"],
        "<name>": contexts["name"],
    }


def _placeholders(command: str) -> list[str]:
    return sorted({part for part in command.split() if part.startswith("<") and part.endswith(">")})


def _placeholder_command(command: str | None) -> list[str]:
    return command.split() if command else []


def _input_source(classification: str) -> str:
    return {
        "executable_with_demo_input": "demo_input",
        "executable_with_generated_workspace": "generated_workspace",
        "executable_with_previous_artifact": "previous_artifact",
        "deterministic_smoke_only": "deterministic_smoke_fixture",
    }.get(classification, "blocked")


def _input_artifacts(placeholders: list[str], contexts: dict, workspace: Path, command_output: Path) -> list[dict]:
    values = _placeholder_values(contexts, command_output)
    return [
        {"placeholder": placeholder, "path": _redact_value(str(values[placeholder]), workspace, command_output)}
        for placeholder in placeholders
        if placeholder in values
    ]


def _dependencies(placeholders: list[str]) -> list[str]:
    dependency_map = {
        "<workspace>": "demo_workspace",
        "<source>": "demo_source",
        "<input>": "demo_source_folder",
        "<file>": "corrected_text_fixture",
        "<config>": "pipeline_config",
        "<package>": "demo_kb_package",
        "<packages>": "demo_kb_package",
        "<skill>": "demo_skill_package",
        "<old>": "demo_skill_package",
        "<new>": "demo_skill_package",
        "<agent>": "demo_agent_package",
        "<repo>": "core_repo_checkout",
    }
    return [dependency_map[item] for item in placeholders if item in dependency_map]


def _blocked_reason(classification: str) -> str:
    return {
        "blocked_provider_required": "Provider, network, or explicit user configuration is required; not executed as a local P1-RWF-V2 target.",
        "blocked_secret_required": "Secret-risk handling remains blocked and is not executed with synthetic secrets.",
        "blocked_planned_adapter": "Planned adapter is not ready in the P1 Core contract.",
        "blocked_missing_safe_input": "No safe deterministic input is available.",
        "blocked_unsafe_to_execute": "The action is unsafe to execute in deterministic offline acceptance.",
    }.get(classification, "")


def _redact_value(value: str, workspace: Path, command_output: Path) -> str:
    redacted = value.replace("\\", "/")
    replacements = {
        workspace.as_posix(): "<workspace>",
        str(workspace).replace("\\", "/"): "<workspace>",
        command_output.as_posix(): "<command_output>",
        str(command_output).replace("\\", "/"): "<command_output>",
        Path.cwd().as_posix(): "<core_repo>",
        str(Path.cwd()).replace("\\", "/"): "<core_repo>",
    }
    for old, new in sorted(replacements.items(), key=lambda item: len(item[0]), reverse=True):
        redacted = redacted.replace(old, new)
    return redacted


def _path(path: Path) -> str:
    return str(path).replace("\\", "/")
