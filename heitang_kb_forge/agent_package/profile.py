from pathlib import Path

from heitang_kb_forge.schemas.agent_package_schema import AgentPackageProfile


def make_agent_profile(package: Path, skill: Path, agent_name: str, agent_type: str) -> AgentPackageProfile:
    return AgentPackageProfile(
        agent_id=_slug(agent_name),
        agent_name=agent_name,
        agent_type=agent_type,
        source_skill_id=_read_skill_id(skill),
        source_package_id=package.name or "knowledge_package",
    )


def render_profile_yaml(profile: AgentPackageProfile) -> str:
    return "\n".join(f"{key}: {value}" for key, value in profile.model_dump(mode="json").items()) + "\n"


def _read_skill_id(skill: Path) -> str:
    manifest = skill / "skill_manifest.yaml"
    if not manifest.exists():
        return skill.name
    for line in manifest.read_text(encoding="utf-8").splitlines():
        if line.startswith("skill_id:"):
            return line.split(":", 1)[1].strip()
    return skill.name


def _slug(value: str) -> str:
    return "".join(char.lower() if char.isalnum() else "-" for char in value).strip("-") or "knowledge-agent"
