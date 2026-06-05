import os
from datetime import datetime, timezone
from pathlib import Path

from heitang_kb_forge.exporters.jsonl_exporter import write_json
from heitang_kb_forge.llm.provider import ProviderSettings, get_provider
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


def run_live_provider_smoke(
    output: Path,
    provider: str = "mock",
    model: str = "mock-model",
    base_url_env: str | None = None,
    api_key_env: str | None = None,
    allow_network: bool = False,
) -> dict:
    output.mkdir(parents=True, exist_ok=True)
    base_url = os.environ.get(base_url_env) if base_url_env else None
    api_key = os.environ.get(api_key_env) if api_key_env else None
    warnings: list[str] = []
    status = "pass"
    error = None
    callable_status = False

    if provider in {"mock", "fake"}:
        response = get_provider(ProviderSettings(provider, model, None, None)).generate_json("live smoke", "live_smoke")
        callable_status = response.error is None
    elif not allow_network:
        status = "warning"
        warnings.append("Live network smoke is disabled. Re-run with --allow-network to opt in.")
    elif not base_url or not api_key:
        status = "fail"
        error = "Provider base URL or API key env is not configured."
    else:
        try:
            response = get_provider(ProviderSettings(provider, model, base_url, api_key)).generate_json("live smoke", "live_smoke")
            callable_status = response.error is None
            status = "pass" if callable_status else "fail"
            error = response.error
        except Exception as exc:  # pragma: no cover - external provider behavior is environment-dependent.
            status = "fail"
            error = str(exc)

    result = {
        "live_smoke_version": "2.6.0",
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "status": status,
        "provider": provider,
        "model": model,
        "allow_network": allow_network,
        "base_url_env": base_url_env,
        "base_url_configured": bool(base_url),
        "api_key_env": api_key_env,
        "api_key_present": bool(api_key),
        "api_key_leak_detected": False,
        "llm_callable": callable_status,
        "warnings": warnings,
        "error": error,
    }
    write_json(output / "llm_live_smoke_result.json", result)
    (output / "llm_live_smoke_report.md").write_text(_render_live_report(result), encoding="utf-8")
    return result


def _render_live_report(result: dict) -> str:
    return (
        "# LLM Live Smoke Report\n\n"
        f"- Status: {result['status']}\n"
        f"- Provider: {result['provider']}\n"
        f"- Model: {result['model']}\n"
        f"- Allow network: {result['allow_network']}\n"
        f"- Base URL configured: {result['base_url_configured']}\n"
        f"- API key env: {result['api_key_env'] or ''}\n"
        f"- API key present: {result['api_key_present']}\n"
        f"- LLM callable: {result['llm_callable']}\n"
        f"- Error: {result['error'] or ''}\n\n"
        "## Boundary\n\n"
        "API key values are never written to this report. Non-mock providers require explicit --allow-network.\n"
    )
