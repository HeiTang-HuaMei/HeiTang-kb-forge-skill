def render_claude_code(agent_name: str) -> str:
    return f"# Claude Code Instructions\n\nUse {agent_name} outputs as local knowledge context.\n"
