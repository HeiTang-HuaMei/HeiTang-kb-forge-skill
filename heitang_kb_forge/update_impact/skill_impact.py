from pathlib import Path


def find_impacted_skills(workspace: Path, package_id: str) -> list[dict]:
    skill_paths = sorted(workspace.rglob("SKILL.md")) if workspace.exists() else []
    if not skill_paths:
        return [
            {
                "skill_id": "default_skill",
                "skill_path": "",
                "source_package_id": package_id,
                "impact_level": "medium",
                "reason": "No registered skills found; manual revalidation recommended.",
                "suggested_action": "revalidate",
            }
        ]
    return [
        {
            "skill_id": path.parent.name,
            "skill_path": str(path).replace("\\", "/"),
            "source_package_id": package_id,
            "impact_level": "medium",
            "reason": "Skill may consume the updated package.",
            "suggested_action": "revalidate",
        }
        for path in skill_paths
    ]
