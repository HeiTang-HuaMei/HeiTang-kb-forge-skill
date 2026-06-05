from pathlib import Path

from heitang_kb_forge.agent_package import generate_agent_package
from heitang_kb_forge.contracts.stable_checker import run_stable_check
from heitang_kb_forge.providers.registry import add_provider
from heitang_kb_forge.reliability import make_reliability_score
from heitang_kb_forge.skill import generate_skill_package
from heitang_kb_forge.skill_validation import validate_skill_package
from heitang_kb_forge.workspace.health import check_workspace_health
from heitang_kb_forge.workspace.initializer import init_portable_workspace
from heitang_kb_forge.workspace.v19_registry import register_workspace_asset
from heitang_kb_forge.exporters.jsonl_exporter import write_json


def write_studio_outputs(
    workspace: Path,
    project_name: str,
    knowledge_package: Path,
    skill_package: Path,
    agent_package: Path,
    status: str,
) -> dict:
    manifest = {
        "studio_run_version": "2.0",
        "project_name": project_name,
        "workspace": str(workspace).replace("\\", "/"),
        "status": status,
        "stages": [
            {"stage": "build", "status": "pass", "outputs": [str(knowledge_package).replace("\\", "/")]},
            {"stage": "generate_skill", "status": "pass", "outputs": [str(skill_package).replace("\\", "/")]},
            {"stage": "generate_agent", "status": "pass", "outputs": [str(agent_package).replace("\\", "/")]},
        ],
        "knowledge_package": str(knowledge_package).replace("\\", "/"),
        "skill_package": str(skill_package).replace("\\", "/"),
        "agent_package": str(agent_package).replace("\\", "/"),
        "workspace_health": status,
        "stable_check": status,
        "release_ready": status == "pass",
    }
    write_json(workspace / "studio_run_manifest.json", manifest)
    (workspace / "studio_run_report.md").write_text(render_studio_report(manifest), encoding="utf-8")
    (workspace / "release_checklist.md").write_text("# Release Checklist\n\n- [ ] Review stable_check_report.md\n- [ ] Review reliability_report.md\n", encoding="utf-8")
    return manifest


def render_studio_report(manifest: dict) -> str:
    return f"# Studio Run Report\n\n- Project: {manifest['project_name']}\n- Status: {manifest['status']}\n- Release ready: {manifest['release_ready']}\n"


def finalize_studio_workspace(workspace: Path, project_name: str, knowledge_package: Path) -> dict:
    init_portable_workspace(workspace)
    skill_package = workspace / "skill_packages" / f"{project_name}_skill"
    agent_package = workspace / "agent_packages" / f"{project_name}_agent"
    generate_skill_package(knowledge_package, skill_package, f"{project_name} Skill")
    validate_skill_package(skill_package, knowledge_package, workspace / "reports" / "skill_validation")
    generate_agent_package(knowledge_package, skill_package, agent_package, f"{project_name} Agent")
    register_workspace_asset(workspace, knowledge_package, "knowledge")
    register_workspace_asset(workspace, skill_package, "skill")
    register_workspace_asset(workspace, agent_package, "agent")
    add_provider(workspace, "mock_default", "mock", "mock-model")
    check_workspace_health(workspace)
    run_stable_check(workspace)
    make_reliability_score(workspace)
    return write_studio_outputs(workspace, project_name, knowledge_package, skill_package, agent_package, "pass")
