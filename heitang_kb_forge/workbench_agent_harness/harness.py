from __future__ import annotations

from pathlib import Path

from heitang_kb_forge.agent_tools.invoker import invoke_tool
from heitang_kb_forge.agent_tools.registry import get_agent_tool
from heitang_kb_forge.exporters.jsonl_exporter import write_json
from heitang_kb_forge.schemas.workbench_agent_harness_schema import (
    WorkbenchAgentHarnessInput,
    WorkbenchAgentHarnessReport,
)


WORKBENCH_AGENT_HARNESS_BOUNDARY = {
    "external_agent_process": "not_started",
    "network": "not_required",
    "secrets": "not_required",
    "redis_service_packaging": "forbidden",
    "vector_service_packaging": "forbidden",
}


def run_workbench_agent_harness(payload: WorkbenchAgentHarnessInput | dict, output: Path) -> WorkbenchAgentHarnessReport:
    data = payload if isinstance(payload, WorkbenchAgentHarnessInput) else WorkbenchAgentHarnessInput.model_validate(payload)
    output.mkdir(parents=True, exist_ok=True)
    failed_checks = _validate(data)
    if failed_checks:
        report = _report(data, "failed", failed_checks)
        write_json(output / "workbench_agent_harness_report.json", report)
        return report

    tool_input = _tool_input(data)
    write_json(output / "tool_input.json", tool_input)
    result, trace = invoke_tool(data.tool_name, output / "tool_input.json")
    write_json(output / "tool_result.json", result)
    write_json(output / "tool_execution_trace.json", trace)
    report = _report(
        data,
        "passed" if result.get("status") == "success" else "failed",
        [] if result.get("status") == "success" else ["tool_execution_failed"],
        result_summary={
            "tool_status": result.get("status"),
            "record_count": len(result.get("records", [])),
            "trace_status": trace.get("status"),
        },
        output_files=[
            "tool_input.json",
            "tool_result.json",
            "tool_execution_trace.json",
            "workbench_agent_harness_report.json",
        ],
    )
    write_json(output / "workbench_agent_harness_report.json", report)
    return report


def _validate(data: WorkbenchAgentHarnessInput) -> list[str]:
    failed_checks: list[str] = []
    try:
        get_agent_tool(data.tool_name)
    except ValueError:
        failed_checks.append("unknown_tool")
    if not data.query.strip():
        failed_checks.append("empty_query")
    if data.tool_name == "retrieve_knowledge" and not data.store:
        if not data.package:
            failed_checks.append("missing_package")
        elif not Path(data.package).exists():
            failed_checks.append("package_not_found")
    return failed_checks


def _tool_input(data: WorkbenchAgentHarnessInput) -> dict:
    payload = {
        "query": data.query,
        "top_k": data.top_k,
    }
    if data.store:
        payload["store"] = data.store
    if data.package:
        payload["package"] = data.package
    return payload


def _report(
    data: WorkbenchAgentHarnessInput,
    status: str,
    failed_checks: list[str],
    result_summary: dict | None = None,
    output_files: list[str] | None = None,
) -> WorkbenchAgentHarnessReport:
    input_keys = ["agent_name", "query", "top_k", "tool_name"]
    if data.package:
        input_keys.append("package")
    if data.store:
        input_keys.append("store")
    return WorkbenchAgentHarnessReport(
        status=status,
        agent_name=data.agent_name,
        tool_name=data.tool_name,
        input_keys=sorted(input_keys),
        output_files=output_files or ["workbench_agent_harness_report.json"],
        failed_checks=failed_checks,
        result_summary=result_summary or {},
        boundary=WORKBENCH_AGENT_HARNESS_BOUNDARY,
    )
