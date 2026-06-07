from __future__ import annotations

import json
import re
from pathlib import Path

from heitang_kb_forge.exporters.jsonl_exporter import write_json


MULTI_KB_ORCHESTRATION_OUTPUT_FILES = [
    "multi_kb_orchestration_manifest.json",
    "multi_kb_route_map.json",
    "multi_agent_binding_graph.json",
    "multi_kb_conflict_report.json",
    "hierarchy_trace.json",
    "memory_candidate_queue.jsonl",
    "memory_writeback_report.json",
    "memory_promotion_report.json",
    "memory_isolation_report.json",
    "memory_lifecycle_report.json",
    "multi_kb_orchestration_trace.json",
    "multi_kb_orchestration_report.md",
]


def orchestrate_multi_kb_agents(
    packages: list[Path],
    output: Path,
    agents: list[Path] | None = None,
    query: str = "",
    mother_agent: Path | None = None,
    workflow_shared_memory: bool = False,
    parent_writeback: bool = False,
) -> dict:
    if not packages:
        raise ValueError("Multi-KB orchestration requires at least one package")
    missing = [str(package) for package in packages if not package.exists() or not package.is_dir()]
    if missing:
        raise FileNotFoundError(f"Package not found: {', '.join(missing)}")
    missing_agents = [str(agent) for agent in agents or [] if not agent.exists() or not agent.is_dir()]
    if missing_agents:
        raise FileNotFoundError(f"Agent package not found: {', '.join(missing_agents)}")
    if mother_agent is not None and (not mother_agent.exists() or not mother_agent.is_dir()):
        raise FileNotFoundError(f"Mother agent package not found: {mother_agent}")
    output.mkdir(parents=True, exist_ok=True)
    package_records = [_package_record(package, query) for package in packages]
    agent_records = [_agent_record(agent) for agent in agents or []]
    mother_record = _mother_agent_record(mother_agent)
    selected_agent = _select_agent(agent_records, package_records, query)
    hierarchy = _hierarchy(mother_record, agent_records, workflow_shared_memory, parent_writeback)
    access_checks = _access_checks(agent_records, package_records, selected_agent)
    memory_candidates = _memory_candidates(selected_agent, mother_record, query, parent_writeback)
    memory_writeback_report = _memory_writeback_report(memory_candidates, parent_writeback)
    memory_promotion_report = _memory_promotion_report(memory_candidates)
    memory_isolation_report = _memory_isolation_report(agent_records, workflow_shared_memory)
    memory_lifecycle_report = _memory_lifecycle_report(memory_candidates)
    route_map = {
        "multi_kb_route_map_version": "3.2.0-alpha.1",
        "query": query,
        "routes": package_records,
        "agent_registry": agent_records,
        "agent_hierarchy": hierarchy,
        "selected_agent": selected_agent,
        "selected_child_agent": selected_agent,
        "selected_agent_mode": selected_agent.get("mode") if selected_agent else None,
        "routing_policy": "kb_questions_prefer_kb_bound_agents_planning_tasks_prefer_standalone_agents",
    }
    graph = {
        "multi_agent_binding_graph_version": "3.2.0-alpha.1",
        "nodes": _nodes(package_records, agent_records, mother_record),
        "edges": _edges(package_records, agent_records, mother_record),
    }
    conflict_report = _conflicts(package_records)
    manifest = {
        "multi_kb_orchestration_version": "3.2.0-alpha.1",
        "status": "pass",
        "package_count": len(package_records),
        "agent_count": len(agent_records),
        "mother_agent": mother_record["agent_id"],
        "child_agent_count": len(agent_records),
        "kb_bound_agent_count": len([agent for agent in agent_records if agent["mode"] == "kb_bound"]),
        "standalone_agent_count": len([agent for agent in agent_records if agent["mode"] == "standalone"]),
        "workflow_shared_memory": workflow_shared_memory,
        "parent_writeback": parent_writeback,
        "memory_candidate_count": len(memory_candidates),
        "conflict_count": len(conflict_report["conflicts"]),
        "output_files": MULTI_KB_ORCHESTRATION_OUTPUT_FILES,
    }
    hierarchy_trace = {
        "hierarchy_trace_version": "3.2.0-alpha.1",
        "mother_agent": mother_record,
        "child_agents": agent_records,
        "parent_child_binding": hierarchy["parent_child_binding"],
        "selected_child_agent": selected_agent,
        "task_route": {
            "from": mother_record["agent_id"],
            "to": selected_agent.get("agent_id") if selected_agent else None,
            "query": query,
            "route_reason": selected_agent.get("route_reason") if selected_agent else "no_child_agent",
        },
        "access_checks": access_checks,
    }
    trace = {
        "multi_kb_orchestration_trace_version": "3.2.0-alpha.1",
        "steps": [
            {"name": "load_packages", "status": "pass", "count": len(package_records)},
            {"name": "load_agents", "status": "pass", "count": len(agent_records)},
            {"name": "build_agent_hierarchy", "status": "pass"},
            {"name": "enforce_child_kb_boundaries", "status": "pass" if not access_checks["blocked"] else "blocked"},
            {"name": "preserve_child_private_memory", "status": "pass"},
            {"name": "queue_parent_memory_writeback", "status": "queued" if memory_candidates else "skipped"},
            {"name": "build_routes", "status": manifest["status"]},
            {"name": "detect_conflicts", "status": "warning" if conflict_report["conflicts"] else "pass"},
        ],
    }
    write_json(output / "multi_kb_orchestration_manifest.json", manifest)
    write_json(output / "multi_kb_route_map.json", route_map)
    write_json(output / "multi_agent_binding_graph.json", graph)
    write_json(output / "multi_kb_conflict_report.json", conflict_report)
    write_json(output / "hierarchy_trace.json", hierarchy_trace)
    (output / "memory_candidate_queue.jsonl").write_text(
        "".join(json.dumps(candidate, ensure_ascii=False) + "\n" for candidate in memory_candidates),
        encoding="utf-8",
    )
    write_json(output / "memory_writeback_report.json", memory_writeback_report)
    write_json(output / "memory_promotion_report.json", memory_promotion_report)
    write_json(output / "memory_isolation_report.json", memory_isolation_report)
    write_json(output / "memory_lifecycle_report.json", memory_lifecycle_report)
    write_json(output / "multi_kb_orchestration_trace.json", trace)
    (output / "multi_kb_orchestration_report.md").write_text(_report(manifest, conflict_report), encoding="utf-8")
    return manifest


def _package_record(package: Path, query: str) -> dict:
    manifest = _read_json(package / "manifest.json")
    chunks = _read_jsonl(package / "chunks.jsonl")
    if not chunks:
        raise ValueError(f"Package requires chunks.jsonl records for orchestration: {package}")
    terms = sorted({term for chunk in chunks for term in _terms(str(chunk.get("text", "")))})
    query_terms = set(_terms(query))
    return {
        "package_id": str(manifest.get("package_id") or package.name),
        "package_path": str(package).replace("\\", "/"),
        "domain": manifest.get("domain", "general"),
        "chunk_count": len(chunks),
        "route_score": len(query_terms.intersection(terms)) if query_terms else len(chunks),
        "terms": terms[:25],
    }


def _agent_record(agent: Path) -> dict:
    manifest = _read_json(agent / "agent_manifest.json")
    profile = _yaml_like(agent / "agent_profile.yaml")
    mode = str(manifest.get("mode") or profile.get("mode") or ("kb_bound" if profile.get("source_package_id") else "standalone"))
    source_package_id = profile.get("source_package_id") if mode == "kb_bound" else None
    return {
        "agent_id": manifest.get("agent_id") or profile.get("agent_id", agent.name),
        "agent_name": manifest.get("name") or profile.get("agent_name", agent.name),
        "mode": mode,
        "agent_path": str(agent).replace("\\", "/"),
        "source_package_id": source_package_id,
        "bound_kbs": [source_package_id] if source_package_id else [],
        "capabilities": manifest.get("capabilities", []),
        "memory_policy": manifest.get("memory_policy", {}),
        "provider_profile": manifest.get("provider_profile", {}),
        "tool_policy": manifest.get("tool_policy", {}),
        "routing_tags": _routing_tags(manifest, profile, mode),
        "private_memory": True,
    }


def _mother_agent_record(agent: Path | None) -> dict:
    if agent is None:
        return {"agent_id": "mother_agent", "agent_name": "Mother Agent", "mode": "mother_agent", "agent_path": None}
    manifest = _read_json(agent / "agent_manifest.json")
    profile = _yaml_like(agent / "agent_profile.yaml")
    return {
        "agent_id": manifest.get("agent_id") or profile.get("agent_id", agent.name),
        "agent_name": manifest.get("name") or profile.get("agent_name", agent.name),
        "mode": "mother_agent",
        "agent_path": str(agent).replace("\\", "/"),
    }


def _nodes(packages: list[dict], agents: list[dict], mother_agent: dict) -> list[dict]:
    return [{"id": item["package_id"], "type": "knowledge_package"} for item in packages] + [
        {"id": mother_agent["agent_id"], "type": "agent", "mode": "mother_agent", "kb_binding": "none"}
    ] + [
        {"id": item["agent_id"], "type": "agent", "mode": item["mode"], "kb_binding": "none" if item["mode"] == "standalone" else "bound"}
        for item in agents
    ]


def _edges(packages: list[dict], agents: list[dict], mother_agent: dict) -> list[dict]:
    package_ids = {item["package_id"] for item in packages}
    parent_edges = [
        {"from": mother_agent["agent_id"], "to": agent["agent_id"], "relationship": "parent_child_binding"}
        for agent in agents
    ]
    kb_edges = [
        {"from": agent["agent_id"], "to": agent["source_package_id"], "relationship": "bound_to_package"}
        for agent in agents
        if agent["mode"] == "kb_bound" and agent.get("source_package_id") in package_ids
    ]
    return kb_edges + parent_edges


def _select_agent(agents: list[dict], packages: list[dict], query: str) -> dict | None:
    if not agents:
        return None
    query_terms = set(_terms(query))
    planning_terms = {"plan", "planning", "process", "format", "formatting", "coach", "write", "writing", "project"}
    if query_terms.intersection(planning_terms):
        standalone = [agent for agent in agents if agent["mode"] == "standalone"]
        if standalone:
            return standalone[0] | {"route_reason": "planning_or_process_task"}
    package_ids = {item["package_id"] for item in packages}
    kb_bound = [agent for agent in agents if agent["mode"] == "kb_bound" and set(agent.get("bound_kbs", [])).intersection(package_ids)]
    if kb_bound:
        return kb_bound[0] | {"route_reason": "kb_grounded_question"}
    return agents[0] | {"route_reason": "fallback_no_kb_bound_agent"}


def _hierarchy(mother_agent: dict, agents: list[dict], workflow_shared_memory: bool, parent_writeback: bool) -> dict:
    return {
        "agent_hierarchy_version": "3.2.0-alpha.1",
        "mother_agent": mother_agent,
        "child_agents": [
            agent
            | {
                "role": "child_agent",
                "memory_policy": {
                    "private_memory": True,
                    "workflow_shared_memory": workflow_shared_memory,
                    "parent_writeback": parent_writeback,
                },
            }
            for agent in agents
        ],
        "parent_child_binding": [
            {
                "parent": mother_agent["agent_id"],
                "child": agent["agent_id"],
                "child_mode": agent["mode"],
                "bound_kbs": agent.get("bound_kbs", []),
            }
            for agent in agents
        ],
        "memory_policy": {
            "child_private_memory_default": True,
            "workflow_shared_memory_enabled": workflow_shared_memory,
            "selective_parent_memory_writeback": parent_writeback,
        },
    }


def _access_checks(agents: list[dict], packages: list[dict], selected_agent: dict | None) -> dict:
    package_ids = {item["package_id"] for item in packages}
    checks = []
    for agent in agents:
        if agent["mode"] != "kb_bound":
            checks.append({"agent_id": agent["agent_id"], "status": "pass", "allowed_kbs": []})
            continue
        unauthorized = sorted(set(agent.get("bound_kbs", [])) - package_ids)
        checks.append(
            {
                "agent_id": agent["agent_id"],
                "status": "blocked" if unauthorized else "pass",
                "allowed_kbs": sorted(set(agent.get("bound_kbs", [])).intersection(package_ids)),
                "blocked_kbs": unauthorized,
            }
        )
    selected_blocked = bool(selected_agent and selected_agent.get("mode") == "kb_bound" and not set(selected_agent.get("bound_kbs", [])).intersection(package_ids))
    return {
        "status": "blocked" if any(check["status"] == "blocked" for check in checks) or selected_blocked else "pass",
        "blocked": any(check["status"] == "blocked" for check in checks) or selected_blocked,
        "checks": checks,
    }


def _memory_candidates(selected_agent: dict | None, mother_agent: dict, query: str, parent_writeback: bool) -> list[dict]:
    if not parent_writeback or selected_agent is None:
        return []
    return [
        {
            "candidate_id": f"{selected_agent['agent_id']}-candidate-1",
            "source_child_agent": selected_agent["agent_id"],
            "target_parent": mother_agent["agent_id"],
            "status": "queued",
            "promotion_required": True,
            "content_summary": query[:120],
        }
    ]


def _memory_writeback_report(candidates: list[dict], parent_writeback: bool) -> dict:
    return {
        "memory_writeback_report_version": "3.2.0-alpha.1",
        "selective_parent_memory_writeback": parent_writeback,
        "memory_lifecycle": _memory_lifecycle_fields(len(candidates)),
        "candidate_count": len(candidates),
        "promoted_count": 0,
        "status": "queued" if candidates else "disabled",
    }


def _memory_promotion_report(candidates: list[dict]) -> dict:
    return {
        "memory_promotion_report_version": "3.2.0-alpha.1",
        "memory_lifecycle": _memory_lifecycle_fields(len(candidates)),
        "candidate_count": len(candidates),
        "promoted": [],
        "status": "pending_review" if candidates else "empty",
    }


def _memory_isolation_report(agents: list[dict], workflow_shared_memory: bool) -> dict:
    return {
        "memory_isolation_report_version": "3.2.0-alpha.1",
        "child_private_memory_default": True,
        "workflow_shared_memory_enabled": workflow_shared_memory,
        "memory_lifecycle": _memory_lifecycle_fields(0),
        "children": [
            {
                "agent_id": agent["agent_id"],
                "private_memory": True,
                "workflow_shared_memory": workflow_shared_memory,
                "parent_memory_write_allowed": False,
            }
            for agent in agents
        ],
        "status": "pass",
    }


def _memory_lifecycle_report(candidates: list[dict]) -> dict:
    return {
        "memory_lifecycle_report_version": "3.2.0-alpha.1",
        "storage_backend": "local_workspace",
        "supported_storage_backends": ["local_workspace", "local_db", "byo_cloud"],
        "memory_lifecycle": _memory_lifecycle_fields(len(candidates)),
        "status": "contract_only",
    }


def _memory_lifecycle_fields(candidate_count: int) -> dict:
    return {
        "session_log": {"enabled": True, "storage": "local_workspace", "record_count": 0},
        "short_term_memory": {"enabled": True, "storage": "local_workspace", "record_count": 0},
        "summary_memory": {"enabled": True, "storage": "local_workspace", "record_count": 0},
        "long_term_memory": {"enabled": False, "storage": "future_backend", "record_count": 0},
        "memory_candidates": {"enabled": True, "storage": "memory_candidate_queue.jsonl", "record_count": candidate_count},
        "memory_index": {"enabled": True, "storage": "local_workspace", "entry_count": 0},
        "retention_policy": {"mode": "explicit", "default_days": None},
        "compaction_policy": {"mode": "summary_after_budget", "status": "not_required"},
        "token_budget_policy": {"mode": "bounded", "status": "configured"},
    }


def _routing_tags(manifest: dict, profile: dict, mode: str) -> list[str]:
    tags = [mode]
    tags.extend(str(item).lower().replace(" ", "_") for item in manifest.get("capabilities", [])[:5])
    agent_type = manifest.get("agent_type") or profile.get("agent_type")
    if agent_type:
        tags.append(str(agent_type))
    return tags


def _conflicts(packages: list[dict]) -> dict:
    conflicts = []
    for index, left in enumerate(packages):
        for right in packages[index + 1 :]:
            overlap = sorted(set(left["terms"]).intersection(right["terms"]))
            if overlap:
                conflicts.append({"left": left["package_id"], "right": right["package_id"], "overlap_terms": overlap[:10]})
    return {"multi_kb_conflict_report_version": "3.2.0-alpha.1", "status": "warning" if conflicts else "pass", "conflicts": conflicts}


def _report(manifest: dict, conflict_report: dict) -> str:
    return "\n".join(
        [
            "# Multi-KB Orchestration Report",
            "",
            f"Status: {manifest['status']}",
            f"Packages: {manifest['package_count']}",
            f"Agents: {manifest['agent_count']}",
            f"Conflicts: {manifest['conflict_count']}",
            f"Conflict status: {conflict_report['status']}",
            "",
        ]
    )


def _terms(text: str) -> list[str]:
    return [term.lower() for term in re.findall(r"[A-Za-z][A-Za-z0-9_]{2,}", text)]


def _read_json(path: Path) -> dict:
    if not path.exists():
        return {}
    return json.loads(path.read_text(encoding="utf-8"))


def _read_jsonl(path: Path) -> list[dict]:
    if not path.exists():
        return []
    return [json.loads(line) for line in path.read_text(encoding="utf-8").splitlines() if line.strip()]


def _yaml_like(path: Path) -> dict:
    data = {}
    if not path.exists():
        return data
    for line in path.read_text(encoding="utf-8").splitlines():
        if ":" in line and not line.startswith(" "):
            key, value = line.split(":", 1)
            data[key.strip()] = value.strip()
    return data
