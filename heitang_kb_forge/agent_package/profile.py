from pathlib import Path
import json

from heitang_kb_forge.schemas.agent_package_schema import AgentPackageProfile


def make_agent_profile(package: Path, skill: Path, agent_name: str, agent_type: str) -> AgentPackageProfile:
    return AgentPackageProfile(
        agent_id=_slug(agent_name),
        agent_name=agent_name,
        agent_type=agent_type,
        source_skill_id=_read_skill_id(skill),
        source_package_id=_read_package_id(package),
        kb_trust_status=_read_package_trust_status(package),
    )


def render_profile_yaml(profile: AgentPackageProfile) -> str:
    return "\n".join(f"{key}: {value}" for key, value in profile.model_dump(mode="json").items()) + "\n"


def _read_skill_id(skill: Path) -> str:
    manifest = skill / "skill_manifest.yaml"
    if manifest.exists():
        for line in manifest.read_text(encoding="utf-8").splitlines():
            if line.startswith("skill_id:"):
                return line.split(":", 1)[1].strip()
    pack_manifest = skill / "skill_pack_manifest.json"
    if pack_manifest.exists():
        try:
            payload = json.loads(pack_manifest.read_text(encoding="utf-8"))
        except json.JSONDecodeError:
            payload = {}
        suite_id = str(payload.get("suite_id") or "").strip()
        if suite_id:
            return suite_id
    suite_manifest = skill / "suite.json"
    if suite_manifest.exists():
        try:
            payload = json.loads(suite_manifest.read_text(encoding="utf-8"))
        except json.JSONDecodeError:
            payload = {}
        suite_id = str(payload.get("suite_id") or "").strip()
        if suite_id:
            return suite_id
    return skill.name


def _read_package_trust_status(package: Path) -> str:
    manifest = package / "manifest.json"
    if not manifest.exists():
        return "legacy_untracked"
    try:
        return str(json.loads(manifest.read_text(encoding="utf-8")).get("kb_trust_status", "legacy_untracked"))
    except json.JSONDecodeError:
        return "raw_parse_output"


def _read_package_id(package: Path) -> str:
    manifest = package / "manifest.json"
    if not manifest.exists():
        return package.name or "knowledge_package"
    try:
        payload = json.loads(manifest.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return package.name or "knowledge_package"
    return str(payload.get("package_id") or package.name or "knowledge_package")


def _slug(value: str) -> str:
    return "".join(char.lower() if char.isalnum() else "-" for char in value).strip("-") or "knowledge-agent"
