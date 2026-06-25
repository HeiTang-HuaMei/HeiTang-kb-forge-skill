from __future__ import annotations

from pathlib import Path

from pydantic import ValidationError

from heitang_kb_forge.exporters.jsonl_exporter import write_json
from heitang_kb_forge.schemas.harness_adapter_spec_schema import (
    HarnessAdapterSpec,
    HarnessAdapterSpecReport,
)


HARNESS_ADAPTER_SPEC_REQUIRED_FIELDS = [
    "adapter_id",
    "capability_id",
    "execution_mode",
    "input_contract",
    "output_contract",
    "boundary",
    "required_reports",
]
HARNESS_ADAPTER_ALLOWED_CAPABILITY_IDS = [
    "codex_execution_harness",
    "workbench_agent_harness",
    "policy_governance_basic",
    "credential_proxy_design",
]
HARNESS_ADAPTER_ALLOWED_EXECUTION_MODES = [
    "local_codex_handoff_contract",
    "local_workbench_agent_harness",
    "local_policy_governance_check",
    "local_credential_proxy_design_check",
]
HARNESS_ADAPTER_SPEC_BOUNDARY = {
    "external_harness_runtime": "not_started",
    "default_network": "forbidden",
    "secrets": "not_required",
    "ui_change": "not_required",
    "runtime_change": "not_required",
    "redis_service_packaging": "forbidden",
    "vector_service_packaging": "forbidden",
}


def default_harness_adapter_specs() -> list[dict]:
    return [
        {
            "adapter_id": "codex_local_handoff",
            "capability_id": "codex_execution_harness",
            "execution_mode": "local_codex_handoff_contract",
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
            "boundary": {
                "network": "not_required",
                "secrets": "not_required",
                "redis_service_packaging": "forbidden",
                "vector_service_packaging": "forbidden",
            },
            "required_reports": ["codex_harness_check_result.json"],
        },
        {
            "adapter_id": "workbench_agent_local_tool",
            "capability_id": "workbench_agent_harness",
            "execution_mode": "local_workbench_agent_harness",
            "input_contract": {
                "agent_name": "non_empty_string",
                "tool_name": "registered_local_tool",
                "query": "non_empty_string",
            },
            "output_contract": {
                "tool_input": "tool_input.json",
                "tool_result": "tool_result.json",
                "trace": "tool_execution_trace.json",
                "report": "workbench_agent_harness_report.json",
            },
            "boundary": {
                "network": "not_required",
                "secrets": "not_required",
                "redis_service_packaging": "forbidden",
                "vector_service_packaging": "forbidden",
            },
            "required_reports": ["workbench_agent_harness_report.json"],
        },
        {
            "adapter_id": "policy_governance_local_check",
            "capability_id": "policy_governance_basic",
            "execution_mode": "local_policy_governance_check",
            "input_contract": {
                "repo": "local_repository",
                "required_files": "capability_registry_and_status_files",
            },
            "output_contract": {
                "report": "policy_governance_basic_report.json",
                "closure": "policy_governance_basic_closure_report.md",
            },
            "boundary": {
                "network": "not_required",
                "secrets": "not_required",
                "redis_service_packaging": "forbidden",
                "vector_service_packaging": "forbidden",
            },
            "required_reports": ["policy_governance_basic_report.json"],
        },
        {
            "adapter_id": "credential_proxy_design_local_check",
            "capability_id": "credential_proxy_design",
            "execution_mode": "local_credential_proxy_design_check",
            "input_contract": {
                "provider_id": "non_empty_string",
                "credential_env": "environment_variable_name",
            },
            "output_contract": {
                "report": "credential_proxy_design_report.json",
                "closure": "credential_proxy_design_closure_report.md",
            },
            "boundary": {
                "network": "not_required",
                "secrets": "not_required",
                "redis_service_packaging": "forbidden",
                "vector_service_packaging": "forbidden",
            },
            "required_reports": ["credential_proxy_design_report.json"],
        },
    ]


def validate_harness_adapter_specs(entries: list[HarnessAdapterSpec | dict], output: Path | None = None) -> HarnessAdapterSpecReport:
    parsed: list[HarnessAdapterSpec] = []
    failed_checks: list[str] = []
    for index, entry in enumerate(entries):
        try:
            data = entry if isinstance(entry, HarnessAdapterSpec) else HarnessAdapterSpec.model_validate(entry)
        except ValidationError as exc:
            failed_checks.extend(f"entry_{index}:missing_or_invalid_{error['loc'][0]}" for error in exc.errors())
            continue
        parsed.append(data)
        failed_checks.extend(f"{data.adapter_id}:{failure}" for failure in _entry_failures(data))

    report = HarnessAdapterSpecReport(
        status="passed" if not failed_checks else "failed",
        adapter_count=len(parsed),
        failed_checks=failed_checks,
        adapter_summaries=[_summary(entry) for entry in parsed],
        allowed_capability_ids=HARNESS_ADAPTER_ALLOWED_CAPABILITY_IDS,
        allowed_execution_modes=HARNESS_ADAPTER_ALLOWED_EXECUTION_MODES,
        required_fields=HARNESS_ADAPTER_SPEC_REQUIRED_FIELDS,
        output_files=["harness_adapter_spec_report.json"],
        boundary=HARNESS_ADAPTER_SPEC_BOUNDARY,
    )
    if output:
        output.mkdir(parents=True, exist_ok=True)
        write_json(output / "harness_adapter_spec_report.json", report)
    return report


def _entry_failures(entry: HarnessAdapterSpec) -> list[str]:
    failures: list[str] = []
    if entry.capability_id not in HARNESS_ADAPTER_ALLOWED_CAPABILITY_IDS:
        failures.append("unknown_capability_id")
    if entry.execution_mode not in HARNESS_ADAPTER_ALLOWED_EXECUTION_MODES:
        failures.append("unknown_execution_mode")
    if entry.boundary.get("network") not in {"not_required", "manual_opt_in"}:
        failures.append("default_network_forbidden")
    if entry.boundary.get("redis_service_packaging") != "forbidden":
        failures.append("redis_service_packaging_boundary_missing")
    if entry.boundary.get("vector_service_packaging") != "forbidden":
        failures.append("vector_service_packaging_boundary_missing")
    if not entry.input_contract:
        failures.append("empty_input_contract")
    if not entry.output_contract:
        failures.append("empty_output_contract")
    if not entry.required_reports:
        failures.append("missing_required_reports")
    return failures


def _summary(entry: HarnessAdapterSpec) -> dict:
    return {
        "adapter_id": entry.adapter_id,
        "capability_id": entry.capability_id,
        "execution_mode": entry.execution_mode,
        "input_keys": sorted(entry.input_contract.keys()),
        "output_keys": sorted(entry.output_contract.keys()),
        "required_reports": entry.required_reports,
        "boundary": entry.boundary,
    }
