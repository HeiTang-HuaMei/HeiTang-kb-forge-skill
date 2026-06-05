def render_update_required(impacted_skills: dict, impacted_agents: dict) -> str:
    return (
        "# Update Required Report\n\n"
        f"- Impacted skills: {len(impacted_skills.get('skills', []))}\n"
        f"- Impacted agents: {len(impacted_agents.get('agents', []))}\n"
    )


def render_dependency_impact(impacted_packages: dict, impacted_skills: dict, impacted_agents: dict) -> str:
    return (
        "# Dependency Impact Report\n\n"
        f"- Packages: {len(impacted_packages.get('packages', []))}\n"
        f"- Skills: {len(impacted_skills.get('skills', []))}\n"
        f"- Agents: {len(impacted_agents.get('agents', []))}\n"
    )
