def choose_provider(registry: dict, default_provider: str = "mock_default") -> dict:
    providers = registry.get("providers", [])
    return next((item for item in providers if item.get("provider_id") == default_provider), providers[0] if providers else {"provider_type": "disabled"})
