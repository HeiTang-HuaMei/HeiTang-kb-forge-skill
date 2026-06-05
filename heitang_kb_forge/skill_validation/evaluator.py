from pathlib import Path
import json

from heitang_kb_forge.exporters.jsonl_exporter import write_json, write_jsonl
from heitang_kb_forge.schemas.skill_validation_schema import SkillValidationResult
from heitang_kb_forge.skill_validation.benchmarks import make_benchmark_cases
from heitang_kb_forge.skill_validation.boundary_check import boundary_score
from heitang_kb_forge.skill_validation.evidence_check import evidence_score
from heitang_kb_forge.skill_validation.report import render_skill_validation_report
from heitang_kb_forge.skill_validation.style_check import style_score


SKILL_VALIDATION_FILES = [
    "skill_validation_report.md",
    "skill_validation_result.json",
    "skill_benchmark_cases.jsonl",
]


def validate_skill_package(skill: Path, package: Path, output: Path) -> SkillValidationResult:
    output.mkdir(parents=True, exist_ok=True)
    errors = [f"missing_{name}" for name in _required_files() if not (skill / name).exists()]
    evidence, evidence_warnings = evidence_score(skill, package) if not errors else (0, [])
    boundary, boundary_warnings = boundary_score(skill) if not errors else (0, [])
    style, style_warnings = style_score(skill) if not errors else (0, [])
    eval_cases = make_benchmark_cases(skill)
    eval_coverage = 100 if eval_cases else 0
    citation_policy = 100 if (skill / "citation_rules.md").exists() else 0
    refusal = 100 if (skill / "refusal_rules.md").exists() else 0
    scores = {
        "evidence_grounding": evidence,
        "boundary_control": boundary,
        "refusal_correctness": refusal,
        "citation_policy": citation_policy,
        "style_consistency": style,
        "eval_coverage": eval_coverage,
    }
    warnings = evidence_warnings + boundary_warnings + style_warnings
    status = "fail" if errors else ("warning" if warnings or min(scores.values()) < 80 else "pass")
    result = SkillValidationResult(
        skill_id=_skill_id(skill),
        status=status,
        release_ready=status == "pass" and min(scores.values()) >= 80,
        scores=scores,
        warnings=warnings,
        errors=errors,
        review_required=warnings,
    )
    write_json(output / "skill_validation_result.json", result.model_dump(mode="json"))
    (output / "skill_validation_report.md").write_text(render_skill_validation_report(result), encoding="utf-8")
    write_jsonl(output / "skill_benchmark_cases.jsonl", eval_cases)
    return result


def _required_files() -> list[str]:
    return [
        "SKILL.md",
        "skill_manifest.yaml",
        "knowledge_scope.md",
        "answer_rules.md",
        "citation_rules.md",
        "boundary_rules.md",
        "refusal_rules.md",
        "style_rules.md",
        "evidence_policy.md",
        "eval_cases.jsonl",
    ]


def _skill_id(skill: Path) -> str:
    path = skill / "skill_manifest.yaml"
    if not path.exists():
        return skill.name
    for line in path.read_text(encoding="utf-8").splitlines():
        if line.startswith("skill_id:"):
            return line.split(":", 1)[1].strip()
    return skill.name
