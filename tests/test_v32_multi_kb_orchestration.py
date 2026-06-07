import json

import pytest

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


def test_agent_hierarchy_routes_children_and_reports_memory_policy(tmp_path):
    first = _package(tmp_path, "alpha", "Pricing policy evidence.")
    second = _package(tmp_path, "beta", "Renewal policy evidence.")
    mother = _agent(tmp_path, "mother", "mother_agent")
    alpha_child = _agent(tmp_path, "alpha-child", "kb_bound", "alpha")
    beta_child = _agent(tmp_path, "beta-child", "kb_bound", "beta")
    standalone_child = _agent(tmp_path, "standalone-child", "standalone")
    output = tmp_path / "hierarchy"

    result = orchestrate_multi_kb_agents(
        [first, second],
        output,
        [alpha_child, beta_child, standalone_child],
        "pricing policy",
        mother,
        workflow_shared_memory=True,
        parent_writeback=True,
    )

    assert result["child_agent_count"] == 3
    assert result["memory_candidate_count"] == 1
    route_map = _json(output / "multi_kb_route_map.json")
    assert route_map["agent_hierarchy"]["mother_agent"]["agent_id"] == "mother"
    assert route_map["selected_child_agent"]["agent_id"] == "alpha-child"
    graph = _json(output / "multi_agent_binding_graph.json")
    assert {"from": "mother", "to": "standalone-child", "relationship": "parent_child_binding"} in graph["edges"]
    assert {"from": "alpha-child", "to": "alpha", "relationship": "bound_to_package"} in graph["edges"]
    isolation = _json(output / "memory_isolation_report.json")
    assert isolation["child_private_memory_default"] is True
    assert isolation["workflow_shared_memory_enabled"] is True
    assert all(child["private_memory"] is True for child in isolation["children"])
    assert _json(output / "memory_writeback_report.json")["candidate_count"] == 1
    lifecycle = _json(output / "memory_lifecycle_report.json")["memory_lifecycle"]
    assert {"session_log", "short_term_memory", "summary_memory", "long_term_memory", "memory_candidates", "memory_index"}.issubset(lifecycle)
    assert lifecycle["memory_candidates"]["record_count"] == 1
    candidate = json.loads((output / "memory_candidate_queue.jsonl").read_text(encoding="utf-8").strip())
    assert candidate["target_parent"] == "mother"


def test_standalone_child_has_no_kb_and_handles_planning_tasks(tmp_path):
    package = _package(tmp_path, "alpha", "Pricing policy evidence.")
    kb_child = _agent(tmp_path, "alpha-child", "kb_bound", "alpha")
    standalone_child = _agent(tmp_path, "planner-child", "standalone")
    output = tmp_path / "planning"

    orchestrate_multi_kb_agents([package], output, [kb_child, standalone_child], "plan writing workflow")

    route_map = _json(output / "multi_kb_route_map.json")
    assert route_map["selected_child_agent"]["agent_id"] == "planner-child"
    node = [item for item in _json(output / "multi_agent_binding_graph.json")["nodes"] if item["id"] == "planner-child"][0]
    assert node["kb_binding"] == "none"
    isolation = _json(output / "memory_isolation_report.json")
    assert isolation["workflow_shared_memory_enabled"] is False


def test_unauthorized_child_kb_access_is_blocked(tmp_path):
    package = _package(tmp_path, "alpha", "Pricing policy evidence.")
    unauthorized_child = _agent(tmp_path, "beta-child", "kb_bound", "beta")
    output = tmp_path / "blocked"

    orchestrate_multi_kb_agents([package], output, [unauthorized_child], "pricing policy")

    trace = _json(output / "hierarchy_trace.json")
    assert trace["access_checks"]["blocked"] is True
    assert trace["access_checks"]["checks"][0]["blocked_kbs"] == ["beta"]
    assert not _json(output / "multi_agent_binding_graph.json")["edges"][1:]


def test_multi_kb_orchestration_requires_package_records(tmp_path):
    package = tmp_path / "empty"
    package.mkdir()
    write_json(package / "manifest.json", {"package_id": "empty"})

    with pytest.raises(ValueError):
        orchestrate_multi_kb_agents([package], tmp_path / "orchestration")


def _package(tmp_path, package_id, text):
    package = tmp_path / package_id
    package.mkdir()
    write_json(package / "manifest.json", {"package_id": package_id, "domain": "general"})
    (package / "chunks.jsonl").write_text(json.dumps({"chunk_id": "c1", "text": text}) + "\n", encoding="utf-8")
    return package


def _agent(tmp_path, agent_id, mode, source_package_id=None):
    agent = tmp_path / agent_id
    agent.mkdir()
    write_json(agent / "agent_manifest.json", {"agent_id": agent_id, "name": agent_id, "mode": mode})
    profile = f"agent_id: {agent_id}\nmode: {mode}\n"
    if source_package_id:
        profile += f"source_package_id: {source_package_id}\n"
    (agent / "agent_profile.yaml").write_text(profile, encoding="utf-8")
    return agent


def _json(path):
    return json.loads(path.read_text(encoding="utf-8"))
