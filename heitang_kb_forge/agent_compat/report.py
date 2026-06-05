def render_agent_compat_report(result: dict) -> str:
    return (
        "# Agent Compatibility Check\n\n"
        f"- Status: {result.get('status')}\n"
        f"- Missing files: {', '.join(result.get('missing_files', [])) or 'None'}\n"
        "- Note: compatibility files are local stubs and do not run external Agent platforms.\n"
    )
