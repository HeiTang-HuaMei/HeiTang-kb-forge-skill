from pathlib import Path
import json

from heitang_kb_forge.exporters.jsonl_exporter import write_jsonl
from heitang_kb_forge.master_skill.license_checker import run_skill_license_check
from heitang_kb_forge.master_skill.safety_checker import run_skill_safety_check
from heitang_kb_forge.master_skill.similarity_checker import run_skill_similarity_check


DERIVED_FILES = [
    "SKILL.md",
    "skill_manifest.yaml",
    "knowledge_scope.md",
    "TASKS.md",
    "INPUT_OUTPUT.md",
    "STYLE_PROFILE.md",
    "STRATEGY_PROFILE.md",
    "BOUNDARY_RULES.md",
    "SAFE_REFUSAL.md",
    "EVIDENCE_USAGE.md",
    "OPERATION_GUIDE.md",
    "RELEASE_CHECKLIST.md",
    "eval_cases.jsonl",
    "derivation_report.md",
]


def generate_derived_skill(master_skill: Path, knowledge_package: Path, output: Path, style_profile: Path | None = None) -> dict:
    output.mkdir(parents=True, exist_ok=True)
    decomposition = _read_json(master_skill / "skill_decomposition.json")
    package_manifest = _read_json(knowledge_package / "manifest.json")
    skill_name = f"{package_manifest.get('package_id', knowledge_package.name)} derived skill"
    (output / "SKILL.md").write_text(f"# {skill_name}\n\nUse this Skill with the user's own knowledge package. It follows learned workflow patterns without copying master Skill content.\n", encoding="utf-8")
    (output / "skill_manifest.yaml").write_text(f"skill_name: {skill_name}\nskill_type: derived_skill\nsource_package_path: {knowledge_package}\ngenerated_by: heitang_kb_forge_v2.2\n", encoding="utf-8")
    (output / "knowledge_scope.md").write_text(f"# Knowledge Scope\n\nSource package: {knowledge_package}\n", encoding="utf-8")
    (output / "TASKS.md").write_text("# Tasks\n\n" + _bullets(decomposition.get("workflow_steps", ["answer with evidence"])), encoding="utf-8")
    (output / "INPUT_OUTPUT.md").write_text("# Input / Output\n\nInputs and outputs are derived from the user's package, not copied from the master Skill.\n", encoding="utf-8")
    (output / "STYLE_PROFILE.md").write_text("# Style Profile\n\n" + (style_profile.read_text(encoding="utf-8") if style_profile and style_profile.exists() else _bullets(decomposition.get("style_features", ["clear and evidence-based"]))), encoding="utf-8")
    (output / "STRATEGY_PROFILE.md").write_text("# Strategy Profile\n\n" + _bullets(decomposition.get("workflow_steps", ["retrieve evidence", "answer within scope"])), encoding="utf-8")
    (output / "BOUNDARY_RULES.md").write_text("# Boundary Rules\n\n" + _bullets(decomposition.get("boundary_rules", ["do not answer outside the knowledge scope"])), encoding="utf-8")
    (output / "SAFE_REFUSAL.md").write_text("# Safe Refusal\n\nRefuse when evidence is missing or the request is outside the knowledge scope.\n", encoding="utf-8")
    (output / "EVIDENCE_USAGE.md").write_text("# Evidence Usage\n\nUse source_path, chunk_id, and citation when available.\n", encoding="utf-8")
    (output / "OPERATION_GUIDE.md").write_text("# Operation Guide\n\nValidate the Skill before release and review derivation reports.\n", encoding="utf-8")
    (output / "RELEASE_CHECKLIST.md").write_text("# Release Checklist\n\n- [ ] Safety checked\n- [ ] Similarity checked\n- [ ] License reviewed\n", encoding="utf-8")
    write_jsonl(output / "eval_cases.jsonl", [{"case_id": "derived_case_1", "query": "Answer with package evidence.", "expected_behavior": "answer_with_citation"}])
    (output / "derivation_report.md").write_text("# Derivation Report\n\nThis package learns task structure and boundaries, then combines them with the user's own knowledge package.\n", encoding="utf-8")
    run_skill_safety_check(output, output)
    run_skill_similarity_check(master_skill, output, output)
    run_skill_license_check(master_skill, output)
    return {"output": str(output), "files": DERIVED_FILES}


def _read_json(path: Path) -> dict:
    if not path.exists():
        return {}
    return json.loads(path.read_text(encoding="utf-8"))


def _bullets(values: list[str]) -> str:
    return "\n".join(f"- {value}" for value in values) or "- generic"
