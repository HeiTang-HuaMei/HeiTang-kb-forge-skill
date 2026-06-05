def render_prompt_profile_report(registry: dict) -> str:
    rows = "\n".join(
        f"| {item.get('profile_id')} | {item.get('profile_type')} | {item.get('enabled')} |"
        for item in registry.get("profiles", [])
    ) or "| - | - | - |"
    return f"""# Prompt Profile Registry Report

| Profile | Type | Enabled |
| --- | --- | --- |
{rows}
"""
