def dependency_count(graph: dict) -> int:
    return len(graph.get("edges", []))
