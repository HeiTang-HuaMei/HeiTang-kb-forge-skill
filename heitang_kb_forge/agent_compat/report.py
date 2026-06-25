def render_agent_compat_report(result: dict) -> str:
    codex_harness = result.get("codex_harness", {})
    return (
        "# Agent Compatibility Check\n\n"
        f"- Status: {result.get('status')}\n"
        f"- Missing files: {', '.join(result.get('missing_files', [])) or 'None'}\n"
        f"- Codex harness status: {codex_harness.get('status', 'not_checked')}\n"
        f"- Codex harness failed checks: {', '.join(codex_harness.get('failed_checks', [])) or 'None'}\n"
        "- Note: compatibility files are local stubs and do not run external Agent platforms.\n"
    )
