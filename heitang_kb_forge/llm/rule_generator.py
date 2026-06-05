def generation_mode(llm_enabled: bool, provider: str, fallback: bool) -> str:
    if not llm_enabled:
        return "rule_template"
    if fallback:
        return "hybrid"
    if provider == "mock":
        return "llm_assisted"
    return "hybrid"
