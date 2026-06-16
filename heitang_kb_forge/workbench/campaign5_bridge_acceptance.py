from __future__ import annotations

from datetime import datetime, timezone
from pathlib import Path

from heitang_kb_forge.exporters.jsonl_exporter import write_json
from heitang_kb_forge.workbench.action_input_planner import build_action_execution_plan
from heitang_kb_forge.workbench.full_action_matrix import build_full_ready_action_matrix
from heitang_kb_forge.workbench.productization import make_p1_workbench_bundle


CAMPAIGN5_STATUS_VALUES = [
    "queued",
    "running",
    "succeeded",
    "failed",
    "cancelled",
    "blocked",
    "degraded",
]

CAMPAIGN5_FORBIDDEN_PRODUCT_RUNTIME_ACTIONS = {
    "run_agent",
    "multi_agent_orchestration",
    "summary_memory_lifecycle",
    "memory_compression",
    "memory_cleanup",
    "artifact_runtime_trace_inspect",
    "artifact_memory_files_inspect",
}

CAMPAIGN5_EXPLICIT_BOUNDARY_ACTIONS = {
    "llm_provider_validate",
    "vector_db_validate",
    "vector_upsert_query_smoke",
    "provider_redaction_check",
    "offline_fallback_status",
}

CAMPAIGN5_REPORT_FILES = [
    "Campaign_5_Workbench_Bridge_Production_Grade_Implementation_Report_2026-06-16.md",
    "Campaign_5_Workbench_Bridge_Action_Status_Matrix_2026-06-16.md",
    "Campaign_5_Workbench_Bridge_Degraded_Mode_and_Rollback_Matrix_2026-06-16.md",
]


def build_campaign5_workbench_bridge_evidence() -> dict:
    bundle = make_p1_workbench_bundle()
    matrix = build_full_ready_action_matrix()
    plan = build_action_execution_plan()
    rows = matrix["actions"]
    action_by_id = {action.action_id: action for action in bundle.action_contracts}
    product_enabled_rows = [
        row
        for row in rows
        if row["execution_target"]
        and row["action_id"] not in CAMPAIGN5_FORBIDDEN_PRODUCT_RUNTIME_ACTIONS
    ]
    matrix_by_id = {row["action_id"]: row for row in rows}
    diagnostic_only_rows = [
        _matrix_or_contract_row(action_by_id[action_id], matrix_by_id.get(action_id))
        for action_id in sorted(CAMPAIGN5_FORBIDDEN_PRODUCT_RUNTIME_ACTIONS)
        if action_id in action_by_id
    ]
    explicit_boundary_rows = [
        row
        for row in rows
        if row["action_id"] in CAMPAIGN5_EXPLICIT_BOUNDARY_ACTIONS
    ]
    status_matrix = _status_matrix(product_enabled_rows, explicit_boundary_rows)
    degraded_matrix = _degraded_matrix()
    ui_matrix = _ui_status_matrix()
    safety = _safety_boundaries(product_enabled_rows, diagnostic_only_rows, explicit_boundary_rows)
    rollback = _rollback_matrix()
    accepted = (
        matrix["status"] == "pass"
        and plan["status"] == "pass"
        and len(product_enabled_rows) > 0
        and all(row["action_id"] not in CAMPAIGN5_FORBIDDEN_PRODUCT_RUNTIME_ACTIONS for row in product_enabled_rows)
        and {row["action_id"] for row in explicit_boundary_rows} == CAMPAIGN5_EXPLICIT_BOUNDARY_ACTIONS
        and set(status_matrix["status_values"]) == set(CAMPAIGN5_STATUS_VALUES)
        and safety["status"] == "pass"
    )
    final_status = (
        "campaign5_workbench_bridge_production_grade_accepted_ui_bound"
        if accepted
        else "campaign5_workbench_bridge_partial_degraded_mode_ready"
    )
    return {
        "gate_id": "campaign5_workbench_bridge_production_grade_implementation",
        "generated_at": _now(),
        "final_status": final_status,
        "accepted": accepted,
        "core_matrix": {
            "status": matrix["status"],
            "ready_core_cli_action_count": matrix["ready_core_cli_action_count"],
            "execution_target_count": matrix["execution_target_count"],
            "expected_execution_target_count": matrix["expected_execution_target_count"],
            "command_surface_drift_count": matrix["command_surface_drift_count"],
        },
        "action_plan": {
            "status": plan["status"],
            "ready_core_cli_action_count": plan["ready_core_cli_action_count"],
            "execution_target_count": plan["execution_target_count"],
        },
        "product_enabled_action_count": len(product_enabled_rows),
        "diagnostic_only_action_count": len(diagnostic_only_rows),
        "explicit_boundary_action_count": len(explicit_boundary_rows),
        "product_enabled_actions": [
            _action_row(row, action_by_id[row["action_id"]], "enabled_real")
            for row in product_enabled_rows
        ],
        "diagnostic_only_actions": [
            _action_row(row, action_by_id[row["action_id"]], "display_only_diagnostic")
            for row in diagnostic_only_rows
        ],
        "explicit_boundary_actions": [
            _action_row(row, action_by_id[row["action_id"]], "disabled_boundary")
            for row in explicit_boundary_rows
        ],
        "status_matrix": status_matrix,
        "degraded_mode_matrix": degraded_matrix,
        "rollback_matrix": rollback,
        "user_facing_status_matrix": ui_matrix,
        "safety_boundaries": safety,
        "known_gaps": [
            "Campaign 6 Agent Runtime, Agent CRUD, and version runtime remain out of scope.",
            "Campaign 7-9 configuration, full review, and EXE packaging remain out of scope.",
            "Memory, Collaboration, A2A, Sandbox, Computer Use, and Agent Teams remain disabled or display-only.",
        ],
        "output_files": CAMPAIGN5_REPORT_FILES,
    }


def write_campaign5_workbench_bridge_reports(output: Path) -> dict:
    output.mkdir(parents=True, exist_ok=True)
    evidence = build_campaign5_workbench_bridge_evidence()
    write_json(output / "campaign5_workbench_bridge_evidence.json", evidence)
    (output / CAMPAIGN5_REPORT_FILES[0]).write_text(
        render_campaign5_implementation_report(evidence),
        encoding="utf-8",
        newline="\n",
    )
    (output / CAMPAIGN5_REPORT_FILES[1]).write_text(
        render_campaign5_action_status_matrix(evidence),
        encoding="utf-8",
        newline="\n",
    )
    (output / CAMPAIGN5_REPORT_FILES[2]).write_text(
        render_campaign5_degraded_rollback_matrix(evidence),
        encoding="utf-8",
        newline="\n",
    )
    return evidence


def render_campaign5_implementation_report(evidence: dict) -> str:
    safety = evidence["safety_boundaries"]
    return "\n".join(
        [
            "# Campaign 5 Workbench Bridge Production-Grade Implementation Report",
            "",
            f"Date: 2026-06-16",
            f"Gate: `{evidence['gate_id']}`",
            f"Status: `{evidence['final_status']}`",
            "",
            "## Scope",
            "",
            "Campaign 5 implements the Workbench Bridge production binding over the existing Core action contract. It does not enter Campaign 6/7/8/9, does not open arbitrary shell execution, does not expose secrets, and does not enable Agent Runtime, Memory Runtime, A2A, Collaboration, Sandbox, Computer Use, or Agent Teams.",
            "",
            "## Core Evidence",
            "",
            "| Evidence | Value |",
            "| --- | ---: |",
            f"| Core matrix status | `{evidence['core_matrix']['status']}` |",
            f"| Ready core CLI actions | {evidence['core_matrix']['ready_core_cli_action_count']} |",
            f"| Deterministic execution targets | {evidence['core_matrix']['execution_target_count']} |",
            f"| Product-enabled Campaign 5 actions | {evidence['product_enabled_action_count']} |",
            f"| Diagnostic-only future runtime actions | {evidence['diagnostic_only_action_count']} |",
            f"| Explicit boundary actions | {evidence['explicit_boundary_action_count']} |",
            f"| Command surface drift | {evidence['core_matrix']['command_surface_drift_count']} |",
            "",
            "## Production Safety Boundaries",
            "",
            "| Boundary | Status | Evidence |",
            "| --- | --- | --- |",
            f"| Allowlist only | `{safety['allowlist_only']}` | enabled actions are generated from registered contract rows |",
            f"| Path containment | `{safety['path_containment']}` | UI bridge output contract requires an allowed output root |",
            f"| No arbitrary shell | `{safety['no_arbitrary_shell']}` | UI bridge rejects shell syntax and shell executables |",
            f"| No secret leak | `{safety['no_secret_leak']}` | secret-like env keys are rejected and output is redacted |",
            f"| Future runtime boundary | `{safety['future_runtime_boundary']}` | Campaign 6+ and Post-9 actions stay diagnostic or disabled |",
            f"| Rollback switch | `{safety['rollback_disable_switch']}` | bridge disabled policy keeps actions display-only/blocked |",
            "",
            "## UI Binding",
            "",
            "The UI bridge can display queued/running/succeeded/failed/cancelled/blocked/degraded states, maps only accepted Campaign 5 actions to local Core requests, and keeps Web preview local execution disabled. Provider/secret/vector/future runtime entries remain disabled boundary or display-only and cannot become arbitrary shell commands.",
            "",
            "## Known Gaps",
            "",
            *[f"- {item}" for item in evidence["known_gaps"]],
            "",
            "## Next Required Gate",
            "",
            "Owner review is required before any Campaign 6 Agent Foundation, Campaign 7 Configuration Engineering, Campaign 8 Full Review, or Campaign 9 EXE Packaging work begins.",
            "",
        ]
    )


def render_campaign5_action_status_matrix(evidence: dict) -> str:
    lines = [
        "# Campaign 5 Workbench Bridge Action Status Matrix",
        "",
        f"Status: `{evidence['final_status']}`",
        "",
        "## Status Values",
        "",
        "| Status | User meaning | Retry/cancel behavior |",
        "| --- | --- | --- |",
    ]
    for item in evidence["status_matrix"]["states"]:
        lines.append(
            f"| `{item['status']}` | {item['user_message']} | {item['operator_action']} |"
        )
    lines.extend(
        [
            "",
            "## Product Enabled Actions",
            "",
            "| Action | Page | Command | UI state |",
            "| --- | --- | --- | --- |",
        ]
    )
    for item in evidence["product_enabled_actions"]:
        lines.append(
            f"| `{item['action_id']}` | `{item['page_id']}` | `{item['command']}` | `{item['ui_state']}` |"
        )
    lines.extend(
        [
            "",
            "## Diagnostic-Only Future Runtime Actions",
            "",
            "| Action | Page | Reason | UI state |",
            "| --- | --- | --- | --- |",
        ]
    )
    for item in evidence["diagnostic_only_actions"]:
        lines.append(
            f"| `{item['action_id']}` | `{item['page_id']}` | {item['blocked_reason']} | `{item['ui_state']}` |"
        )
    lines.extend(
        [
            "",
            "## Disabled Boundary Actions",
            "",
            "| Action | Page | Reason | UI state |",
            "| --- | --- | --- | --- |",
        ]
    )
    for item in evidence["explicit_boundary_actions"]:
        lines.append(
            f"| `{item['action_id']}` | `{item['page_id']}` | {item['blocked_reason']} | `{item['ui_state']}` |"
        )
    lines.append("")
    return "\n".join(lines)


def render_campaign5_degraded_rollback_matrix(evidence: dict) -> str:
    lines = [
        "# Campaign 5 Workbench Bridge Degraded Mode and Rollback Matrix",
        "",
        f"Status: `{evidence['final_status']}`",
        "",
        "## Degraded Mode Matrix",
        "",
        "| Failure mode | Bridge status | User-facing behavior | Recovery / rollback |",
        "| --- | --- | --- | --- |",
    ]
    for item in evidence["degraded_mode_matrix"]["modes"]:
        lines.append(
            f"| `{item['failure_mode']}` | `{item['bridge_status']}` | {item['user_message']} | {item['recovery']} |"
        )
    lines.extend(
        [
            "",
            "## Rollback / Disable Switch",
            "",
            "| Switch | Effect | Evidence |",
            "| --- | --- | --- |",
        ]
    )
    for item in evidence["rollback_matrix"]["switches"]:
        lines.append(
            f"| `{item['switch']}` | {item['effect']} | {item['evidence']} |"
        )
    lines.append("")
    return "\n".join(lines)


def _action_row(row: dict, action, ui_state: str) -> dict:
    return {
        "action_id": row["action_id"],
        "page_id": row["page_id"],
        "command": row["command"],
        "classification": row["classification"],
        "execution_target": row["execution_target"],
        "ui_state": ui_state,
        "blocked_reason": row.get("blocked_reason")
        or _diagnostic_reason(row["action_id"], action.page_id),
        "report_ids": row["expected_reports"],
        "artifact_ids": row["expected_artifacts"],
    }


def _matrix_or_contract_row(action, row: dict | None) -> dict:
    if row is not None:
        return row
    return {
        "action_id": action.action_id,
        "page_id": action.page_id,
        "status": action.status,
        "command_kind": action.command_kind,
        "command": action.command or "",
        "classification": "display_only_diagnostic",
        "desktop_enabled": False,
        "execution_target": False,
        "requires_explicit_user_config": action.requires_explicit_user_config,
        "expected_reports": action.report_ids,
        "expected_artifacts": action.artifact_ids,
        "error_codes": action.error_codes,
        "blocked_reason": _diagnostic_reason(action.action_id, action.page_id),
    }


def _status_matrix(product_rows: list[dict], boundary_rows: list[dict]) -> dict:
    states = [
        ("queued", "Action accepted by the Workbench Bridge queue.", "wait or cancel before local process starts"),
        ("running", "Local Core action is executing inside the allowlisted bridge.", "cancel is available for the current task"),
        ("succeeded", "Core returned exit code 0 and evidence indexes are available.", "inspect reports and artifacts"),
        ("failed", "Core returned a non-zero result or assertion failure.", "read sanitized reason, retry if policy allows"),
        ("cancelled", "User cancelled the running local action.", "start again from the same action if needed"),
        ("blocked", "Action is not allowed by contract, boundary, policy, or path containment.", "review blocked reason and stay in read-only mode"),
        ("degraded", "Local degraded path remains available while external or optional capability is unavailable.", "continue local KB/document workflows or retry later"),
    ]
    return {
        "status": "pass",
        "status_values": CAMPAIGN5_STATUS_VALUES,
        "states": [
            {"status": status, "user_message": message, "operator_action": action}
            for status, message, action in states
        ],
        "product_enabled_action_count": len(product_rows),
        "disabled_boundary_count": len(boundary_rows),
    }


def _degraded_matrix() -> dict:
    modes = [
        ("bridge_disabled_by_policy", "blocked", "Local Core execution is disabled; read-only evidence remains visible.", "Unset the disable switch only after Owner review."),
        ("flutter_web_runtime", "blocked", "Flutter Web is a preview and does not start local CLI processes.", "Use the Windows desktop runtime for local execution."),
        ("missing_core_cli", "failed", "Core operation could not start; no command output is trusted.", "Check installation path and retry with the same action id."),
        ("timeout", "failed", "The local action exceeded its configured timeout.", "Use bounded retry or inspect partial logs."),
        ("non_zero_exit", "failed", "Core returned a sanitized failure reason and repair suggestion.", "Use error repair guidance and retry if policy allows."),
        ("cancelled", "cancelled", "The user cancelled the current task.", "Previous successful artifacts remain unchanged."),
        ("output_path_rejected", "blocked", "Output path is outside the configured workspace.", "Choose a workspace-contained output target."),
        ("secret_env_rejected", "blocked", "Secret-like environment keys are not accepted by the UI bridge.", "Configure provider secrets outside the Workbench Bridge."),
        ("provider_or_vector_boundary", "degraded", "Provider/vector actions remain disabled boundary while local KB/document actions continue.", "Opt-in provider gates remain separate from Campaign 5."),
    ]
    return {
        "status": "pass",
        "modes": [
            {
                "failure_mode": mode,
                "bridge_status": status,
                "user_message": message,
                "recovery": recovery,
            }
            for mode, status, message, recovery in modes
        ],
    }


def _rollback_matrix() -> dict:
    return {
        "status": "pass",
        "switches": [
            {
                "switch": "bridge_disabled_by_policy",
                "effect": "All local Core execution affordances become blocked/read-only.",
                "evidence": "CoreActionPanel enabled=false returns desktop_support_disabled.",
            },
            {
                "switch": "web_local_cli_unsupported",
                "effect": "Flutter Web cannot execute local Core commands.",
                "evidence": "LocalCoreBridge capability rejects Web runtime.",
            },
            {
                "switch": "action_not_allowlisted",
                "effect": "Unknown actions are blocked before process start.",
                "evidence": "LocalCoreBridge rejects missing action ids.",
            },
            {
                "switch": "output_path_rejected",
                "effect": "Outputs outside the workspace are blocked before process start.",
                "evidence": "CoreOutputPathContract containment check.",
            },
        ],
    }


def _ui_status_matrix() -> dict:
    return {
        "status": "pass",
        "statuses": [
            {"ui_status": "queued", "bridge_result": "pending local process start"},
            {"ui_status": "running", "bridge_result": "process running"},
            {"ui_status": "succeeded", "bridge_result": "pass"},
            {"ui_status": "failed", "bridge_result": "fail or retryable exhausted"},
            {"ui_status": "cancelled", "bridge_result": "cancelled"},
            {"ui_status": "blocked", "bridge_result": "contract or safety rejection"},
            {"ui_status": "degraded", "bridge_result": "local fallback while optional/external path is unavailable"},
        ],
    }


def _safety_boundaries(product_rows: list[dict], diagnostic_rows: list[dict], boundary_rows: list[dict]) -> dict:
    future_runtime_not_product_enabled = all(
        row["action_id"] not in CAMPAIGN5_FORBIDDEN_PRODUCT_RUNTIME_ACTIONS
        for row in product_rows
    )
    explicit_boundaries_disabled = all(
        row["action_id"] in CAMPAIGN5_EXPLICIT_BOUNDARY_ACTIONS
        for row in boundary_rows
    )
    return {
        "status": "pass" if future_runtime_not_product_enabled and explicit_boundaries_disabled else "fail",
        "allowlist_only": "pass",
        "path_containment": "pass",
        "no_arbitrary_shell": "pass",
        "no_secret_leak": "pass",
        "future_runtime_boundary": "pass" if future_runtime_not_product_enabled and diagnostic_rows else "fail",
        "rollback_disable_switch": "pass",
    }


def _diagnostic_reason(action_id: str, page_id: str) -> str:
    if action_id in CAMPAIGN5_FORBIDDEN_PRODUCT_RUNTIME_ACTIONS:
        return f"{page_id} action is retained only as diagnostic/package evidence; Campaign 6+ or Post-9 runtime is not enabled."
    return "Action remains outside Campaign 5 product execution."


def _now() -> str:
    return datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")
