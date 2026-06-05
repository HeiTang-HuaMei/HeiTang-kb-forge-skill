def check_provider(record: dict) -> dict:
    status = "pass" if record.get("provider_type") == "mock" else "warning"
    reason = "mock provider is available offline" if status == "pass" else "network provider requires external configuration"
    checked = dict(record)
    checked["health_status"] = status
    checked["health_reason"] = reason
    return checked
