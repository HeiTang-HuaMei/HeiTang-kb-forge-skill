from heitang_kb_forge.skill.generator import generate_skill_package
from heitang_kb_forge.agent_package.generator import generate_agent_package
from heitang_kb_forge.workspace.initializer import init_portable_workspace
from heitang_kb_forge.workspace.v19_registry import register_workspace_asset
from tests.v17_helpers import read_json, write_sample_package


def test_relationship_graph_links_package_skill_agent(tmp_path):
    workspace = tmp_path / "workspace"
    package = write_sample_package(tmp_path / "package")
    skill = tmp_path / "skill"
    agent = tmp_path / "agent"
    init_portable_workspace(workspace)
    generate_skill_package(package, skill, "Demo Skill")
    generate_agent_package(package, skill, agent, "Demo Agent")

    register_workspace_asset(workspace, package, "knowledge")
    register_workspace_asset(workspace, skill, "skill")
    register_workspace_asset(workspace, agent, "agent")

    graph = read_json(workspace / "registries" / "relationship_graph.json")
    assert len(graph["nodes"]) == 3
    assert any(edge["relationship"] == "generated_agent" for edge in graph["edges"])
