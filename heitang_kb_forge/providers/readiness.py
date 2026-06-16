from pathlib import Path
import json

from heitang_kb_forge.exporters.jsonl_exporter import write_json


def make_provider_readiness(workspace: Path, output: Path) -> dict:
    output.mkdir(parents=True, exist_ok=True)
    registry = workspace / "registries" / "provider_registry.json"
    providers = []
    if registry.exists():
        data = json.loads(registry.read_text(encoding="utf-8-sig"))
        providers = data.get("providers", [])
    if not providers:
        providers = [{"provider_id": "mock_default", "provider_type": "mock", "status": "disabled"}]
    result = {"provider_count": len(providers), "network_required": False, "api_keys_stored": False, "providers": providers}
    write_json(output / "provider_readiness_result.json", result)
    (output / "provider_readiness_report.md").write_text(
        "# Provider Readiness Report\n\n"
        f"- Providers: {len(providers)}\n"
        "- Network required: False\n"
        "- API keys stored: False\n",
        encoding="utf-8",
    )
    return result
