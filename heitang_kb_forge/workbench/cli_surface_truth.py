from __future__ import annotations

from pathlib import Path

from typer.main import get_command
from typer.testing import CliRunner

from heitang_kb_forge.exporters.jsonl_exporter import write_json
from heitang_kb_forge.workbench.productization import make_p1_workbench_bundle


COMMAND_SURFACE_REPORT_FILES = [
    "command_surface_truth_report.json",
    "command_surface_truth_report.md",
]


def audit_p1_ready_core_cli_surface() -> dict:
    from heitang_kb_forge.cli import app

    cli = get_command(app)
    runner = CliRunner()
    commands = cli.commands
    bundle = make_p1_workbench_bundle()
    ready_actions = [
        action
        for action in bundle.action_contracts
        if action.status == "ready" and action.command_kind == "core_cli"
    ]
    unique_commands = sorted({action.command.split()[0] for action in ready_actions if action.command})
    action_results = []
    drifts = []

    for action in ready_actions:
        parts = action.command.split()
        command_name = parts[0]
        contract_flags = sorted({part for part in parts[1:] if part.startswith("--")})
        result = {
            "action_id": action.action_id,
            "command": command_name,
            "contract_command": action.command,
            "contract_flags": contract_flags,
            "requires_explicit_user_config": action.requires_explicit_user_config,
            "error_codes": action.error_codes,
            "status": "pass",
            "drifts": [],
        }
        if command_name not in commands:
            drift = {"type": "missing_command", "command": command_name}
            result["status"] = "fail"
            result["drifts"].append(drift)
            drifts.append({"action_id": action.action_id, **drift})
            action_results.append(result)
            continue

        help_result = runner.invoke(app, [command_name, "--help"])
        if help_result.exit_code != 0:
            drift = {"type": "help_failed", "command": command_name, "exit_code": help_result.exit_code}
            result["status"] = "fail"
            result["drifts"].append(drift)
            drifts.append({"action_id": action.action_id, **drift})
            action_results.append(result)
            continue

        cli_flags = sorted(
            {
                option
                for parameter in commands[command_name].params
                for option in getattr(parameter, "opts", [])
            }
        )
        missing_flags = sorted(set(contract_flags) - set(cli_flags))
        result["cli_flags"] = cli_flags
        if missing_flags:
            drift = {"type": "missing_flags", "command": command_name, "missing_flags": missing_flags}
            result["status"] = "fail"
            result["drifts"].append(drift)
            drifts.append({"action_id": action.action_id, **drift})
        action_results.append(result)

    explicit_config_ready = [
        action.action_id
        for action in ready_actions
        if action.requires_explicit_user_config
        or set(action.error_codes) & {"provider_auth_failed", "secret_risk", "network_unavailable"}
    ]
    planned_ready = [
        action.action_id
        for action in bundle.action_contracts
        if action.status == "ready" and action.command_kind == "planned_adapter"
    ]
    report = {
        "report_id": "p1_command_surface_truth",
        "status": "pass" if not drifts and not planned_ready else "fail",
        "ready_core_cli_action_count": len(ready_actions),
        "unique_command_count": len(unique_commands),
        "unique_commands": unique_commands,
        "drift_count": len(drifts),
        "drifts": drifts,
        "actions": action_results,
        "planned_adapter_ready_violations": planned_ready,
        "provider_secret_network_ready_actions_require_explicit_config": explicit_config_ready,
        "tests_require_real_llm_api_network": False,
        "network_required": False,
    }
    return report


def write_command_surface_truth_report(output: Path) -> dict:
    output.mkdir(parents=True, exist_ok=True)
    report = audit_p1_ready_core_cli_surface()
    write_json(output / "command_surface_truth_report.json", report)
    (output / "command_surface_truth_report.md").write_text(render_command_surface_truth_report(report), encoding="utf-8")
    return report


def render_command_surface_truth_report(report: dict) -> str:
    drift_lines = ["- None."] if not report["drifts"] else [
        f"- {item['action_id']}: {item['type']} ({item['command']})" for item in report["drifts"]
    ]
    explicit_lines = [
        f"- {action_id}" for action_id in report["provider_secret_network_ready_actions_require_explicit_config"]
    ] or ["- None."]
    return "\n".join(
        [
            "# P1 Command Surface Truth Report",
            "",
            f"Status: {report['status']}",
            f"Ready/core_cli actions: {report['ready_core_cli_action_count']}",
            f"Unique CLI commands: {report['unique_command_count']}",
            f"Drift count: {report['drift_count']}",
            "",
            "## Drifts",
            "",
            *drift_lines,
            "",
            "## Explicit Config Ready Actions",
            "",
            "These ready actions remain excluded from Golden Local Workflow V1 real-local completion unless user config is supplied.",
            "",
            *explicit_lines,
            "",
            "Tests require real LLM/API/network: false.",
            "",
        ]
    )
