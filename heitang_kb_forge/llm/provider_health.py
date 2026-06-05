from pathlib import Path
import json

from heitang_kb_forge.exporters.jsonl_exporter import write_json


def check_provider_health(workspace: Path, allow_network: bool = False) -> tuple[dict, str]:
    path = workspace / "registries" / "provider_registry.json"
    registry = json.loads(path.read_text(encoding="utf-8")) if path.exists() else {"providers": []}
    results = []
    warnings = []
    for provider in registry.get("providers", []):
        provider_type = provider.get("provider_type")
        status = "pass" if provider_type == "mock" else "warning"
        if provider_type != "mock" and not allow_network:
            warnings.append(f"{provider.get('provider_id')}:network_disabled")
        results.append({"provider_id": provider.get("provider_id"), "provider_type": provider_type, "status": status})
    result = {"provider_health_version": "2.0", "status": "warning" if warnings else "pass", "providers": results, "warnings": warnings}
    write_json(workspace / "provider_health_result.json", result)
    report = render_provider_health_report(result)
    (workspace / "provider_health_report.md").write_text(report, encoding="utf-8")
    return result, report


def render_provider_health_report(result: dict) -> str:
    rows = "\n".join(f"| {item['provider_id']} | {item['provider_type']} | {item['status']} |" for item in result["providers"]) or "| - | - | - |"
    warnings = "\n".join(f"- {item}" for item in result["warnings"]) or "- None"
    return f"# Provider Health Report\n\n| Provider | Type | Status |\n| --- | --- | --- |\n{rows}\n\n## Warnings\n\n{warnings}\n"
