from pathlib import Path
import shutil

from heitang_kb_forge.exporters.jsonl_exporter import write_json
from heitang_kb_forge.platform_distribution.guides import install_guide, upload_guide, xhs_policy, xhs_violation_checklist
from heitang_kb_forge.platform_distribution.mock_publish import mock_publish_package
from heitang_kb_forge.platform_distribution.platforms import SUPPORTED_PLATFORMS, expand_platforms
from heitang_kb_forge.platform_distribution.upload_check import check_platform_upload
from heitang_kb_forge.schemas.platform_distribution_schema import PlatformManifest


def export_platform_package(skill: Path, agent: Path | None, output: Path, platform: str) -> list[PlatformManifest]:
    output.mkdir(parents=True, exist_ok=True)
    manifests = []
    for platform_name in expand_platforms(platform):
        platform_output = output / platform_name if platform == "all" else output
        platform_output.mkdir(parents=True, exist_ok=True)
        exported_files = _write_platform_files(skill, agent, platform_output, platform_name)
        manifest = PlatformManifest(
            platform=platform_name,
            source_skill=str(skill).replace("\\", "/"),
            source_agent=str(agent).replace("\\", "/") if agent else None,
            supported_platforms=SUPPORTED_PLATFORMS,
            exported_files=exported_files,
            policy_files=_policy_files(platform_name),
            warnings=_platform_warnings(platform_name),
            limits=_platform_limits(platform_name),
        )
        write_json(platform_output / "platform_manifest.json", manifest)
        mock_publish_package(platform_output, platform_name, platform_output)
        check_platform_upload(platform_output, platform_output, platform_name)
        manifests.append(manifest)
    return manifests


def _write_platform_files(skill: Path, agent: Path | None, output: Path, platform: str) -> list[str]:
    files: list[str] = []
    _copy_if_exists(skill / "SKILL.md", output / "SKILL.md", files)
    if agent:
        _copy_if_exists(agent / "agent_profile.yaml", output / "agent_profile.yaml", files)
    (output / "install_guide.md").write_text(install_guide(platform), encoding="utf-8")
    (output / "upload_guide.md").write_text(upload_guide(platform), encoding="utf-8")
    files.extend(["install_guide.md", "upload_guide.md"])
    if platform == "openclaw":
        (output / "openclaw_agent.yaml").write_text("platform: openclaw\nmode: local_export_stub\n", encoding="utf-8")
        files.append("openclaw_agent.yaml")
    elif platform == "codex":
        (output / "codex_instructions.md").write_text("# Codex Instructions\n\nUse this exported Skill package locally.\n", encoding="utf-8")
        files.append("codex_instructions.md")
    elif platform == "claude_code":
        (output / "claude_code_instructions.md").write_text("# Claude Code Instructions\n\nUse this exported Skill package locally.\n", encoding="utf-8")
        files.append("claude_code_instructions.md")
    elif platform == "mcp":
        write_json(output / "mcp_manifest.json", {"platform": "mcp", "server_started": False})
        files.append("mcp_manifest.json")
    elif platform == "local_registry":
        write_json(output / "local_registry_manifest.json", {"platform": "local_registry", "registered": False})
        files.append("local_registry_manifest.json")
    elif platform == "generic":
        write_json(output / "generic_platform_profile.json", {"platform": "generic"})
        files.append("generic_platform_profile.json")
    elif platform == "xhs":
        _write_xhs_files(skill, output, files)
    return files


def _policy_files(platform: str) -> list[str]:
    if platform == "xhs":
        return ["platform_policy.md", "violation_risk_checklist.md"]
    return []


def _platform_warnings(platform: str) -> list[str]:
    warnings = [
        "Local export package only.",
        "No real platform account or external platform API is used.",
    ]
    if platform in {"openclaw", "codex", "claude_code", "mcp"}:
        warnings.append(f"{platform} output is an adapter package or stub only; no runtime is executed.")
    if platform == "xhs":
        warnings.append("XHS output is not an official XHS upload API and does not publish notes automatically.")
    return warnings


def _platform_limits(platform: str) -> list[str]:
    limits = [
        "No real upload.",
        "No external platform runtime execution.",
    ]
    if platform == "mcp":
        limits.append("No MCP server startup.")
    if platform == "xhs":
        limits.extend(["No real XHS account login.", "No automatic XHS note publishing."])
    return limits


def _write_xhs_files(skill: Path, output: Path, files: list[str]) -> None:
    xhs_dir = output / "xhs_skill_package"
    xhs_dir.mkdir(parents=True, exist_ok=True)
    _copy_if_exists(skill / "SKILL.md", xhs_dir / "SKILL.md", files, prefix="xhs_skill_package/")
    write_json(
        output / "xhs_skill_manifest.json",
        {
            "platform": "xhs",
            "package_type": "local_xhs_skill_package",
            "official_xhs_upload_api": False,
            "real_account_used": False,
            "automatic_note_publish": False,
        },
    )
    write_json(output / "xhs_skill_link_manifest.json", {"links": [], "manual_review_required": True})
    (output / "platform_policy.md").write_text(xhs_policy(), encoding="utf-8")
    (output / "violation_risk_checklist.md").write_text(xhs_violation_checklist(), encoding="utf-8")
    files.extend(["xhs_skill_manifest.json", "xhs_skill_link_manifest.json", "platform_policy.md", "violation_risk_checklist.md"])


def _copy_if_exists(source: Path, destination: Path, files: list[str], prefix: str = "") -> None:
    if source.exists():
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, destination)
        files.append(f"{prefix}{destination.name}")
