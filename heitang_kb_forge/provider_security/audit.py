from __future__ import annotations

import json
from datetime import datetime, timezone
from pathlib import Path

from heitang_kb_forge.exporters.jsonl_exporter import write_json

SENSITIVE_MARKERS = ("sk-", "secret", "password", "token")


def run_provider_security_audit(workspace: Path, output: Path) -> dict:
    output.mkdir(parents=True, exist_ok=True)
    providers = _load_providers(workspace)
    findings = [_audit_provider(provider) for provider in providers]
    high_or_critical = [item for item in findings if item["severity"] in {"high", "critical"}]
    result = {
        "provider_security_version": "2.6.0",
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "workspace": str(workspace),
        "provider_count": len(providers),
        "status": "fail" if high_or_critical else "pass",
        "stores_real_api_keys": any(item["stores_real_api_key"] for item in findings),
        "network_required_by_default": any(item["network_required_by_default"] for item in findings),
        "high_or_critical_count": len(high_or_critical),
        "findings": findings,
    }
    write_json(output / "provider_security_audit.json", result)
    (output / "provider_security_report.md").write_text(_render_report(result), encoding="utf-8")
    return result


def _load_providers(workspace: Path) -> list[dict]:
    registry = workspace / "registries" / "provider_registry.json"
    if not registry.exists():
        return [{"provider_id": "mock_default", "provider_type": "mock", "api_key_env": None, "network_required": False}]
    payload = json.loads(registry.read_text(encoding="utf-8"))
    return payload.get("providers", [])


def _audit_provider(provider: dict) -> dict:
    api_key_env = provider.get("api_key_env")
    inline_values = [
        str(provider.get(key) or "")
        for key in ["api_key", "secret_key", "token", "password", "authorization"]
        if provider.get(key)
    ]
    stores_real_key = any(_looks_sensitive(value) for value in inline_values)
    network_required = bool(provider.get("network_required")) and bool(provider.get("enabled"))
    suspicious_env_name = bool(api_key_env and _looks_sensitive(api_key_env))
    severity = "critical" if stores_real_key else "high" if network_required else "warning" if suspicious_env_name else "info"
    warnings: list[str] = []
    if stores_real_key:
        warnings.append("Provider config appears to store a real secret value.")
    if network_required:
        warnings.append("Provider is enabled and requires network by default.")
    if suspicious_env_name:
        warnings.append("api_key_env name looks suspicious; store env var names only, not values.")
    return {
        "provider_id": provider.get("provider_id", "unknown"),
        "provider_type": provider.get("provider_type", "unknown"),
        "severity": severity,
        "stores_real_api_key": stores_real_key,
        "api_key_env_present": bool(api_key_env),
        "api_key_env": api_key_env,
        "network_required_by_default": network_required,
        "warnings": warnings,
    }


def _looks_sensitive(value: str) -> bool:
    lowered = value.lower()
    return any(marker in lowered for marker in SENSITIVE_MARKERS) and len(value) >= 8


def _render_report(result: dict) -> str:
    lines = [
        "# Provider Security Audit",
        "",
        f"- Status: {result['status']}",
        f"- Providers: {result['provider_count']}",
        f"- Stores real API keys: {result['stores_real_api_keys']}",
        f"- Network required by default: {result['network_required_by_default']}",
        f"- High or critical findings: {result['high_or_critical_count']}",
        "",
        "## Findings",
        "",
    ]
    for item in result["findings"]:
        lines.append(
            f"- {item['provider_id']} ({item['provider_type']}): {item['severity']} | "
            f"api_key_env_present={item['api_key_env_present']} | "
            f"network_required_by_default={item['network_required_by_default']}"
        )
        for warning in item["warnings"]:
            lines.append(f"  - {warning}")
    lines.extend(
        [
            "",
            "## Boundary",
            "",
            "This audit is local-only. It does not call provider APIs and does not validate real credentials.",
        ]
    )
    return "\n".join(lines) + "\n"
