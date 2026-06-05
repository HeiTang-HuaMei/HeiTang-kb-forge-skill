def sanitize_provider_config(provider_id: str, provider_type: str, model: str, api_key_env: str | None = None) -> dict:
    return {
        "provider_id": provider_id,
        "provider_type": provider_type,
        "display_name": provider_id,
        "base_url": None,
        "default_model": model,
        "api_key_env": api_key_env,
        "enabled": provider_type == "mock",
        "network_required": provider_type != "mock",
        "health_status": "not_checked",
    }
