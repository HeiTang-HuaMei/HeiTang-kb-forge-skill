def render_source_change_report(sources: list[dict]) -> str:
    return "# Workspace Source Change Report\n\n" f"- Sources scanned: {len(sources)}\n"


def render_refresh_impact_report(packages: list[dict], skills: list[dict], agents: list[dict]) -> str:
    return (
        "# Workspace Refresh Impact Report\n\n"
        f"- Impacted packages: {len(packages)}\n"
        f"- Impacted skills: {len(skills)}\n"
        f"- Impacted agents: {len(agents)}\n"
    )
