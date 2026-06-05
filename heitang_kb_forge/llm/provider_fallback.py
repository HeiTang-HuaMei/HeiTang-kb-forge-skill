def fallback_provider(provider: dict, fallback: str = "mock") -> dict:
    if provider.get("provider_type") in {"mock", "local_stub"}:
        return provider
    return {"provider_id": fallback, "provider_type": fallback, "default_model": "mock-model"}
