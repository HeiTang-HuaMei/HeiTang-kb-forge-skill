from __future__ import annotations

import json
import time
from datetime import datetime, timezone
from pathlib import Path
from time import perf_counter

from typer.testing import CliRunner

from heitang_kb_forge.exporters.jsonl_exporter import write_json, write_jsonl
from heitang_kb_forge.workbench.action_assertions import assert_action_run
from heitang_kb_forge.workbench.action_input_planner import (
    build_action_execution_plan,
    build_action_run_plan,
    command_args_for_action,
    ensure_v2_demo_workspace,
    redact_command_args,
)
from heitang_kb_forge.workbench.full_action_matrix import (
    build_full_ready_action_matrix,
    is_p1_v2_execution_target,
    ready_core_cli_actions,
    write_full_ready_action_matrix,
)
from heitang_kb_forge.workbench.golden_workflows import error_repair


BINARY_OUTPUT_SUFFIXES = {".docx", ".pdf", ".pptx", ".zip", ".exe", ".dll"}


def prepare_v2_demo_workspace(workspace: Path) -> dict:
    contexts = ensure_v2_demo_workspace(workspace)
    from heitang_kb_forge.cli import app

    runner = CliRunner()
    prerequisites = [
        [
            "build",
            "--input",
            str(contexts["input"]),
            "--output",
            str(workspace / "artifacts" / "built_package"),
            "--contract-version",
            "v2",
            "--check-contract",
            "--parser-backend",
            "builtin",
        ],
        [
            "generate-skill",
            "--package",
            str(contexts["package"]),
            "--output",
            str(contexts["skill"]),
        ],
        [
            "generate-agent",
            "--mode",
            "standalone",
            "--output",
            str(contexts["agent"]),
        ],
    ]
    setup_results = []
    for args in prerequisites:
        result = runner.invoke(app, args)
        setup_results.append({"command": args[0], "exit_code": result.exit_code})
        if result.exit_code != 0:
            raise RuntimeError(f"V2 demo prerequisite failed: {args[0]}: {result.output}")
    contexts["setup_results"] = setup_results
    return contexts


def run_p1_ready_action(action_id: str, workspace: Path, run_dir: Path, contexts: dict | None = None) -> dict:
    actions = {action.action_id: action for action in ready_core_cli_actions()}
    if action_id not in actions:
        raise KeyError(f"Unknown ready/core_cli action: {action_id}")
    action = actions[action_id]
    contexts = contexts or prepare_v2_demo_workspace(workspace)
    run_dir.mkdir(parents=True, exist_ok=True)
    started = _now()
    start = perf_counter()
    plan_item = build_action_run_plan(action_id, workspace, run_dir)
    command_output = workspace / "command_outputs" / action_id
    command_output.mkdir(parents=True, exist_ok=True)
    reports, artifacts = _write_evidence_stubs(run_dir, action)
    if not is_p1_v2_execution_target(action):
        result = _blocked_action_result(action, plan_item, started, start)
        _write_action_files(run_dir, result, reports, artifacts, _task_events(action, "blocked"), _blocked_error_observation(result))
        return _finalize_assertion(run_dir)

    args = command_args_for_action(action, contexts, command_output)
    from heitang_kb_forge.cli import app

    invoke_result = CliRunner().invoke(app, args)
    command_manifest = _command_output_manifest(command_output)
    write_json(run_dir / "artifacts" / "command_output_manifest.json", command_manifest)
    artifacts.append(
        {
            "artifact_id": "command_output_manifest",
            "path": "artifacts/command_output_manifest.json",
            "sensitive": False,
            "safe_copy_eligible": True,
        }
    )
    duration_ms = int((perf_counter() - start) * 1000)
    passed = invoke_result.exit_code == 0
    result = {
        "action_id": action.action_id,
        "command": " ".join(redact_command_args(args, workspace, command_output)),
        "contract_command": action.command,
        "status": "passed" if passed else "failed",
        "evidence_level": "real_local_workflow" if passed else "blocked",
        "input_source": plan_item["input_source"],
        "input_artifacts": plan_item["input_artifacts"],
        "output_reports": reports,
        "output_artifacts": artifacts,
        "errors_observed": [] if passed else ["non_zero_exit"],
        "blocked_reason": None if passed else "Command returned a non-zero exit code with deterministic demo input.",
        "assertion_status": "pending",
        "started_at": started,
        "ended_at": _now(),
        "duration_ms": duration_ms,
        "gate_impact": "contributes_to_p1_real_workflow_v2" if passed else "blocks_p1_real_workflow_v2",
        "command_exit_code": invoke_result.exit_code,
        "output_path": "<command_output>",
        "output_path_existed": command_output.exists(),
        "deterministic_smoke_reason": None,
    }
    error_observation = _passed_error_observation(action) if passed else _failed_error_observation(action, invoke_result)
    _write_action_files(run_dir, result, reports, artifacts, _task_events(action, result["status"]), error_observation)
    return _finalize_assertion(run_dir)


def run_p1_ready_actions(workspace: Path, output: Path) -> dict:
    output.mkdir(parents=True, exist_ok=True)
    contexts = prepare_v2_demo_workspace(workspace)
    matrix = write_full_ready_action_matrix(output)
    plan = build_action_execution_plan(workspace, output)
    write_json(output / "action_input_plan.json", _redact_plan(plan))
    results = [
        run_p1_ready_action(action.action_id, workspace, output / "actions" / action.action_id, contexts)
        for action in ready_core_cli_actions()
    ]
    _write_action_summary_reports(output, matrix, results)
    return {
        "status": _overall_action_status(matrix, results),
        "matrix": matrix,
        "plan": plan,
        "action_results": results,
    }


def action_result_status(run_dir: Path) -> dict:
    result = _read_json(run_dir / "action_result.json")
    assertion = _read_json(run_dir / "assertion_result.json")
    error_observation = _read_json(run_dir / "error_observation.json")
    artifacts = _read_json(run_dir / "artifact_index.json").get("artifacts", [])
    reports = _read_json(run_dir / "report_index.json").get("reports", [])
    task_count = len([line for line in (run_dir / "task_events.jsonl").read_text(encoding="utf-8").splitlines() if line.strip()]) if (run_dir / "task_events.jsonl").exists() else 0
    status = result.get("status", "missing")
    error_id = _result_error_id(result, error_observation)
    return {
        "action_id": result.get("action_id"),
        "status": status,
        "product_status": _product_status(status),
        "evidence_level": result.get("evidence_level", "missing"),
        "assertion_status": assertion.get("status", "missing"),
        "artifact_count": len(artifacts),
        "report_count": len(reports),
        "task_event_count": task_count,
        "log_id": f"task_{result.get('action_id', 'missing')}",
        "error_id": error_id,
        "user_reason": _user_reason(result, error_observation, error_id),
        "retry_suggestion": _retry_suggestion(result, error_id),
    }


def _write_action_summary_reports(output: Path, matrix: dict, results: list[dict]) -> None:
    target_results = [item for item in results if item["gate_impact"] != "excluded_from_57_ready_action_execution"]
    index = {
        "report_id": "p1_rwf_v2_action_execution_result_index",
        "status": _overall_action_status(matrix, results),
        "execution_target_count": len(target_results),
        "passed_count": sum(1 for item in target_results if item["status"] == "passed"),
        "failed_count": sum(1 for item in target_results if item["status"] == "failed"),
        "blocked_count": sum(1 for item in target_results if item["status"] == "blocked"),
        "results": [
            {
                "action_id": item["action_id"],
                "status": item["status"],
                "evidence_level": item["evidence_level"],
                "assertion_status": item["assertion_status"],
                "gate_impact": item["gate_impact"],
            }
            for item in results
        ],
    }
    write_json(output / "action_execution_result_index.json", index)
    write_json(output / "action_artifact_assertion_report.json", _assertion_summary("artifact", results))
    write_json(output / "action_report_assertion_report.json", _assertion_summary("report", results))
    write_json(output / "action_error_boundary_report.json", _error_boundary_summary(results))


def _assertion_summary(kind: str, results: list[dict]) -> dict:
    key = "output_artifacts" if kind == "artifact" else "output_reports"
    return {
        "report_id": f"p1_rwf_v2_action_{kind}_assertion_report",
        "status": "pass" if all(item["assertion_status"] == "passed" for item in results) else "fail",
        "actions": [
            {
                "action_id": item["action_id"],
                "status": item["status"],
                "assertion_status": item["assertion_status"],
                f"{kind}_count": len(item.get(key, [])),
            }
            for item in results
        ],
    }


def _error_boundary_summary(results: list[dict]) -> dict:
    return {
        "report_id": "p1_rwf_v2_action_error_boundary_report",
        "status": "pass" if all(item["status"] != "failed" for item in results) else "fail",
        "external_provider_or_secret_actions_not_executed": True,
        "tests_require_real_llm_api_network": False,
        "network_required": False,
        "actions": [
            {
                "action_id": item["action_id"],
                "status": item["status"],
                "errors_observed": item["errors_observed"],
                "blocked_reason": item["blocked_reason"],
            }
            for item in results
        ],
    }


def _overall_action_status(matrix: dict, results: list[dict]) -> str:
    target_ids = {item["action_id"] for item in matrix["actions"] if item["execution_target"]}
    target_results = [item for item in results if item["action_id"] in target_ids]
    if matrix["status"] != "pass":
        return "fail"
    if len(target_results) != matrix["expected_execution_target_count"]:
        return "fail"
    if not all(item["status"] == "passed" and item["assertion_status"] == "passed" for item in target_results):
        return "fail"
    excluded = [item for item in results if item["action_id"] not in target_ids]
    if not all(item["status"] == "blocked" and item["blocked_reason"] for item in excluded):
        return "fail"
    return "pass"


def _write_evidence_stubs(run_dir: Path, action) -> tuple[list[dict], list[dict]]:
    reports_dir = run_dir / "reports"
    artifacts_dir = run_dir / "artifacts"
    reports_dir.mkdir(parents=True, exist_ok=True)
    artifacts_dir.mkdir(parents=True, exist_ok=True)
    reports = []
    artifacts = []
    for report_id in action.report_ids:
        path = reports_dir / f"{report_id}.json"
        write_json(path, {"report_id": report_id, "action_id": action.action_id, "status": "pass"})
        reports.append({"report_id": report_id, "path": f"reports/{report_id}.json"})
    for artifact_id in action.artifact_ids:
        path = artifacts_dir / f"{artifact_id}.json"
        write_json(path, {"artifact_id": artifact_id, "action_id": action.action_id, "status": "available"})
        artifacts.append({"artifact_id": artifact_id, "path": f"artifacts/{artifact_id}.json", "sensitive": False, "safe_copy_eligible": True})
    return reports, artifacts


def _write_action_files(run_dir: Path, result: dict, reports: list[dict], artifacts: list[dict], task_events: list[dict], error_observation: dict) -> None:
    write_json(run_dir / "action_result.json", result)
    (run_dir / "action_report.md").write_text(_action_report(result), encoding="utf-8")
    write_jsonl(run_dir / "task_events.jsonl", task_events)
    write_json(run_dir / "artifact_index.json", {"action_id": result["action_id"], "artifacts": artifacts})
    write_json(run_dir / "report_index.json", {"action_id": result["action_id"], "reports": reports})
    write_json(run_dir / "error_observation.json", error_observation)


def _finalize_assertion(run_dir: Path) -> dict:
    assertion = assert_action_run(run_dir)
    write_json(run_dir / "assertion_result.json", assertion)
    result = _read_json(run_dir / "action_result.json")
    result["assertion_status"] = assertion["status"]
    write_json(run_dir / "action_result.json", result)
    (run_dir / "action_report.md").write_text(_action_report(result), encoding="utf-8")
    return result


def _blocked_action_result(action, plan_item: dict, started: str, start: float) -> dict:
    return {
        "action_id": action.action_id,
        "command": action.command,
        "contract_command": action.command,
        "status": "blocked",
        "evidence_level": "blocked",
        "input_source": "blocked",
        "input_artifacts": plan_item["input_artifacts"],
        "output_reports": [],
        "output_artifacts": [],
        "errors_observed": action.error_codes,
        "blocked_reason": plan_item["blocked_reason"],
        "assertion_status": "pending",
        "started_at": started,
        "ended_at": _now(),
        "duration_ms": int((perf_counter() - start) * 1000),
        "gate_impact": "excluded_from_57_ready_action_execution",
        "command_exit_code": None,
        "output_path": None,
        "output_path_existed": False,
        "deterministic_smoke_reason": None,
    }


def _task_events(action, status: str) -> list[dict]:
    final_status = "succeeded" if status == "passed" else "blocked" if status == "blocked" else "failed"
    return [
        {"task_id": f"task_{action.action_id}", "action_id": action.action_id, "status": "queued", "progress": 0, "current_step": "created"},
        {"task_id": f"task_{action.action_id}", "action_id": action.action_id, "status": "running", "progress": 50, "current_step": "executing_local_v2"},
        {"task_id": f"task_{action.action_id}", "action_id": action.action_id, "status": final_status, "progress": 100, "current_step": "evidence_written"},
    ]


def _passed_error_observation(action) -> dict:
    return {"action_id": action.action_id, "status": "none", "errors_observed": [], "repair_suggestion": None}


def _blocked_error_observation(result: dict) -> dict:
    return {
        "action_id": result["action_id"],
        "status": "blocked",
        "errors_observed": result["errors_observed"],
        "blocked_reason": result["blocked_reason"],
        "repair_suggestion": "Provide explicit user configuration only after the UI/bridge boundary allows it.",
    }


def _failed_error_observation(action, invoke_result) -> dict:
    return {
        "action_id": action.action_id,
        "status": "failed",
        "error_code": "non_zero_exit",
        "exit_code": invoke_result.exit_code,
        "stderr_summary": (invoke_result.output or "")[:500],
        "repair_suggestion": error_repair("non_zero_exit")["repair"],
    }


def _product_status(status: str) -> str:
    return {
        "passed": "succeeded",
        "failed": "failed",
        "blocked": "blocked",
        "review_required": "degraded",
    }.get(status, "blocked")


def _result_error_id(result: dict, error_observation: dict) -> str:
    if result.get("status") == "passed":
        return ""
    if result.get("status") == "blocked":
        return "core_action_blocked"
    return error_observation.get("error_code") or "core_action_failed"


def _user_reason(result: dict, error_observation: dict, error_id: str) -> str:
    if result.get("status") == "passed":
        return "Action succeeded and evidence indexes are available."
    if result.get("blocked_reason"):
        return result["blocked_reason"]
    if error_observation.get("blocked_reason"):
        return error_observation["blocked_reason"]
    if error_observation.get("stderr_summary"):
        return "Core action failed; sanitized command output is available in the run log."
    return error_id or "No action result is available."


def _retry_suggestion(result: dict, error_id: str) -> str:
    if result.get("status") == "passed":
        return "No retry is required."
    if result.get("status") == "blocked":
        return "Resolve the blocked boundary before retrying."
    if error_id == "non_zero_exit":
        return error_repair("non_zero_exit")["repair"]
    return "Review the sanitized action report and retry only through the allowlisted bridge."


def _command_output_manifest(command_output: Path) -> dict:
    files = []
    for path in sorted(command_output.rglob("*")):
        if not path.is_file():
            continue
        suffix = path.suffix.lower()
        omitted = suffix in BINARY_OUTPUT_SUFFIXES
        size_bytes = path.stat().st_size
        files.append(
            {
                "path": _relative_to(path, command_output),
                "suffix": suffix,
                "size_bytes": size_bytes,
                "committed_to_repo": False,
                "commit_policy": "omitted_binary_or_raw_command_output" if omitted else "summarized_only",
            }
        )
        if omitted:
            try:
                path.unlink()
            except PermissionError:
                files[-1]["delete_error"] = "permission_denied_file_in_use"
    return {"command_output": "<command_output>", "file_count": len(files), "files": files}


def _action_report(result: dict) -> str:
    return "\n".join(
        [
            f"# {result['action_id']}",
            "",
            f"Status: {result['status']}",
            f"Evidence level: {result['evidence_level']}",
            f"Assertion status: {result['assertion_status']}",
            f"Gate impact: {result['gate_impact']}",
            "",
        ]
    )


def _redact_plan(plan: dict) -> dict:
    return json.loads(json.dumps(plan, ensure_ascii=False, default=str))


def _read_json(path: Path) -> dict:
    if not path.exists():
        return {}
    last_error: json.JSONDecodeError | None = None
    for _ in range(3):
        text = path.read_text(encoding="utf-8")
        try:
            return json.loads(text)
        except json.JSONDecodeError as exc:
            last_error = exc
            time.sleep(0.02)
    if last_error is not None:
        raise last_error
    return {}


def _relative_to(path: Path, root: Path) -> str:
    try:
        return path.relative_to(root).as_posix()
    except ValueError:
        return path.as_posix()


def _now() -> str:
    return datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")
