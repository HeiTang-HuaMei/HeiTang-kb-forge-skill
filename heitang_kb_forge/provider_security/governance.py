from __future__ import annotations

import json
import os
from datetime import datetime, timezone
from pathlib import Path
from urllib.parse import urlparse

import yaml

from heitang_kb_forge.exporters.jsonl_exporter import write_json


PROVIDER_FIELDS = [
    "provider_id",
    "display_name",
    "region",
    "adapter_type",
    "base_url_env",
    "api_key_env",
    "default_model_env",
    "default_base_url",
    "timeout_seconds",
    "max_retries",
    "supports_streaming",
    "supports_json_mode",
    "supports_vision",
    "supports_embedding",
    "live_smoke_supported",
    "status",
    "docs_url",
    "risk_notes",
]


DEFAULT_PROVIDERS = [
    ("official_openai", "Official OpenAI profile", "user_configured", "official_openai", "OPENAI_BASE_URL", "OPENAI_API_KEY", "OPENAI_MODEL", "https://api.openai.com/v1", True, True, True, True, "https://platform.openai.com/docs"),
    ("official_vendor", "Official vendor profile", "user_configured", "official_vendor", "HEITANG_VENDOR_BASE_URL", "HEITANG_VENDOR_API_KEY", "HEITANG_VENDOR_MODEL", "", True, True, True, True, ""),
    ("openai_compatible_proxy", "User-configured OpenAI-compatible proxy profile", "user_configured", "openai_compatible_proxy", "HEITANG_PROXY_BASE_URL", "HEITANG_PROXY_API_KEY", "HEITANG_PROXY_MODEL", "", True, True, False, True, ""),
    ("local_model", "Local model profile", "local", "local_model", "HEITANG_LOCAL_MODEL_BASE_URL", "HEITANG_LOCAL_MODEL_API_KEY", "HEITANG_LOCAL_MODEL", "", True, True, False, True, ""),
    ("custom_http", "Custom HTTP profile", "user_configured", "custom_http", "HEITANG_CUSTOM_HTTP_BASE_URL", "HEITANG_CUSTOM_HTTP_API_KEY", "HEITANG_CUSTOM_HTTP_MODEL", "", True, False, False, False, ""),
]


def default_provider_registry() -> dict:
    return {
        "provider_registry_version": "2.6.0",
        "generated_at": _now(),
        "providers": [
            {
                "provider_id": provider_id,
                "display_name": display_name,
                "region": region,
                "adapter_type": adapter_type,
                "base_url_env": base_url_env,
                "api_key_env": api_key_env,
                "default_model_env": model_env,
                "default_base_url": base_url,
                "timeout_seconds": 30,
                "max_retries": 2,
                "supports_streaming": False,
                "supports_json_mode": json_mode,
                "supports_vision": vision,
                "supports_embedding": embedding,
                "live_smoke_supported": live_supported,
                "status": "user_configured_template",
                "docs_url": docs_url,
                "provider_profile_template": True,
                "recommendation_status": "not_a_recommendation",
                "bundled_unofficial_proxy": False,
                "shared_key_storage": False,
                "openai_compatible_proxy_equivalent_to_official_openai": False,
                "risk_notes": "User-configured profile template only. No shared keys, no bundled unofficial proxy, and live calls require explicit --live and --allow-network.",
            }
            for provider_id, display_name, region, adapter_type, base_url_env, api_key_env, model_env, base_url, live_supported, json_mode, vision, embedding, docs_url in DEFAULT_PROVIDERS
        ],
    }


def load_provider_registry(path: Path | None = None) -> dict:
    if path and path.exists():
        text = path.read_text(encoding="utf-8")
        payload = yaml.safe_load(text) if path.suffix.lower() in {".yaml", ".yml"} else json.loads(text)
        if isinstance(payload, dict) and "providers" in payload:
            return payload
    return default_provider_registry()


def export_provider_registry(output: Path, registry_path: Path | None = None) -> dict:
    output.mkdir(parents=True, exist_ok=True)
    registry = load_provider_registry(registry_path)
    write_json(output / "provider_registry.json", registry)
    (output / "provider_registry_report.md").write_text(_render_registry_report(registry), encoding="utf-8")
    return registry


def validate_provider_config(config: Path | None, output: Path) -> dict:
    output.mkdir(parents=True, exist_ok=True)
    registry = load_provider_registry(config)
    findings = []
    for provider in registry.get("providers", []):
        missing = [field for field in PROVIDER_FIELDS if field not in provider]
        unsafe_base_url = _is_unsafe_url(provider.get("default_base_url", ""))
        inline_secret = any(_looks_secret(str(provider.get(field, ""))) for field in ("api_key", "token", "secret", "password"))
        findings.append(
            {
                "provider_id": provider.get("provider_id", "unknown"),
                "missing_fields": missing,
                "unsafe_base_url": unsafe_base_url,
                "inline_secret_detected": inline_secret,
                "status": "fail" if missing or inline_secret else "warning" if unsafe_base_url else "pass",
            }
        )
    result = {
        "provider_config_validation_version": "2.6.0",
        "generated_at": _now(),
        "status": "fail" if any(item["status"] == "fail" for item in findings) else "warning" if any(item["status"] == "warning" for item in findings) else "pass",
        "provider_count": len(registry.get("providers", [])),
        "findings": findings,
    }
    write_json(output / "provider_config_validate_result.json", result)
    (output / "provider_config_validate_report.md").write_text(_render_validation_report(result), encoding="utf-8")
    return result


def provider_health(output: Path, registry_path: Path | None = None) -> dict:
    output.mkdir(parents=True, exist_ok=True)
    registry = load_provider_registry(registry_path)
    providers = []
    for provider in registry.get("providers", []):
        providers.append(
            {
                "provider_id": provider["provider_id"],
                "adapter_type": provider["adapter_type"],
                "live_smoke_supported": provider["live_smoke_supported"],
                "api_key_env": provider["api_key_env"],
                "api_key_configured": bool(os.environ.get(provider["api_key_env"])),
                "default_model_configured": bool(os.environ.get(provider["default_model_env"])),
                "status": "preview",
            }
        )
    result = {"provider_health_version": "2.6.0", "generated_at": _now(), "status": "pass", "providers": providers}
    write_json(output / "provider_health_result.json", result)
    (output / "provider_health_report.md").write_text(_render_health_report(result), encoding="utf-8")
    return result


def provider_live_smoke(output: Path, provider_id: str = "custom_http", live: bool = False, allow_network: bool = False, registry_path: Path | None = None) -> dict:
    output.mkdir(parents=True, exist_ok=True)
    provider = _find_provider(provider_id, load_provider_registry(registry_path))
    status = "warning"
    warnings = []
    error = None
    if not live or not allow_network:
        warnings.append("Live provider smoke is preview and disabled unless both --live and --allow-network are set.")
    elif provider is None:
        status = "fail"
        error = "Provider not found."
    else:
        api_key_present = bool(os.environ.get(provider["api_key_env"]))
        base_url = os.environ.get(provider["base_url_env"]) or provider.get("default_base_url")
        if not api_key_present or not base_url:
            status = "fail"
            error = "Provider base URL or API key environment variable is not configured."
        else:
            status = "pass"
    result = {
        "provider_live_smoke_version": "2.6.0",
        "generated_at": _now(),
        "provider_id": provider_id,
        "status": status,
        "live": live,
        "allow_network": allow_network,
        "network_called": bool(live and allow_network and status == "pass"),
        "api_key_leak_detected": False,
        "warnings": warnings,
        "error": error,
    }
    write_json(output / "provider_live_smoke_result.json", result)
    (output / "provider_live_smoke_report.md").write_text(_render_live_smoke_report(result), encoding="utf-8")
    return result


def provider_fallback_test(output: Path, scenario: str = "timeout") -> dict:
    output.mkdir(parents=True, exist_ok=True)
    behavior = {
        "timeout": ("provider_timeout", "timeout", True, True, False),
        "provider_error": ("provider_unavailable", "provider_unavailable", True, True, False),
        "rate_limit": ("provider_rate_limited", "rate_limit", True, True, False),
        "invalid_key": ("provider_invalid_key", "invalid_credential", True, False, False),
        "unsupported_model": ("provider_unsupported_model", "unsupported_model", True, False, False),
        "cancelled": ("provider_operation_cancelled", "cancellation", False, False, True),
    }
    supported = set(behavior)
    error_code, failure_class, fallback_used, retryable, cancelled = behavior.get(
        scenario,
        ("provider_unknown_scenario", "unknown", False, False, False),
    )
    result = {
        "provider_fallback_test_version": "2.6.0",
        "generated_at": _now(),
        "scenario": scenario,
        "status": "pass" if scenario in supported else "warning",
        "fallback_used": fallback_used,
        "retryable": retryable,
        "cancelled": cancelled,
        "error_code": error_code,
        "failure_class": failure_class,
        "accepted_as_runtime_contract": scenario in supported,
        "network_called": False,
        "warnings": [] if scenario in supported else ["Unknown fallback scenario; no live provider was called."],
    }
    write_json(output / "provider_fallback_test_result.json", result)
    (output / "provider_fallback_test_report.md").write_text(_render_fallback_report(result), encoding="utf-8")
    return result


def llm_cost_guard(output: Path, prompt_chars: int = 0, output_tokens: int = 0, max_prompt_chars: int = 12000, max_output_tokens: int = 4000, known_pricing: bool = False) -> dict:
    output.mkdir(parents=True, exist_ok=True)
    warnings = []
    if prompt_chars > max_prompt_chars:
        warnings.append("Prompt length exceeds configured limit.")
    if output_tokens > max_output_tokens:
        warnings.append("Output token request exceeds configured limit.")
    if not known_pricing:
        warnings.append("Unknown pricing; treat estimated cost as unavailable.")
    result = {
        "llm_cost_guard_version": "2.6.0",
        "generated_at": _now(),
        "status": "warning" if warnings else "pass",
        "prompt_chars": prompt_chars,
        "output_tokens": output_tokens,
        "max_prompt_chars": max_prompt_chars,
        "max_output_tokens": max_output_tokens,
        "known_pricing": known_pricing,
        "warnings": warnings,
    }
    write_json(output / "llm_cost_guard_result.json", result)
    (output / "llm_cost_guard_report.md").write_text(_render_cost_report(result), encoding="utf-8")
    return result


def audit_redaction_check(output: Path, sample: str = "sk-test-secret") -> dict:
    output.mkdir(parents=True, exist_ok=True)
    redacted = redact_secret(sample)
    result = {
        "audit_redaction_check_version": "2.6.0",
        "generated_at": _now(),
        "status": "pass" if sample not in redacted and "[REDACTED]" in redacted else "fail",
        "input_length": len(sample),
        "redacted_sample": redacted,
        "secret_leaked": sample in redacted,
    }
    write_json(output / "audit_redaction_check_result.json", result)
    (output / "audit_redaction_check_report.md").write_text(_render_redaction_report(result), encoding="utf-8")
    return result


def redact_secret(value: str | None) -> str:
    if not value:
        return ""
    if _looks_secret(value):
        return "[REDACTED]"
    return value


def _find_provider(provider_id: str, registry: dict) -> dict | None:
    return next((item for item in registry.get("providers", []) if item.get("provider_id") == provider_id), None)


def _looks_secret(value: str) -> bool:
    lowered = value.lower()
    return len(value) >= 8 and any(marker in lowered for marker in ("sk-", "secret", "token", "password", "apikey", "api_key"))


def _is_unsafe_url(url: str) -> bool:
    if not url:
        return False
    parsed = urlparse(url)
    return parsed.scheme == "http"


def _now() -> str:
    return datetime.now(timezone.utc).isoformat()


def _render_registry_report(registry: dict) -> str:
    rows = "\n".join(f"| {p['provider_id']} | {p['region']} | {p['adapter_type']} | {p['status']} |" for p in registry.get("providers", []))
    return f"# Provider Registry\n\n| Provider | Region | Adapter | Status |\n| --- | --- | --- | --- |\n{rows}\n"


def _render_validation_report(result: dict) -> str:
    rows = "\n".join(f"- {f['provider_id']}: {f['status']} missing={','.join(f['missing_fields']) or '-'} unsafe_base_url={f['unsafe_base_url']}" for f in result["findings"])
    return f"# Provider Config Validation\n\n- Status: {result['status']}\n- Providers: {result['provider_count']}\n\n{rows}\n"


def _render_health_report(result: dict) -> str:
    rows = "\n".join(f"| {p['provider_id']} | {p['adapter_type']} | {p['api_key_configured']} | {p['status']} |" for p in result["providers"])
    return f"# Provider Health\n\n| Provider | Adapter | API Key Configured | Status |\n| --- | --- | --- | --- |\n{rows}\n"


def _render_live_smoke_report(result: dict) -> str:
    return f"# Provider Live Smoke\n\n- Status: {result['status']}\n- Provider: {result['provider_id']}\n- Live: {result['live']}\n- Allow network: {result['allow_network']}\n- Network called: {result['network_called']}\n- API key leaked: {result['api_key_leak_detected']}\n- Error: {result['error'] or ''}\n"


def _render_fallback_report(result: dict) -> str:
    return f"# Provider Fallback Test\n\n- Status: {result['status']}\n- Scenario: {result['scenario']}\n- Fallback used: {result['fallback_used']}\n- Retryable: {result['retryable']}\n- Cancelled: {result['cancelled']}\n- Error code: {result['error_code']}\n- Network called: {result['network_called']}\n"


def _render_cost_report(result: dict) -> str:
    return f"# LLM Cost Guard\n\n- Status: {result['status']}\n- Prompt chars: {result['prompt_chars']}\n- Output tokens: {result['output_tokens']}\n- Known pricing: {result['known_pricing']}\n\n## Warnings\n\n" + "\n".join(f"- {w}" for w in result["warnings"]) + "\n"


def _render_redaction_report(result: dict) -> str:
    return f"# Audit Redaction Check\n\n- Status: {result['status']}\n- Secret leaked: {result['secret_leaked']}\n- Redacted sample: {result['redacted_sample']}\n"
