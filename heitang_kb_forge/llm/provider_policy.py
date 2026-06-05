def default_provider_policy() -> dict:
    return {
        "default_provider": "mock",
        "allow_network": False,
        "fallback_provider": "mock",
        "require_audit_log": True,
        "redact_sensitive_input": True,
        "fail_safe": True,
    }
