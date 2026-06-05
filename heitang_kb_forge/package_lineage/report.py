from .dependency import dependency_count


def render_lineage_report(graph: dict) -> str:
    return (
        "# Package Lineage Report\n\n"
        f"- Packages: {len(graph.get('nodes', []))}\n"
        f"- Relationships: {len(graph.get('edges', []))}\n"
    )


def render_dependency_report(graph: dict) -> str:
    return "# Package Dependency Report\n\n" f"- Dependency edges: {dependency_count(graph)}\n"
