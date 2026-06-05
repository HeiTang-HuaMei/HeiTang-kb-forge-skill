def render_codex_instructions(agent_name: str) -> tuple[str, str]:
    return (
        f"# Codex Instructions\n\nCall local HeiTang KB Forge outputs for {agent_name}.\n",
        "# Codex Task Plan\n\n1. Inspect package.\n2. Retrieve evidence.\n3. Answer with citations.\n",
    )
