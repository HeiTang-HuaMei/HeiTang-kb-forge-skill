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
    "multi_kb_orchestration_trace.json",
    "multi_kb_orchestration_report.md",
]


def orchestrate_multi_kb_agents(packages: list[Path], output: Path, agents: list[Path] | None = None, query: str = "") -> dict:
    output.mkdir(parents=True, exist_ok=True)
    package_records = [_package_record(package, query) for package in packages]
    agent_records = [_agent_record(agent) for agent in agents or []]
    route_map = {"multi_kb_route_map_version": "3.2.0-alpha.1", "query": query, "routes": package_records}
    graph = {
        "multi_agent_binding_graph_version": "3.2.0-alpha.1",
        "nodes": _nodes(package_records, agent_records),
        "edges": _edges(package_records, agent_records),
    }
    conflict_report = _conflicts(package_records)
    manifest = {
        "multi_kb_orchestration_version": "3.2.0-alpha.1",
        "status": "pass" if packages else "fail",
        "package_count": len(package_records),
        "agent_count": len(agent_records),
        "conflict_count": len(conflict_report["conflicts"]),
        "output_files": MULTI_KB_ORCHESTRATION_OUTPUT_FILES,
    }
    trace = {
        "multi_kb_orchestration_trace_version": "3.2.0-alpha.1",
        "steps": [
            {"name": "load_packages", "status": "pass", "count": len(package_records)},
            {"name": "load_agents", "status": "pass", "count": len(agent_records)},
            {"name": "build_routes", "status": manifest["status"]},
            {"name": "detect_conflicts", "status": "warning" if conflict_report["conflicts"] else "pass"},
        ],
    }
    write_json(output / "multi_kb_orchestration_manifest.json", manifest)
    write_json(output / "multi_kb_route_map.json", route_map)
    write_json(output / "multi_agent_binding_graph.json", graph)
    write_json(output / "multi_kb_conflict_report.json", conflict_report)
    write_json(output / "multi_kb_orchestration_trace.json", trace)
    (output / "multi_kb_orchestration_report.md").write_text(_report(manifest, conflict_report), encoding="utf-8")
    return manifest


def _package_record(package: Path, query: str) -> dict:
    manifest = _read_json(package / "manifest.json")
    chunks = _read_jsonl(package / "chunks.jsonl")
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
    profile = _yaml_like(agent / "agent_profile.yaml")
    return {
        "agent_id": profile.get("agent_id", agent.name),
        "agent_name": profile.get("agent_name", agent.name),
        "agent_path": str(agent).replace("\\", "/"),
        "source_package_id": profile.get("source_package_id"),
    }


def _nodes(packages: list[dict], agents: list[dict]) -> list[dict]:
    return [{"id": item["package_id"], "type": "knowledge_package"} for item in packages] + [
        {"id": item["agent_id"], "type": "agent"} for item in agents
    ]


def _edges(packages: list[dict], agents: list[dict]) -> list[dict]:
    package_ids = {item["package_id"] for item in packages}
    return [
        {"from": agent["agent_id"], "to": agent["source_package_id"], "relationship": "bound_to_package"}
        for agent in agents
        if agent.get("source_package_id") in package_ids
    ]


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
