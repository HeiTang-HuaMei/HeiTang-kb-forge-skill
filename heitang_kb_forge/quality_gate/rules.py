from pathlib import Path

QUALITY_GATE_OBJECTS = {
    "knowledge_package": ["manifest.json", "chunks.jsonl", "quality_report.json"],
    "skill_package": ["skill_package/SKILL.md"],
    "derived_skill_package": ["derived_skill_package/SKILL.md"],
    "agent_package": ["agent_package/agent_profile.yaml"],
    "workspace": ["workspace/workspace_manifest.json"],
    "provider_registry": ["workspace/registries/provider_registry.json"],
    "prompt_profiles": ["workspace/registries/prompt_profile_registry.json"],
    "llm_audit": ["workspace/registries/llm_call_audit.jsonl"],
    "platform_exports": ["platform_distribution/platform_manifest.json", "platform_distribution/platform_upload_check_result.json"],
}


def gate_status(workspace: Path, files: list[str]) -> str:
    if all((workspace / name).exists() for name in files):
        return "pass"
    if any((workspace / name).exists() for name in files):
        return "warning"
    return "not_found"

