from __future__ import annotations

import re
from pathlib import Path

from heitang_kb_forge.exporters.jsonl_exporter import write_json, write_jsonl


SKILL_REVERSE_FUSION_OUTPUT_FILES = [
    "skill_reverse_profiles.json",
    "skill_fusion_plan.json",
    "fused_skill/SKILL.md",
    "fused_skill/skill_manifest.yaml",
    "fused_skill/boundary_rules.md",
    "fused_skill/evidence_policy.md",
    "skill_reverse_fusion_trace.json",
    "skill_reverse_fusion_quality_report.json",
    "skill_reverse_fusion_report.md",
]


def reverse_and_fuse_skills(skills: list[Path], output: Path, fused_name: str = "Fused Knowledge Skill") -> dict:
    output.mkdir(parents=True, exist_ok=True)
    profiles = [_reverse_skill(skill) for skill in skills]
    plan = {
        "skill_fusion_plan_version": "3.3.0-alpha.1",
        "fused_name": fused_name,
        "source_skill_count": len(profiles),
        "capabilities": sorted({item for profile in profiles for item in profile["capabilities"]}),
        "boundary_rules": sorted({item for profile in profiles for item in profile["boundary_rules"]}),
    }
    fused = output / "fused_skill"
    fused.mkdir(parents=True, exist_ok=True)
    (fused / "SKILL.md").write_text(_skill_md(fused_name, plan), encoding="utf-8")
    (fused / "skill_manifest.yaml").write_text(
        f"skill_name: {fused_name}\nskill_type: fused_skill\nsource_skill_count: {len(profiles)}\ngenerated_by: skill_reverse_fusion\n",
        encoding="utf-8",
    )
    (fused / "boundary_rules.md").write_text("# Boundary Rules\n\n" + _bullets(plan["boundary_rules"] or ["do not answer outside fused skill scope"]), encoding="utf-8")
    (fused / "evidence_policy.md").write_text("# Evidence Policy\n\nUse only evidence available to the bound knowledge package or retrieved context.\n", encoding="utf-8")
    quality = {
        "skill_reverse_fusion_version": "3.3.0-alpha.1",
        "status": "pass" if profiles else "fail",
        "source_skill_count": len(profiles),
        "capability_count": len(plan["capabilities"]),
        "boundary_rule_count": len(plan["boundary_rules"]),
        "review_required": len(profiles) > 1,
    }
    trace = {
        "skill_reverse_fusion_trace_version": "3.3.0-alpha.1",
        "steps": [
            {"name": "reverse_skills", "status": "pass", "count": len(profiles)},
            {"name": "build_fusion_plan", "status": "pass"},
            {"name": "write_fused_skill", "status": quality["status"]},
        ],
    }
    manifest = {
        "skill_reverse_fusion_version": "3.3.0-alpha.1",
        "status": quality["status"],
        "fused_skill": str(fused),
        "output_files": SKILL_REVERSE_FUSION_OUTPUT_FILES,
    }
    write_json(output / "skill_reverse_profiles.json", {"profiles": profiles})
    write_json(output / "skill_fusion_plan.json", plan)
    write_json(output / "skill_reverse_fusion_trace.json", trace)
    write_json(output / "skill_reverse_fusion_quality_report.json", quality)
    write_json(output / "skill_reverse_fusion_manifest.json", manifest)
    write_jsonl(fused / "eval_cases.jsonl", [{"case_id": "fusion_case_1", "query": "Answer within fused skill scope.", "expected_behavior": "grounded_answer"}])
    (output / "skill_reverse_fusion_report.md").write_text(_report(fused_name, quality), encoding="utf-8")
    return manifest


def _reverse_skill(skill: Path) -> dict:
    text = _read_text(skill / "SKILL.md")
    boundary = _read_text(skill / "boundary_rules.md")
    evidence = _read_text(skill / "evidence_policy.md")
    return {
        "skill_path": str(skill).replace("\\", "/"),
        "skill_name": _name(text, skill.name),
        "capabilities": _lines_matching(text, ["use", "answer", "generate", "retrieve", "provide"])[:12],
        "boundary_rules": _lines_matching(boundary + "\n" + text, ["do not", "must not", "refuse", "outside", "boundary"])[:12],
        "evidence_policies": _lines_matching(evidence + "\n" + text, ["evidence", "citation", "source", "grounded"])[:12],
    }


def _skill_md(name: str, plan: dict) -> str:
    return "\n".join(
        [
            f"# {name}",
            "",
            "Use this fused Skill when the task matches one of the merged capabilities.",
            "",
            "## Capabilities",
            "",
            _bullets(plan["capabilities"] or ["answer with evidence"]),
            "",
            "## Boundary",
            "",
            "Follow `boundary_rules.md` and `evidence_policy.md`.",
            "",
        ]
    )


def _report(name: str, quality: dict) -> str:
    return f"# Skill Reverse Fusion Report\n\n- Fused Skill: {name}\n- Status: {quality['status']}\n- Source Skills: {quality['source_skill_count']}\n"


def _read_text(path: Path) -> str:
    if not path.exists():
        return ""
    return path.read_text(encoding="utf-8", errors="ignore")


def _name(text: str, fallback: str) -> str:
    for line in text.splitlines():
        clean = line.strip("# ").strip()
        if clean:
            return clean
    return fallback


def _lines_matching(text: str, needles: list[str]) -> list[str]:
    lines = [line.strip("-*# ") for line in text.splitlines() if line.strip()]
    return [line for line in lines if any(needle in line.lower() for needle in needles)]


def _bullets(values: list[str]) -> str:
    normalized = [re.sub(r"\s+", " ", value).strip() for value in values]
    return "\n".join(f"- {value}" for value in normalized) or "- generic"
