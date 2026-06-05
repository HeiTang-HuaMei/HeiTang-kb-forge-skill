from pathlib import Path

SAMPLE_TYPES = [
    "minimal_knowledge_package",
    "multimodal_knowledge_package",
    "skill_package",
    "derived_skill_package",
    "agent_package",
    "workspace_snapshot",
    "platform_export_all",
    "xhs_skill_package_mock",
    "mcp_stub_package",
]


def make_registry(samples_root: Path) -> list[dict]:
    return [
        {"sample_id": sample_type, "path": str(samples_root / _path_for(sample_type)).replace("\\", "/")}
        for sample_type in SAMPLE_TYPES
    ]


def _path_for(sample_type: str) -> str:
    if "platform" in sample_type or "xhs" in sample_type or "mcp" in sample_type:
        return "platform_export_mock" if sample_type == "platform_export_all" else "platform_exports"
    if "skill" in sample_type and "agent" not in sample_type:
        return "skill_package" if sample_type == "skill_package" else "derived_skill_package"
    if "agent" in sample_type:
        return "agent_package"
    if "workspace" in sample_type:
        return "workspace"
    return "minimal_knowledge_package" if sample_type == "minimal_knowledge_package" else "knowledge_package"
