from __future__ import annotations

import hashlib
import json
import os
import urllib.error
import urllib.parse
import urllib.request
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Callable


PROVIDER_TYPES = {
    "official_openai",
    "official_vendor",
    "openai_compatible_proxy",
    "local_model",
    "custom_http",
}
WIRE_APIS = ("responses", "chat_completions", "embeddings")
DEFAULT_WIRE_API = {"responses": True, "chat_completions": True, "embeddings": False}


@dataclass(frozen=True)
class ProviderProfile:
    profile_id: str
    provider_type: str
    base_url: str
    model: str
    api_key: str = ""
    wire_api: dict[str, bool] | None = None
    network_required: bool = True

    def normalized_wire_api(self) -> dict[str, bool]:
        configured = self.wire_api or DEFAULT_WIRE_API
        return {name: bool(configured.get(name, False)) for name in WIRE_APIS}


def load_provider_profiles(
    *,
    env: dict[str, str] | os._Environ[str] | None = None,
    profile_file: Path | None = None,
) -> tuple[list[ProviderProfile], dict]:
    env = env or os.environ
    source_method = "none"
    raw_profiles: list[dict[str, Any]] = []
    if profile_file:
        source_method = "profile_file"
        raw_profiles = _coerce_profiles(json.loads(profile_file.read_text(encoding="utf-8")))
    elif env.get("HEITANG_LLM_PROVIDER_PROFILE_FILE"):
        source_method = "profile_file_env"
        raw_profiles = _coerce_profiles(json.loads(Path(env["HEITANG_LLM_PROVIDER_PROFILE_FILE"]).read_text(encoding="utf-8")))
    elif env.get("HEITANG_LLM_PROVIDER_PROFILES_JSON"):
        source_method = "profiles_json_env"
        raw_profiles = _coerce_profiles(json.loads(env["HEITANG_LLM_PROVIDER_PROFILES_JSON"]))
    elif any(env.get(name) for name in ["HEITANG_LLM_PROVIDER", "HEITANG_LLM_BASE_URL", "HEITANG_LLM_MODEL", "HEITANG_LLM_API_KEY"]):
        source_method = "legacy_env"
        raw_profiles = [_legacy_env_profile(env)]

    profiles = [_profile_from_dict(item, index) for index, item in enumerate(raw_profiles)]
    metadata = {
        "source_method": source_method,
        "profile_count": len(profiles),
        "legacy_env_compatible": source_method == "legacy_env",
        "allowed_provider_types": sorted(PROVIDER_TYPES),
        "official_openai_only": False,
        "openai_compatible_proxy_equivalent_to_official_openai": False,
        "bundled_or_recommended_unofficial_proxy": False,
    }
    return profiles, metadata


def run_provider_profile_acceptance(
    profiles: list[ProviderProfile],
    *,
    acceptance_enabled: bool,
    timeout_sec: float = 30,
    urlopen: Callable[..., Any] | None = None,
) -> dict:
    urlopen = urlopen or urllib.request.urlopen
    if not profiles:
        return {
            "status": "blocked_with_reason",
            "blocked_reason": "no_configured_provider_profile",
            "provider_profiles": [],
            "provider_profile_count": 0,
            "passing_provider_profile_count": 0,
            "live_gate_pass_requires_one_valid_profile": True,
            "core_usable_without_llm": True,
            "suggestions": ["Configure at least one user-owned provider profile, then rerun live LLM acceptance."],
        }

    profile_reports = []
    for profile in profiles:
        profile_reports.append(
            _probe_profile(
                profile,
                acceptance_enabled=acceptance_enabled,
                timeout_sec=timeout_sec,
                urlopen=urlopen,
            )
        )
    passing = [item for item in profile_reports if item["live_acceptance_status"] == "pass"]
    blocked_502 = any(item.get("last_error_class") == "provider_http_error_502" for item in profile_reports)
    status = "pass" if passing else "blocked_with_reason"
    blocked_reason = "" if passing else "no_provider_profile_returned_valid_live_response"
    suggestions = []
    if blocked_502:
        suggestions.append("Switch provider profile or ask the user-managed provider/proxy owner to resolve HTTP 502.")
    if not acceptance_enabled:
        suggestions.append("Set HEITANG_LLM_ACCEPTANCE_ENABLED=true or pass an explicit live-acceptance profile when running live checks.")
    return {
        "status": status,
        "blocked_reason": blocked_reason,
        "provider_profiles": profile_reports,
        "provider_profile_count": len(profile_reports),
        "passing_provider_profile_count": len(passing),
        "live_gate_pass_requires_one_valid_profile": True,
        "core_usable_without_llm": True,
        "suggestions": suggestions,
    }


def _probe_profile(
    profile: ProviderProfile,
    *,
    acceptance_enabled: bool,
    timeout_sec: float,
    urlopen: Callable[..., Any],
) -> dict:
    wire_api = profile.normalized_wire_api()
    report = _profile_public_report(profile)
    report.update(
        {
            "wire_api": wire_api,
            "capability_detection": {
                "models": _not_run("acceptance_disabled"),
                "chat_completions": _not_run("acceptance_disabled"),
                "responses": _not_run("acceptance_disabled"),
                "embeddings": _not_run("acceptance_disabled"),
            },
            "live_acceptance_status": "blocked_with_reason",
            "last_error_class": "acceptance_disabled",
            "response_hash": "",
            "tests_require_real_llm_api_network": False,
        }
    )
    if not acceptance_enabled:
        return report
    if not profile.base_url:
        report["last_error_class"] = "provider_base_url_missing"
        return report
    if profile.network_required and not profile.api_key:
        report["last_error_class"] = "provider_api_key_missing"
        return report

    detections = {
        "models": _call_endpoint(profile, "GET", "/models", None, timeout_sec, urlopen),
        "chat_completions": _call_endpoint(
            profile,
            "POST",
            "/chat/completions",
            _chat_payload(profile),
            timeout_sec,
            urlopen,
        ),
        "responses": _call_endpoint(profile, "POST", "/responses", _responses_payload(profile), timeout_sec, urlopen),
        "embeddings": _call_endpoint(profile, "POST", "/embeddings", _embeddings_payload(profile), timeout_sec, urlopen)
        if wire_api.get("embeddings")
        else _not_run("embeddings_not_enabled_for_profile"),
    }
    report["capability_detection"] = detections
    live_candidates = [detections["chat_completions"], detections["responses"]]
    passing = next((item for item in live_candidates if item["status"] == "pass"), None)
    if passing:
        report["live_acceptance_status"] = "pass"
        report["last_error_class"] = ""
        report["response_hash"] = passing.get("response_hash", "")
        return report

    first_error = next((item for item in live_candidates + [detections["models"], detections["embeddings"]] if item.get("last_error_class")), {})
    report["last_error_class"] = first_error.get("last_error_class", "provider_no_valid_live_response")
    return report


def _call_endpoint(
    profile: ProviderProfile,
    method: str,
    endpoint: str,
    payload: dict[str, Any] | None,
    timeout_sec: float,
    urlopen: Callable[..., Any],
) -> dict:
    url = f"{_api_root_url(profile.base_url).rstrip('/')}/{endpoint.lstrip('/')}"
    headers = {"Content-Type": "application/json"}
    if profile.api_key:
        headers["Authorization"] = "Bearer <redacted>"
    request_headers = {"Content-Type": "application/json"}
    if profile.api_key:
        request_headers["Authorization"] = f"Bearer {profile.api_key}"
    request = urllib.request.Request(
        url,
        data=json.dumps(payload).encode("utf-8") if payload is not None else None,
        headers=request_headers,
        method=method,
    )
    try:
        with urlopen(request, timeout=timeout_sec) as response:  # noqa: S310 - explicit opt-in live provider probe.
            body = response.read(12000)
            status_code = int(getattr(response, "status", 200))
    except urllib.error.HTTPError as exc:
        body = exc.read(12000)
        return _endpoint_result(endpoint, "blocked_with_reason", exc.code, body, f"provider_http_error_{exc.code}", headers)
    except urllib.error.URLError as exc:
        return _endpoint_result(endpoint, "blocked_with_reason", None, b"", "provider_network_error", headers, str(exc.reason))
    except TimeoutError:
        return _endpoint_result(endpoint, "blocked_with_reason", None, b"", "provider_timeout", headers)
    except Exception as exc:  # noqa: BLE001 - live probe must report stable failure.
        return _endpoint_result(endpoint, "blocked_with_reason", None, b"", exc.__class__.__name__, headers)
    status = "pass" if 200 <= status_code < 300 and bool(body.strip()) else "blocked_with_reason"
    error_class = "" if status == "pass" else "provider_empty_or_non_success_response"
    return _endpoint_result(endpoint, status, status_code, body, error_class, headers)


def _endpoint_result(
    endpoint: str,
    status: str,
    http_status: int | None,
    body: bytes,
    error_class: str,
    headers: dict[str, str],
    message: str = "",
) -> dict:
    return {
        "endpoint": endpoint,
        "status": status,
        "http_status": http_status,
        "last_error_class": error_class,
        "response_hash": hashlib.sha256(body).hexdigest() if body else "",
        "response_text_committed": False,
        "request_headers_committed": {"Authorization": headers.get("Authorization", "")},
        "message": message,
    }


def _profile_public_report(profile: ProviderProfile) -> dict:
    return {
        "profile_id": profile.profile_id,
        "provider_type": profile.provider_type,
        "base_url": _redact_url(profile.base_url),
        "model": profile.model,
        "api_key": "<redacted>" if profile.api_key else "",
        "api_key_configured": bool(profile.api_key),
        "network_required": profile.network_required,
        "privacy_notice": _privacy_notice(profile.provider_type),
        "official_openai_equivalent": profile.provider_type == "official_openai",
        "third_party_proxy_not_equivalent_to_official_api": profile.provider_type == "openai_compatible_proxy",
        "shared_key_stored": False,
    }


def _privacy_notice(provider_type: str) -> str:
    if provider_type == "official_openai":
        return "Official OpenAI API profile. User supplies their own key; HeiTang stores only redacted report metadata."
    if provider_type == "official_vendor":
        return "Official vendor API profile. User supplies their own provider endpoint and key."
    if provider_type == "openai_compatible_proxy":
        return "User-configured OpenAI-compatible proxy. It is not bundled, recommended, or equivalent to an official API."
    if provider_type == "local_model":
        return "Local model profile. Keep traffic on the configured local endpoint when provided."
    return "Custom HTTP profile. User is responsible for endpoint trust, privacy, and compatibility."


def _api_root_url(base_url: str) -> str:
    root = base_url.rstrip("/")
    for suffix in ("/chat/completions", "/responses", "/embeddings", "/models"):
        if root.endswith(suffix):
            return root[: -len(suffix)]
    return root


def _redact_url(url: str) -> str:
    if not url:
        return ""
    parsed = urllib.parse.urlsplit(url)
    netloc = parsed.netloc
    if "@" in netloc:
        netloc = f"<redacted>@{netloc.rsplit('@', 1)[-1]}"
    query = "<redacted>" if parsed.query else ""
    return urllib.parse.urlunsplit((parsed.scheme, netloc, parsed.path, query, ""))


def _legacy_env_profile(env: dict[str, str] | os._Environ[str]) -> dict[str, Any]:
    provider = env.get("HEITANG_LLM_PROVIDER", "custom_http")
    provider_type = provider if provider in PROVIDER_TYPES else "custom_http"
    return {
        "profile_id": "legacy_env",
        "provider_type": provider_type,
        "base_url": env.get("HEITANG_LLM_BASE_URL", ""),
        "model": env.get("HEITANG_LLM_MODEL", ""),
        "api_key": env.get("HEITANG_LLM_API_KEY", ""),
        "wire_api": {"chat_completions": True, "responses": True, "embeddings": False},
        "network_required": provider_type != "local_model",
    }


def _profile_from_dict(data: dict[str, Any], index: int) -> ProviderProfile:
    provider_type = str(data.get("provider_type") or "custom_http")
    if provider_type not in PROVIDER_TYPES:
        provider_type = "custom_http"
    raw_wire_api = data.get("wire_api")
    wire_api = DEFAULT_WIRE_API if raw_wire_api is None else raw_wire_api
    if isinstance(wire_api, list):
        wire_api = {item: True for item in wire_api}
    return ProviderProfile(
        profile_id=str(data.get("profile_id") or data.get("provider_id") or f"profile_{index + 1}"),
        provider_type=provider_type,
        base_url=str(data.get("base_url") or ""),
        model=str(data.get("model") or ""),
        api_key=str(data.get("api_key") or ""),
        wire_api={name: bool(wire_api.get(name, False)) for name in WIRE_APIS},
        network_required=bool(data.get("network_required", provider_type != "local_model")),
    )


def _coerce_profiles(payload: Any) -> list[dict[str, Any]]:
    if isinstance(payload, dict) and isinstance(payload.get("provider_profiles"), list):
        return [item for item in payload["provider_profiles"] if isinstance(item, dict)]
    if isinstance(payload, dict) and isinstance(payload.get("profiles"), list):
        return [item for item in payload["profiles"] if isinstance(item, dict)]
    if isinstance(payload, list):
        return [item for item in payload if isinstance(item, dict)]
    if isinstance(payload, dict):
        return [payload]
    return []


def _chat_payload(profile: ProviderProfile) -> dict[str, Any]:
    return {
        "model": profile.model,
        "messages": [
            {"role": "system", "content": "Return a short readiness phrase."},
            {"role": "user", "content": "HeiTang live provider acceptance smoke."},
        ],
        "temperature": 0,
        "max_tokens": 32,
    }


def _responses_payload(profile: ProviderProfile) -> dict[str, Any]:
    return {"model": profile.model, "input": "HeiTang live provider acceptance smoke."}


def _embeddings_payload(profile: ProviderProfile) -> dict[str, Any]:
    return {"model": profile.model, "input": "HeiTang embedding capability detection."}


def _not_run(reason: str) -> dict:
    return {
        "status": "not_run",
        "http_status": None,
        "last_error_class": reason,
        "response_hash": "",
        "response_text_committed": False,
    }
