import json

from heitang_kb_forge.exporters.jsonl_exporter import write_json
from heitang_kb_forge.multi_kb_orchestration import orchestrate_multi_kb_agents


def test_multi_kb_orchestration_writes_routes_conflicts_and_graph(tmp_path):
    first = _package(tmp_path, "alpha", "Pricing policy evidence.")
    second = _package(tmp_path, "beta", "Pricing renewal evidence.")
    agent = tmp_path / "agent"
    agent.mkdir()
    (agent / "agent_profile.yaml").write_text("agent_id: agent-alpha\nsource_package_id: alpha\n", encoding="utf-8")
    output = tmp_path / "orchestration"

    result = orchestrate_multi_kb_agents([first, second], output, [agent], "pricing")

    assert result["status"] == "pass"
    assert result["package_count"] == 2
    assert _json(output / "multi_kb_route_map.json")["routes"][0]["route_score"] >= 1
    assert _json(output / "multi_agent_binding_graph.json")["edges"][0]["relationship"] == "bound_to_package"
    assert _json(output / "multi_kb_conflict_report.json")["status"] == "warning"
    assert (output / "multi_kb_orchestration_report.md").exists()


def _package(tmp_path, package_id, text):
    package = tmp_path / package_id
    package.mkdir()
    write_json(package / "manifest.json", {"package_id": package_id, "domain": "general"})
    (package / "chunks.jsonl").write_text(json.dumps({"chunk_id": "c1", "text": text}) + "\n", encoding="utf-8")
    return package


def _json(path):
    return json.loads(path.read_text(encoding="utf-8"))
