from pathlib import Path


def impacted_workspace_assets(workspace: Path) -> tuple[list[dict], list[dict], list[dict]]:
    packages = [{"package_id": path.parent.name, "package_path": str(path.parent).replace("\\", "/"), "suggested_action": "revalidate"} for path in sorted(workspace.rglob("manifest.json"))]
    skills = [{"skill_id": path.parent.name, "skill_path": str(path).replace("\\", "/"), "suggested_action": "revalidate"} for path in sorted(workspace.rglob("SKILL.md"))]
    agents = [{"agent_id": path.parent.name, "agent_path": str(path).replace("\\", "/"), "suggested_action": "revalidate"} for path in sorted(workspace.rglob("agent_profile.yaml"))]
    return packages, skills, agents
