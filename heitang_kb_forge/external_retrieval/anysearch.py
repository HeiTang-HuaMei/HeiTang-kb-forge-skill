from __future__ import annotations

import json
import os
import re
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Callable
from urllib.error import HTTPError, URLError
from urllib.parse import urlparse
from urllib.request import ProxyHandler, Request, build_opener

from heitang_kb_forge.exporters.jsonl_exporter import write_json


ANYSEARCH_OUTPUT_FILES = {
    "check": "anysearch_provider_check.json",
    "smoke": "anysearch_provider_smoke.json",
    "run": "anysearch_retrieval_result.json",
    "source_trace": "source_trace.json",
}

Transport = Callable[[str, dict[str, str], dict[str, Any], int, str | None], dict[str, Any]]


@dataclass(frozen=True)
class AnySearchConfig:
    enabled: bool = True
    base_url: str = "https://api.anysearch.com"
    reverse_proxy_url: str | None = None
    proxy_url: str | None = None
    api_key_env: str = "ANYSEARCH_API_KEY"
    timeout_seconds: int = 30

    @classmethod
    def load(cls, path: Path | None = None) -> tuple[AnySearchConfig, list[str]]:
        if path is None:
            return cls(), []
        payload = json.loads(Path(path).read_text(encoding="utf-8"))
        if not isinstance(payload, dict):
            raise ValueError("AnySearch config must be a JSON object.")
        errors = []
        for secret_field in ("api_key", "token", "secret", "password"):
            if payload.get(secret_field):
                errors.append(f"inline_secret_not_allowed:{secret_field}")
        allowed = {
            "enabled",
            "base_url",
            "reverse_proxy_url",
            "proxy_url",
            "api_key_env",
            "timeout_seconds",
        }
        unknown = sorted(set(payload) - allowed - {"api_key", "token", "secret", "password"})
        errors.extend(f"unknown_config_field:{field}" for field in unknown)
        return (
            cls(
                enabled=bool(payload.get("enabled", True)),
                base_url=str(payload.get("base_url") or cls.base_url),
                reverse_proxy_url=_optional_text(payload.get("reverse_proxy_url")),
                proxy_url=_optional_text(payload.get("proxy_url")),
                api_key_env=str(payload.get("api_key_env") or cls.api_key_env),
                timeout_seconds=int(payload.get("timeout_seconds", cls.timeout_seconds)),
            ),
            errors,
        )

    @property
    def endpoint(self) -> str:
        base = (self.reverse_proxy_url or self.base_url).rstrip("/")
        return base if base.endswith("/mcp") else f"{base}/mcp"

    @property
    def api_key(self) -> str | None:
        return os.environ.get(self.api_key_env) or None


def check_anysearch_provider(output: Path, config_path: Path | None = None) -> dict[str, Any]:
    config, load_errors = AnySearchConfig.load(config_path)
    validation_errors = load_errors + _validate_config(config)
    if validation_errors:
        status = "failed"
        runtime_status = "invalid_config"
    elif not config.enabled:
        status = "passed"
        runtime_status = "disabled"
    elif config.api_key:
        status = "passed"
        runtime_status = "configured"
    else:
        status = "passed"
        runtime_status = "available_anonymous"
    result = {
        "schema_version": "anysearch_provider_check.v1",
        "provider_id": "anysearchskill",
        "integration_mode": "provider_adapter",
        "status": status,
        "runtime_status": runtime_status,
        "smoke_status": "not_run",
        "enabled": config.enabled,
        "network_required": True,
        "external_runtime_required": False,
        "api_key_optional": True,
        "api_key_configured": bool(config.api_key),
        "api_key_env": config.api_key_env,
        "base_url": _safe_url(config.base_url),
        "reverse_proxy_configured": bool(config.reverse_proxy_url),
        "reverse_proxy_url": _safe_url(config.reverse_proxy_url),
        "proxy_configured": bool(config.proxy_url),
        "proxy_url": _safe_url(config.proxy_url),
        "timeout_seconds": config.timeout_seconds,
        "secrets_persisted": False,
        "validation_errors": validation_errors,
        "repair_suggestion": _repair_suggestion(validation_errors, config),
        "final_target_not_downgraded": True,
        "remaining_gap": "The provider check does not prove a live request, full External Source Center UI, Core Bridge execution, complete API/proxy configuration, Full Gate, EXE, or release readiness.",
        "next_required_e2e_step": "Run the controlled AnySearch provider smoke and record source-trace evidence for Section 5 item 5.3.",
        "not_goal_complete": True,
    }
    output = Path(output)
    output.mkdir(parents=True, exist_ok=True)
    write_json(output / ANYSEARCH_OUTPUT_FILES["check"], result)
    return result


def smoke_anysearch_provider(
    output: Path,
    *,
    config_path: Path | None = None,
    allow_network: bool = False,
    query: str = "document understanding knowledge base",
    transport: Transport | None = None,
) -> dict[str, Any]:
    return run_anysearch_retrieval(
        output,
        query=query,
        max_results=3,
        config_path=config_path,
        allow_network=allow_network,
        transport=transport,
        report_kind="smoke",
    )


def run_anysearch_retrieval(
    output: Path,
    *,
    query: str,
    max_results: int = 5,
    config_path: Path | None = None,
    allow_network: bool = False,
    transport: Transport | None = None,
    report_kind: str = "run",
) -> dict[str, Any]:
    config, load_errors = AnySearchConfig.load(config_path)
    validation_errors = load_errors + _validate_config(config)
    result = _base_result(config, query, max_results, report_kind, allow_network)
    if validation_errors:
        result.update(
            status="failed",
            runtime_status="invalid_config",
            smoke_status="failed" if report_kind == "smoke" else "not_run",
            error_code="invalid_config",
            error="; ".join(validation_errors),
            repair_suggestion="Fix the reported configuration fields and retry.",
        )
    elif not config.enabled:
        result.update(
            status="skipped",
            runtime_status="disabled",
            smoke_status="skipped_disabled" if report_kind == "smoke" else "not_run",
            error_code=None,
            error=None,
            repair_suggestion="Enable the provider before requesting network retrieval.",
        )
    elif not allow_network:
        result.update(
            status="skipped",
            runtime_status="available_anonymous" if not config.api_key else "configured",
            smoke_status="skipped_network_not_allowed" if report_kind == "smoke" else "not_run",
            error_code=None,
            error=None,
            repair_suggestion="Retry with explicit --allow-network after reviewing the provider endpoint and proxy settings.",
        )
    else:
        result = _execute_search(result, config, transport or _post_json)

    output = Path(output)
    output.mkdir(parents=True, exist_ok=True)
    filename = ANYSEARCH_OUTPUT_FILES["smoke" if report_kind == "smoke" else "run"]
    write_json(output / filename, result)
    write_json(
        output / ANYSEARCH_OUTPUT_FILES["source_trace"],
        {
            "schema_version": "anysearch_source_trace.v1",
            "provider_id": "anysearchskill",
            "query": query,
            "status": result["status"],
            "source_count": len(result["sources"]),
            "sources": result["sources"],
            "secrets_persisted": False,
        },
    )
    return result


def _execute_search(result: dict[str, Any], config: AnySearchConfig, transport: Transport) -> dict[str, Any]:
    headers = {"Content-Type": "application/json", "Accept": "application/json"}
    if config.api_key:
        headers["Authorization"] = f"Bearer {config.api_key}"
    payload = {
        "jsonrpc": "2.0",
        "id": 1,
        "method": "tools/call",
        "params": {
            "name": "search",
            "arguments": {
                "query": result["query"],
                "max_results": result["max_results"],
            },
        },
    }
    started = time.perf_counter()
    try:
        response = transport(config.endpoint, headers, payload, config.timeout_seconds, config.proxy_url)
        if response.get("error"):
            raise RuntimeError(f"provider_error:{response['error']}")
        text = _response_text(response)
        sources = _parse_sources(text)
        if not text or not sources:
            raise ValueError("provider_response_missing_sources")
        result.update(
            status="passed",
            runtime_status="available",
            smoke_status="passed" if result["report_kind"] == "smoke" else "not_run",
            network_called=True,
            anonymous_mode=not bool(config.api_key),
            elapsed_ms=round((time.perf_counter() - started) * 1000),
            result_count=len(sources),
            sources=sources,
            error_code=None,
            error=None,
            repair_suggestion=None,
        )
    except Exception as exc:
        code = _classify_error(exc, config)
        result.update(
            status="failed",
            runtime_status="unavailable",
            smoke_status="failed" if result["report_kind"] == "smoke" else "not_run",
            network_called=True,
            elapsed_ms=round((time.perf_counter() - started) * 1000),
            error_code=code,
            error=_safe_error(exc, config.api_key),
            repair_suggestion=_error_repair(code),
        )
    return result


def _base_result(
    config: AnySearchConfig,
    query: str,
    max_results: int,
    report_kind: str,
    allow_network: bool,
) -> dict[str, Any]:
    return {
        "schema_version": f"anysearch_provider_{report_kind}.v1",
        "provider_id": "anysearchskill",
        "integration_mode": "provider_adapter",
        "report_kind": report_kind,
        "status": "not_run",
        "runtime_status": "not_checked",
        "smoke_status": "not_run",
        "query": query,
        "max_results": max(1, min(int(max_results), 20)),
        "result_count": 0,
        "sources": [],
        "network_required": True,
        "network_allowed": allow_network,
        "network_called": False,
        "external_runtime_required": False,
        "api_key_optional": True,
        "api_key_configured": bool(config.api_key),
        "api_key_env": config.api_key_env,
        "anonymous_mode": not bool(config.api_key),
        "endpoint": _safe_url(config.endpoint),
        "reverse_proxy_configured": bool(config.reverse_proxy_url),
        "proxy_configured": bool(config.proxy_url),
        "secrets_persisted": False,
        "elapsed_ms": 0,
        "error_code": None,
        "error": None,
        "repair_suggestion": None,
        "final_target_not_downgraded": True,
        "remaining_gap": "A provider result does not complete the External Source Center UI, general API/proxy configuration campaign, Agent verification workflow, Full Gate, EXE, or release.",
        "next_required_e2e_step": "Finish the Section 5 item 5.3 integration decision and UI impact evidence before moving to item 5.4 n8n.",
        "not_goal_complete": True,
    }


def _post_json(
    endpoint: str,
    headers: dict[str, str],
    payload: dict[str, Any],
    timeout_seconds: int,
    proxy_url: str | None,
) -> dict[str, Any]:
    data = json.dumps(payload).encode("utf-8")
    request = Request(endpoint, data=data, headers=headers, method="POST")
    opener = build_opener(ProxyHandler({"http": proxy_url, "https": proxy_url})) if proxy_url else build_opener()
    with opener.open(request, timeout=timeout_seconds) as response:
        return json.loads(response.read().decode("utf-8"))


def _response_text(response: dict[str, Any]) -> str:
    content = response.get("result", {}).get("content", [])
    return "\n".join(
        str(item.get("text", ""))
        for item in content
        if isinstance(item, dict) and item.get("type") == "text"
    ).strip()


def _parse_sources(text: str) -> list[dict[str, Any]]:
    sources = []
    current: dict[str, Any] | None = None
    for raw_line in text.splitlines():
        line = raw_line.strip()
        heading = re.match(r"^###\s+(\d+)\.\s+(.+)$", line)
        if heading:
            if current and current.get("url"):
                sources.append(current)
            current = {
                "rank": int(heading.group(1)),
                "title": heading.group(2).strip(),
                "url": "",
                "snippet": "",
                "provider": "anysearchskill",
            }
            continue
        if current is None:
            continue
        url_match = re.match(r"^-\s+\*\*URL\*\*:\s+(\S+)", line)
        if url_match:
            current["url"] = url_match.group(1).strip()
        elif line.startswith("- ") and current["url"] and not current["snippet"]:
            current["snippet"] = line[2:].strip()
    if current and current.get("url"):
        sources.append(current)
    for source in sources:
        source["source_id"] = f"anysearch_{source['rank']}"
    return sources


def _validate_config(config: AnySearchConfig) -> list[str]:
    errors = []
    for label, value in (("base_url", config.base_url), ("reverse_proxy_url", config.reverse_proxy_url), ("proxy_url", config.proxy_url)):
        if not value:
            continue
        parsed = urlparse(value)
        if parsed.scheme not in {"http", "https"} or not parsed.netloc:
            errors.append(f"invalid_url:{label}")
    if config.timeout_seconds < 1 or config.timeout_seconds > 300:
        errors.append("timeout_seconds_out_of_range")
    if not config.api_key_env.strip():
        errors.append("api_key_env_required")
    return errors


def _classify_error(exc: Exception, config: AnySearchConfig) -> str:
    text = str(exc).lower()
    if config.proxy_url and ("proxy" in text or "407" in text):
        return "proxy_error"
    if isinstance(exc, HTTPError):
        if exc.code in {401, 403}:
            return "provider_auth_failed"
        if exc.code == 429:
            return "provider_rate_limited"
        return "provider_http_error"
    if isinstance(exc, (URLError, TimeoutError)):
        return "network_error"
    if "provider_response_missing_sources" in text:
        return "invalid_provider_response"
    return "provider_error"


def _error_repair(code: str) -> str:
    repairs = {
        "proxy_error": "Verify the configured proxy URL and proxy credentials, then retry the provider smoke.",
        "provider_auth_failed": "Verify the environment variable named by api_key_env; do not place the key in the config file.",
        "provider_rate_limited": "Wait for the provider rate limit window or configure an optional AnySearch API key.",
        "provider_http_error": "Verify base_url or reverse_proxy_url and inspect provider availability.",
        "network_error": "Verify network access, DNS, proxy, and reverse proxy configuration.",
        "invalid_provider_response": "Inspect provider protocol compatibility; do not mark smoke as passed.",
        "provider_error": "Inspect the structured provider error and retry after correcting the endpoint or request.",
    }
    return repairs[code]


def _repair_suggestion(errors: list[str], config: AnySearchConfig) -> str | None:
    if errors:
        return "Remove inline secrets, use valid HTTP(S) URLs, and keep API credentials in the configured environment variable."
    if not config.enabled:
        return "Enable the provider when external retrieval is required."
    if not config.api_key:
        return "Anonymous mode is available with lower limits; optionally configure the API key environment variable."
    return None


def _safe_url(value: str | None) -> str | None:
    if not value:
        return None
    parsed = urlparse(value)
    host = parsed.hostname or ""
    port = f":{parsed.port}" if parsed.port else ""
    path = parsed.path.rstrip("/")
    return f"{parsed.scheme}://{host}{port}{path}"


def _safe_error(exc: Exception, api_key: str | None = None) -> str:
    text = str(exc)
    if api_key:
        text = text.replace(api_key, "[REDACTED]")
    return re.sub(r"(?i)(bearer|api[_-]?key|token|secret)\s+[^\s,;]+", r"\1 [REDACTED]", text)[:500]


def _optional_text(value: Any) -> str | None:
    text = str(value).strip() if value is not None else ""
    return text or None
