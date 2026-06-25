from __future__ import annotations

from pathlib import Path

from heitang_kb_forge.exporters.jsonl_exporter import write_json
from heitang_kb_forge.schemas.credential_proxy_schema import CredentialProxyEntry, CredentialProxyReport


CREDENTIAL_PROXY_BOUNDARY = {
    "stores_plaintext_credential": "forbidden",
    "reads_environment_values": "not_required",
    "network": "not_required",
    "ui_change": "not_required",
    "runtime_change": "not_required",
    "redis_service_packaging": "forbidden",
    "vector_service_packaging": "forbidden",
}


def validate_credential_proxy_design(entries: list[CredentialProxyEntry | dict], output: Path | None = None) -> CredentialProxyReport:
    parsed = [entry if isinstance(entry, CredentialProxyEntry) else CredentialProxyEntry.model_validate(entry) for entry in entries]
    failed_checks: list[str] = []
    masked_entries = []
    for entry in parsed:
        entry_failures = _entry_failures(entry)
        failed_checks.extend(f"{entry.provider_id}:{failure}" for failure in entry_failures)
        masked_entries.append(
            {
                "provider_id": entry.provider_id,
                "credential_source": "env_ref" if entry.credential_env else "missing",
                "credential_env": entry.credential_env or None,
                "endpoint_env": entry.endpoint_env or None,
                "model_env": entry.model_env or None,
                "inline_credential_present": bool(entry.inline_credential),
                "status": "failed" if entry_failures else "passed",
            }
        )
    report = CredentialProxyReport(
        status="passed" if not failed_checks else "failed",
        provider_count=len(parsed),
        failed_checks=failed_checks,
        entries=masked_entries,
        output_files=["credential_proxy_design_report.json"],
        boundary=CREDENTIAL_PROXY_BOUNDARY,
    )
    if output:
        output.mkdir(parents=True, exist_ok=True)
        write_json(output / "credential_proxy_design_report.json", report)
    return report


def _entry_failures(entry: CredentialProxyEntry) -> list[str]:
    failures: list[str] = []
    if not entry.credential_env:
        failures.append("missing_credential_env")
    if entry.inline_credential:
        failures.append("inline_credential_forbidden")
    if entry.credential_env and not _looks_like_env_name(entry.credential_env):
        failures.append("invalid_credential_env_name")
    return failures


def _looks_like_env_name(value: str) -> bool:
    return value.upper() == value and value.replace("_", "").isalnum()
