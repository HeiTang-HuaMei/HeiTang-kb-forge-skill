def render_mcp() -> tuple[dict, dict, dict]:
    return (
        {"resources": []},
        {"tools": [{"name": "retrieve_knowledge", "mode": "stub"}]},
        {"mcp_version": "stub", "server": "not_started"},
    )
