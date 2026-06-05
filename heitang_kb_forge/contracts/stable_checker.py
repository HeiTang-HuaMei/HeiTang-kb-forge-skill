from pathlib import Path

from heitang_kb_forge.contracts.compatibility import contract_status
from heitang_kb_forge.contracts.stable_contract import STABLE_CONTRACTS
from heitang_kb_forge.exporters.jsonl_exporter import write_json
from heitang_kb_forge.schemas.stable_contract_schema import StableCheckResult


EXTENSION_READINESS = {
    "input_hardening": "not_enabled",
    "master_skill_learning": "not_enabled",
    "derived_skill_generation": "not_enabled",
    "batch_governance": "not_enabled",
    "platform_distribution": "not_enabled",
    "xhs_skill_export": "not_enabled",
    "quality_gate": "not_enabled",
    "provider_security_audit": "not_enabled",
    "domain_skill_factory": "not_enabled",
    "feishu_publishing": "not_enabled",
    "mobile_distribution": "not_enabled",
}


def run_stable_check(workspace: Path) -> tuple[StableCheckResult, str]:
    statuses = {}
    warnings = []
    for name, files in STABLE_CONTRACTS.items():
        present = all((workspace / file_name).exists() for file_name in files)
        statuses[name] = contract_status(present)
        if not present:
            warnings.append(f"{name}_contract_incomplete")
    result = StableCheckResult(
        status="warning" if warnings else "pass",
        checked_contracts=statuses,
        extension_readiness=EXTENSION_READINESS,
        warnings=warnings,
        release_ready=not warnings,
    )
    write_json(workspace / "stable_check_result.json", result.model_dump(mode="json"))
    report = render_stable_check_report(result)
    (workspace / "stable_check_report.md").write_text(report, encoding="utf-8")
    return result, report


def render_stable_check_report(result: StableCheckResult) -> str:
    rows = "\n".join(f"| {key} | {value} |" for key, value in result.checked_contracts.items())
    warnings = "\n".join(f"- {item}" for item in result.warnings) or "- None"
    extensions = "\n".join(f"| {key} | {value} |" for key, value in result.extension_readiness.items())
    return f"""# Stable Check Report

- Status: {result.status}
- Release ready: {result.release_ready}

| Contract | Status |
| --- | --- |
{rows}

## Warnings

{warnings}

## Extension Readiness

| Extension | Status |
| --- | --- |
{extensions}
"""
