from pathlib import Path


def find_impacted_agents(workspace: Path, impacted_skills: list[dict]) -> list[dict]:
    agent_paths = sorted(workspace.rglob("agent_profile.yaml")) if workspace.exists() else []
    if not agent_paths:
        return [
            {
                "agent_id": "default_agent",
                "agent_path": "",
                "source_skill_id": impacted_skills[0]["skill_id"] if impacted_skills else "",
                "impact_level": "medium",
                "reason": "No registered agents found; manual revalidation recommended.",
                "suggested_action": "revalidate",
            }
        ]
    source_skill = impacted_skills[0]["skill_id"] if impacted_skills else ""
    return [
        {
            "agent_id": path.parent.name,
            "agent_path": str(path).replace("\\", "/"),
            "source_skill_id": source_skill,
            "impact_level": "medium",
            "reason": "Agent may depend on an impacted skill.",
            "suggested_action": "revalidate",
        }
        for path in agent_paths
    ]
