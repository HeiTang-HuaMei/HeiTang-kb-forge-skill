from heitang_kb_forge.local_agent_runtime import run_local_agent_runtime
from tests.v310_helpers import make_agent, make_package, read_json


def test_mother_routes_task_to_kb_bound_child_and_uses_authorized_evidence(tmp_path):
    package = make_package(tmp_path, "alpha", "Pricing policy evidence for local runtime.")
    mother = make_agent(tmp_path, "mother", "mother_agent")
    child = make_agent(tmp_path, "alpha-child", "kb_bound", "alpha")
    output = tmp_path / "runtime"

    status = run_local_agent_runtime([package], output, [child], "pricing policy", mother)

    assert status["status"] == "pass"
    session = read_json(output / "local_agent_runtime_session.json")
    assert session["mother_agent"] == "mother"
    assert session["selected_child_agent"] == "alpha-child"
    assert session["evidence"][0]["package_id"] == "alpha"
    assert session["llm_used"] is False
    assert session["network_used"] is False
    access = read_json(output / "child_kb_access_report.json")
    assert access["authorized"] is True


def test_unauthorized_child_kb_access_is_blocked_at_runtime(tmp_path):
    package = make_package(tmp_path, "alpha")
    child = make_agent(tmp_path, "beta-child", "kb_bound", "beta")
    output = tmp_path / "runtime"

    run_local_agent_runtime([package], output, [child], "pricing policy")

    assert read_json(output / "local_agent_runtime_status.json")["status"] == "blocked"
    access = read_json(output / "child_kb_access_report.json")
    assert access["blocked_kbs"] == ["beta"]
    assert read_json(output / "local_agent_runtime_session.json")["response"]["status"] == "refused"


def test_standalone_child_runs_without_kb_binding_for_planning_task(tmp_path):
    package = make_package(tmp_path, "alpha")
    kb_child = make_agent(tmp_path, "alpha-child", "kb_bound", "alpha")
    standalone = make_agent(tmp_path, "planner-child", "standalone")
    output = tmp_path / "runtime"

    run_local_agent_runtime([package], output, [kb_child, standalone], "plan writing workflow")

    session = read_json(output / "local_agent_runtime_session.json")
    assert session["selected_child_agent"] == "planner-child"
    assert session["evidence"] == []
    assert read_json(output / "child_kb_access_report.json")["allowed_kbs"] == []


def test_private_memory_default_shared_memory_explicit_and_writeback_candidate(tmp_path):
    package = make_package(tmp_path, "alpha")
    child = make_agent(tmp_path, "alpha-child", "kb_bound", "alpha")
    output = tmp_path / "runtime"

    run_local_agent_runtime([package], output, [child], "pricing policy", workflow_shared_memory=True, parent_writeback=True)

    isolation = read_json(output / "child_memory_isolation_report.json")
    assert isolation["child_private_memory_default"] is True
    assert isolation["children"][0]["private_memory"] is True
    shared = read_json(output / "workflow_shared_memory_report.json")
    assert shared["enabled"] is True
    writeback = read_json(output / "parent_memory_writeback_actions.json")
    assert writeback["enabled"] is True
    assert writeback["actions"][0]["action"] == "review_memory_candidate"
