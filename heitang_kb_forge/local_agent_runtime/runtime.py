from __future__ import annotations

import json
from datetime import datetime, timezone
from pathlib import Path

from heitang_kb_forge.exporters.jsonl_exporter import write_json
from heitang_kb_forge.multi_kb_orchestration import orchestrate_multi_kb_agents


V310_LOCAL_AGENT_RUNTIME_OUTPUT_FILES = [
    "local_agent_runtime_session.json",
    "local_agent_runtime_trace.json",
    "mother_child_runtime_trace.json",
    "child_task_route_trace.json",
    "child_kb_access_report.json",
    "child_memory_isolation_report.json",
    "workflow_shared_memory_report.json",
    "parent_memory_writeback_actions.json",
    "local_agent_runtime_status.json",
    "local_agent_runtime_report.md",
]


def run_local_agent_runtime(
    packages: list[Path],
    output: Path,
    agents: list[Path] | None = None,
    task: str = "",
    mother_agent: Path | None = None,
    workflow_shared_memory: bool = False,
    parent_writeback: bool = False,
    top_k: int = 3,
) -> dict:
    output.mkdir(parents=True, exist_ok=True)
    orchestration = orchestrate_multi_kb_agents(
        packages,
        output,
        agents or [],
        task,
        mother_agent,
        workflow_shared_memory,
        parent_writeback,
    )
    hierarchy_trace = _read_json(output / "hierarchy_trace.json")
    selected = hierarchy_trace.get("selected_child_agent")
    access = hierarchy_trace.get("access_checks", {})
    selected_access = _selected_access(selected, access)
    evidence = _authorized_evidence(packages, selected, top_k) if selected_access["authorized"] else []
    blocked = not selected_access["authorized"]
    response = _response(task, selected, evidence, blocked)
    session = {
        "local_agent_runtime_session_version": "3.10.0-alpha.1",
        "session_id": f"local-runtime-{datetime.now(timezone.utc).strftime('%Y%m%d%H%M%S')}",
        "task": task,
        "status": "blocked" if blocked else "pass",
        "mother_agent": hierarchy_trace.get("mother_agent", {}).get("agent_id"),
        "selected_child_agent": selected.get("agent_id") if selected else None,
        "selected_child_mode": selected.get("mode") if selected else None,
        "response": response,
        "evidence": evidence,
        "llm_used": False,
        "network_used": False,
        "tests_require_real_llm_api_network": False,
    }
    route_trace = {
        "child_task_route_trace_version": "3.10.0-alpha.1",
        "task": task,
        "route": hierarchy_trace.get("task_route", {}),
        "selected_child_agent": selected,
        "route_status": "blocked" if blocked else "routed",
    }
    access_report = {
        "child_kb_access_report_version": "3.10.0-alpha.1",
        "status": "blocked" if blocked else "pass",
        "selected_child_agent": selected.get("agent_id") if selected else None,
        "authorized": selected_access["authorized"],
        "allowed_kbs": selected_access["allowed_kbs"],
        "blocked_kbs": selected_access["blocked_kbs"],
        "policy": "child_can_only_read_bound_kbs_or_no_kb_for_standalone",
    }
    isolation = _memory_isolation(selected, hierarchy_trace, workflow_shared_memory)
    shared = {
        "workflow_shared_memory_report_version": "3.10.0-alpha.1",
        "enabled": workflow_shared_memory,
        "policy": "explicit_only",
        "shared_memory_records": [{"task": task, "child_agent": selected.get("agent_id")}] if workflow_shared_memory and selected else [],
        "child_private_memory_preserved": True,
    }
    writeback = {
        "parent_memory_writeback_actions_version": "3.10.0-alpha.1",
        "enabled": parent_writeback,
        "policy": "selective_candidate_queue_only",
        "actions": _writeback_actions(output),
        "auto_promoted": False,
    }
    runtime_trace = {
        "local_agent_runtime_trace_version": "3.10.0-alpha.1",
        "steps": [
            {"name": "load_agent_hierarchy", "status": "pass"},
            {"name": "route_task_to_child", "status": route_trace["route_status"]},
            {"name": "enforce_child_kb_access", "status": access_report["status"]},
            {"name": "preserve_child_private_memory", "status": "pass"},
            {"name": "workflow_shared_memory", "status": "enabled" if workflow_shared_memory else "disabled"},
            {"name": "selective_parent_writeback", "status": "queued" if writeback["actions"] else "disabled"},
        ],
    }
    status = {
        "local_agent_runtime_status_version": "3.10.0-alpha.1",
        "status": session["status"],
        "runtime_mode": "deterministic_local_smoke",
        "agent_runtime_full_implementation": False,
        "mother_child_operations_available": True,
        "child_kb_boundaries_enforced": True,
        "child_private_memory_default": True,
        "workflow_shared_memory_enabled": workflow_shared_memory,
        "selective_parent_writeback_enabled": parent_writeback,
        "llm_required": False,
        "network_required": False,
        "output_files": V310_LOCAL_AGENT_RUNTIME_OUTPUT_FILES,
    }
    write_json(output / "local_agent_runtime_session.json", session)
    write_json(output / "child_task_route_trace.json", route_trace)
    write_json(output / "child_kb_access_report.json", access_report)
    write_json(output / "child_memory_isolation_report.json", isolation)
    write_json(output / "workflow_shared_memory_report.json", shared)
    write_json(output / "parent_memory_writeback_actions.json", writeback)
    write_json(output / "mother_child_runtime_trace.json", {"mother_child_runtime_trace_version": "3.10.0-alpha.1", "hierarchy": hierarchy_trace, "session": session})
    write_json(output / "local_agent_runtime_trace.json", runtime_trace)
    write_json(output / "local_agent_runtime_status.json", status)
    (output / "local_agent_runtime_report.md").write_text(_report(status, session, access_report), encoding="utf-8")
    return status | {"orchestration": orchestration}


def _selected_access(selected: dict | None, access: dict) -> dict:
    if not selected:
        return {"authorized": False, "allowed_kbs": [], "blocked_kbs": ["no_child_agent"]}
    if selected.get("mode") == "standalone":
        return {"authorized": True, "allowed_kbs": [], "blocked_kbs": []}
    checks = {item.get("agent_id"): item for item in access.get("checks", [])}
    check = checks.get(selected.get("agent_id"), {})
    return {
        "authorized": check.get("status") == "pass" and bool(check.get("allowed_kbs")),
        "allowed_kbs": check.get("allowed_kbs", []),
        "blocked_kbs": check.get("blocked_kbs", []),
    }


def _authorized_evidence(packages: list[Path], selected: dict | None, top_k: int) -> list[dict]:
    allowed = set(selected.get("bound_kbs", []) if selected else [])
    if selected and selected.get("mode") == "standalone":
        return []
    evidence = []
    for package in packages:
        manifest = _read_json(package / "manifest.json")
        package_id = manifest.get("package_id") or package.name
        if package_id not in allowed:
            continue
        for row in _read_jsonl(package / "chunks.jsonl")[:top_k]:
            evidence.append({"package_id": package_id, "chunk_id": row.get("chunk_id"), "text": row.get("text", "")})
            if len(evidence) >= top_k:
                return evidence
    return evidence


def _response(task: str, selected: dict | None, evidence: list[dict], blocked: bool) -> dict:
    if blocked:
        return {"status": "refused", "text": "Child agent is not authorized to access the requested KB."}
    if selected and selected.get("mode") == "standalone":
        return {"status": "pass", "text": f"Standalone child handled local planning task: {task}"}
    text = evidence[0]["text"] if evidence else "No evidence selected."
    return {"status": "pass", "text": text}


def _memory_isolation(selected: dict | None, hierarchy_trace: dict, workflow_shared_memory: bool) -> dict:
    children = [
        {
            "agent_id": child.get("agent_id"),
            "private_memory": True,
            "workflow_shared_memory": workflow_shared_memory,
            "parent_memory_write_allowed": False,
        }
        for child in hierarchy_trace.get("child_agents", [])
    ]
    return {
        "child_memory_isolation_report_version": "3.10.0-alpha.1",
        "status": "pass",
        "selected_child_agent": selected.get("agent_id") if selected else None,
        "child_private_memory_default": True,
        "children": children,
    }


def _writeback_actions(output: Path) -> list[dict]:
    queue = output / "memory_candidate_queue.jsonl"
    if not queue.exists():
        return []
    return [
        {"action": "review_memory_candidate", "candidate_id": row.get("candidate_id"), "status": "queued"}
        for row in _read_jsonl(queue)
    ]


def _report(status: dict, session: dict, access: dict) -> str:
    return f"""# Local Agent Runtime Report

- Status: {status['status']}
- Runtime mode: {status['runtime_mode']}
- Selected child: {session['selected_child_agent']}
- KB access: {access['status']}
- LLM required: {status['llm_required']}
- Network required: {status['network_required']}
"""


def _read_json(path: Path) -> dict:
    if not path.exists():
        return {}
    return json.loads(path.read_text(encoding="utf-8"))


def _read_jsonl(path: Path) -> list[dict]:
    if not path.exists():
        return []
    return [json.loads(line) for line in path.read_text(encoding="utf-8").splitlines() if line.strip()]
