import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
MOCK_DATA = ROOT / "examples" / "ui_mock_data"


def read_json(name):
    return json.loads((MOCK_DATA / name).read_text(encoding="utf-8"))


def test_required_mock_data_files_exist_and_are_json():
    for file_name in [
        "knowledge_bases.json",
        "agents.json",
        "workflows.json",
        "memory_scopes.json",
        "jobs.json",
        "review_queue.json",
        "generated_docs.json",
        "provider_status.json",
        "parser_backend_status.json",
        "answer_policies.json",
        "p1_core_contract_fixture.json",
    ]:
        assert (MOCK_DATA / file_name).exists()
        assert isinstance(read_json(file_name), dict)


def test_mock_data_represents_knowledge_bases_agents_and_bindings():
    knowledge_bases = read_json("knowledge_bases.json")["knowledge_bases"]
    agents = read_json("agents.json")["agents"]
    kb_ids = {kb["id"] for kb in knowledge_bases}
    agent_ids = {agent["id"] for agent in agents}

    assert len(knowledge_bases) >= 2
    assert {"draft", "trusted"} <= {kb["status"] for kb in knowledge_bases}
    assert len(agents) >= 2

    for kb in knowledge_bases:
        assert kb["bound_agents"]
        assert set(kb["bound_agents"]) <= agent_ids

    for agent in agents:
        assert agent["bound_kbs"]
        assert set(agent["bound_kbs"]) <= kb_ids
        assert agent["private_memory_scope"].startswith("mem-agent-")


def test_mock_data_represents_providers_policies_and_parser_status():
    providers = read_json("provider_status.json")["providers"]
    parser_backends = read_json("parser_backend_status.json")["parser_backends"]
    policies = read_json("answer_policies.json")

    assert len(providers) >= 3
    assert {"available", "degraded", "offline"} <= {provider["status"] for provider in providers}
    assert len(parser_backends) >= 3
    assert {"available", "degraded"} <= {backend["status"] for backend in parser_backends}
    assert {"grounded_only", "cite_or_abstain", "needs_review"} <= {
        policy["id"] for policy in policies["answer_policies"]
    }
    assert policies["memory_policies"]


def test_mock_data_represents_p1_core_contract_alignment_fixture():
    fixture = read_json("p1_core_contract_fixture.json")

    assert fixture["source"]["core_commit"] == "a793247ff8704275891ff9a1aefcb78888bcc9f2"
    assert fixture["not_full_operation_yet"] is True
    assert fixture["not_v4_0_workbench_rc"] is True
    assert fixture["counts"]["actions"] == 110
    assert fixture["counts"]["reports"] == 109
    assert fixture["counts"]["artifacts"] == 101
    assert fixture["counts"]["errors"] == 20
    assert fixture["counts"]["templates"] == 6


def test_mock_data_represents_review_generated_docs_workflow_and_exports():
    review_items = read_json("review_queue.json")["review_items"]
    docs = read_json("generated_docs.json")
    workflows = read_json("workflows.json")["workflows"]

    assert {"high", "medium", "low"} <= {item["risk"] for item in review_items}
    assert all(item["corrected_text"] for item in review_items)
    assert docs["generated_docs"]
    assert docs["export_items"]
    assert workflows

    for workflow in workflows:
        assert workflow["shared_memory_scope"].startswith("mem-workflow-")
        assert workflow["steps"]
        assert workflow["handoff_trace"]


def test_mock_data_represents_memory_isolation():
    memory_scopes = read_json("memory_scopes.json")["memory_scopes"]
    scope_types = {scope["type"] for scope in memory_scopes}
    isolations = {scope["isolation"] for scope in memory_scopes}

    assert {"agent_private", "workflow_shared"} <= scope_types
    assert "private" in isolations
    assert "shared_with_workflow_agents" in isolations
