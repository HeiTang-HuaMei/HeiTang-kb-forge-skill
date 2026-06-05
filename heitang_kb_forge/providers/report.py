def render_provider_registry_report(registry: dict) -> str:
    rows = "\n".join(
        f"| {item.get('provider_id')} | {item.get('provider_type')} | {item.get('health_status')} |"
        for item in registry.get("providers", [])
    ) or "| - | - | - |"
    return f"""# Provider Registry Report

| Provider | Type | Health |
| --- | --- | --- |
{rows}
"""
