from pathlib import Path
import json

from heitang_kb_forge.exporters.jsonl_exporter import write_json


def rebuild_relationship_graph(workspace: Path) -> dict:
    registries = workspace / "registries"
    packages = _read_jsonl(registries / "package_registry.jsonl")
    skills = _read_jsonl(registries / "skill_registry.jsonl")
    agents = _read_jsonl(registries / "agent_registry.jsonl")
    nodes = []
    edges = []
    for item in packages:
        nodes.append({"id": item["package_id"], "type": "knowledge_package", "name": item["package_name"], "path": item["package_path"]})
    for item in skills:
        nodes.append({"id": item["skill_id"], "type": "skill_package", "name": item["skill_name"], "path": item["skill_path"]})
        if item.get("source_package_id"):
            edges.append({"from": item["source_package_id"], "to": item["skill_id"], "relationship": "generated_skill"})
    for item in agents:
        nodes.append({"id": item["agent_id"], "type": "agent_package", "name": item["agent_name"], "path": item["agent_path"]})
        if item.get("source_skill_id"):
            edges.append({"from": item["source_skill_id"], "to": item["agent_id"], "relationship": "generated_agent"})
    graph = {"nodes": nodes, "edges": edges}
    write_json(registries / "relationship_graph.json", graph)
    return graph


def _read_jsonl(path: Path) -> list[dict]:
    if not path.exists():
        return []
    return [json.loads(line) for line in path.read_text(encoding="utf-8").splitlines() if line.strip()]
