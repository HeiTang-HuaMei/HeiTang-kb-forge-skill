from pathlib import Path
import json

from heitang_kb_forge.schemas.skill_schema import SkillManifest


def make_skill_manifest(package: Path, skill_name: str, skill_type: str) -> SkillManifest:
    manifest = _load_json(package / "manifest.json")
    source_package_id = str(manifest.get("package_id") or package.name or "knowledge_package")
    return SkillManifest(
        skill_id=_slug(skill_name),
        skill_name=skill_name,
        source_package_id=source_package_id,
        source_contract_version=manifest.get("contract_version"),
        kb_trust_status=manifest.get("kb_trust_status", "legacy_untracked"),
        supported_tasks=[skill_type, "answer_with_citations", "boundary_aware_refusal"],
        required_assets=["chunks.jsonl", "cards.jsonl", "qa_pairs.jsonl", "glossary.jsonl", "manifest.json"],
    )


def render_skill_manifest_yaml(manifest: SkillManifest) -> str:
    lines = []
    for key, value in manifest.model_dump(mode="json").items():
        if isinstance(value, list):
            lines.append(f"{key}:")
            lines.extend(f"  - {item}" for item in value)
        else:
            lines.append(f"{key}: {value}")
    return "\n".join(lines) + "\n"


def _load_json(path: Path) -> dict:
    if not path.exists():
        return {}
    return json.loads(path.read_text(encoding="utf-8"))


def _slug(value: str) -> str:
    return "".join(char.lower() if char.isalnum() else "-" for char in value).strip("-") or "knowledge-skill"
