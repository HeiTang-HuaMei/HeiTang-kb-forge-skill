import os

from heitang_kb_forge.schemas.live_smoke_schema import LiveProviderSmokeReport


def make_live_provider_smoke_report() -> LiveProviderSmokeReport:
    llm_key = os.environ.get("HEITANG_LLM_API_KEY")
    llm_base_url = os.environ.get("HEITANG_LLM_BASE_URL")
    llm_model = os.environ.get("HEITANG_LLM_MODEL")
    embedding_key = os.environ.get("HEITANG_EMBEDDING_API_KEY")
    embedding_base_url = os.environ.get("HEITANG_EMBEDDING_BASE_URL")
    embedding_model = os.environ.get("HEITANG_EMBEDDING_MODEL")

    warnings: list[str] = []
    llm_configured = bool(llm_key and llm_base_url and llm_model)
    embedding_configured = bool(embedding_key and embedding_base_url and embedding_model)
    if not llm_configured:
        warnings.append("LLM live provider environment variables are incomplete.")
    if not embedding_configured:
        warnings.append("Embedding live provider environment variables are incomplete.")

    return LiveProviderSmokeReport(
        llm_provider_configured=llm_configured,
        embedding_provider_configured=embedding_configured,
        llm_callable=False,
        embedding_callable=False,
        warnings=warnings,
    )


def should_run_live_tests() -> bool:
    return os.environ.get("HEITANG_RUN_LIVE_TESTS") == "1"
