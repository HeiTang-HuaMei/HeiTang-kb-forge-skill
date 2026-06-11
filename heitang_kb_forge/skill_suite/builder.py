from __future__ import annotations

import json
import re
from pathlib import Path

from heitang_kb_forge.exporters.jsonl_exporter import write_json
from heitang_kb_forge.schemas.skill_suite_schema import (
    DependencyEdge,
    SkillCandidatePlan,
    SkillSuiteManifest,
    SuiteSkill,
)


SKILL_SUITE_OUTPUT_FILES = [
    "suite.json",
    "SKILL_INDEX.md",
    "ROUTING.md",
    "METHODOLOGY_MAP.md",
    "SOURCE_TRACE.md",
    "DEPENDENCY_GRAPH.json",
    "SKILL_HIERARCHY.json",
    "hierarchy_analysis.json",
]


def build_skill_suite(plan: Path, output: Path) -> dict:
    candidate_plan = SkillCandidatePlan.model_validate(
        _read_json(plan / "skill_candidates.json")
    )
    candidates = candidate_plan.candidates
    _validate_candidate_ids([candidate.candidate_id for candidate in candidates])
    candidate_ids = {candidate.candidate_id for candidate in candidates}
    missing_dependencies = sorted(
        {
            dependency
            for candidate in candidates
            for dependency in candidate.dependency_draft
            if dependency not in candidate_ids
        }
    )
    if missing_dependencies:
        raise ValueError(
            f"Skill Suite contains missing dependencies: {', '.join(missing_dependencies)}"
        )
    if _has_cycle(
        {
            candidate.candidate_id: candidate.dependency_draft
            for candidate in candidates
        }
    ):
        raise ValueError("Skill Suite dependency draft contains a cycle")

    output.mkdir(parents=True, exist_ok=True)
    skills = []
    for candidate in candidates:
        skill_type = candidate.provisional_skill_type
        skill_path = (
            Path("skills") / skill_type / candidate.candidate_id / "SKILL.md"
        )
        absolute_path = output / skill_path
        absolute_path.parent.mkdir(parents=True, exist_ok=True)
        absolute_path.write_text(_render_skill(candidate), encoding="utf-8")
        skills.append(
            SuiteSkill(
                skill_id=candidate.candidate_id,
                title=candidate.title,
                skill_type=skill_type,
                path=skill_path.as_posix(),
                trigger=candidate.skill_contract.trigger,
                purpose=candidate.skill_contract.purpose,
                depends_on=candidate.dependency_draft,
                supporting_evidence=candidate.supporting_evidence,
                confidence=candidate.confidence,
                status=candidate.status,
            )
        )

    duplicate_groups = _duplicate_groups(skills)
    conflict_pairs = _conflict_pairs(skills)
    edges = [
        DependencyEdge(source=skill.skill_id, target=dependency)
        for skill in skills
        for dependency in skill.depends_on
    ]
    hierarchy_counts = {
        skill_type: len([skill for skill in skills if skill.skill_type == skill_type])
        for skill_type in ("planning", "functional", "atomic")
    }
    suite = SkillSuiteManifest(
        suite_id=f"suite_{_slug(candidate_plan.source_package_id)}",
        source_package_id=candidate_plan.source_package_id,
        skill_count=len(skills),
        hierarchy_counts=hierarchy_counts,
        skills=skills,
        dependency_edges=edges,
        duplicate_skill_groups=duplicate_groups,
        conflict_skill_pairs=conflict_pairs,
        status=(
            "review_required"
            if duplicate_groups
            or conflict_pairs
            or any(skill.status != "ready" for skill in skills)
            else "ready"
        ),
        skillx_integration={
            "integration_level": "L3_contract_absorbed+L4_capability_fused",
            "runtime_integration": "none",
            "trajectory_mining": False,
            "self_evolving_skills": False,
        },
    )
    hierarchy = {
        "skill_hierarchy_version": "v4.2-p2.2-1",
        "planning": [skill.skill_id for skill in skills if skill.skill_type == "planning"],
        "functional": [
            skill.skill_id for skill in skills if skill.skill_type == "functional"
        ],
        "atomic": [skill.skill_id for skill in skills if skill.skill_type == "atomic"],
        "classification_source": "Slice 5 evidence-backed candidate plan",
        "tests_require_real_llm_api_network": False,
    }
    graph = {
        "dependency_graph_version": "v4.2-p2.2-1",
        "nodes": [
            {
                "skill_id": skill.skill_id,
                "skill_type": skill.skill_type,
                "path": skill.path,
            }
            for skill in skills
        ],
        "edges": [edge.model_dump(mode="json") for edge in edges],
        "missing_dependencies": [],
        "cycle_detected": False,
        "tests_require_real_llm_api_network": False,
    }
    analysis = {
        "hierarchy_analysis_version": "v4.2-p2.2-1",
        "duplicate_skill_groups": duplicate_groups,
        "conflict_skill_pairs": conflict_pairs,
        "missing_dependencies": [],
        "cycle_detected": False,
        "merge_split_recommendations": [
            {
                "candidate_id": candidate.candidate_id,
                **candidate.merge_split_recommendation.model_dump(mode="json"),
            }
            for candidate in candidates
        ],
        "tests_require_real_llm_api_network": False,
    }

    write_json(output / "suite.json", suite)
    write_json(output / "SKILL_HIERARCHY.json", hierarchy)
    write_json(output / "DEPENDENCY_GRAPH.json", graph)
    write_json(output / "hierarchy_analysis.json", analysis)
    (output / "SKILL_INDEX.md").write_text(
        _render_skill_index(suite), encoding="utf-8"
    )
    (output / "ROUTING.md").write_text(_render_routing(suite), encoding="utf-8")
    (output / "METHODOLOGY_MAP.md").write_text(
        _render_methodology_trace(candidate_plan), encoding="utf-8"
    )
    (output / "SOURCE_TRACE.md").write_text(
        _render_source_trace(suite), encoding="utf-8"
    )
    return suite.model_dump(mode="json")


def _render_skill(candidate) -> str:
    contract = candidate.skill_contract
    lines = [
        "---",
        f"name: {json.dumps(candidate.title, ensure_ascii=False)}",
        f"description: {json.dumps(contract.purpose, ensure_ascii=False)}",
        f"skill_type: {candidate.provisional_skill_type}",
        "---",
        "",
        f"# {candidate.title}",
        "",
        "## Purpose",
        "",
        contract.purpose,
        "",
        "## Trigger",
        "",
        contract.trigger,
        "",
        "## Workflow",
        "",
    ]
    lines.extend(
        f"{index}. {step}" for index, step in enumerate(contract.workflow_steps, start=1)
    )
    lines.extend(
        [
            "",
            "## Evidence",
            "",
            *[f"- `{item}`" for item in candidate.supporting_evidence],
            "",
            "## Constraints",
            "",
        ]
    )
    lines.extend(
        [f"- {item}" for item in contract.constraints]
        or ["- Stay within source-traced methodology evidence."]
    )
    return "\n".join(lines).rstrip() + "\n"


def _render_skill_index(suite: SkillSuiteManifest) -> str:
    lines = [
        "# Skill Index",
        "",
        f"- Suite: `{suite.suite_id}`",
        f"- Status: {suite.status}",
        f"- Skills: {suite.skill_count}",
        "",
        "| Skill | Type | Status | Path |",
        "| --- | --- | --- | --- |",
    ]
    lines.extend(
        f"| {skill.title} | {skill.skill_type} | {skill.status} | `{skill.path}` |"
        for skill in suite.skills
    )
    return "\n".join(lines).rstrip() + "\n"


def _render_routing(suite: SkillSuiteManifest) -> str:
    lines = [
        "# Routing Rules",
        "",
        "Routing is evaluated from Planning to Functional to Atomic Skills.",
        "",
    ]
    for skill_type in ("planning", "functional", "atomic"):
        lines.extend([f"## {skill_type.title()} Skills", ""])
        rows = [skill for skill in suite.skills if skill.skill_type == skill_type]
        lines.extend(
            f"- `{skill.skill_id}`: {skill.trigger} -> `{skill.path}`" for skill in rows
        )
        if not rows:
            lines.append("- No evidence-supported Skill in this category.")
        lines.append("")
    return "\n".join(lines).rstrip() + "\n"


def _render_methodology_trace(plan: SkillCandidatePlan) -> str:
    lines = [
        "# Methodology to Skill Trace",
        "",
        f"- Source methodology version: `{plan.source_methodology_version}`",
        f"- Source package: `{plan.source_package_id}`",
        "",
    ]
    lines.extend(
        f"- `{candidate.source_methodology_module}` -> `{candidate.candidate_id}`"
        for candidate in plan.candidates
    )
    return "\n".join(lines).rstrip() + "\n"


def _render_source_trace(suite: SkillSuiteManifest) -> str:
    lines = ["# Source Trace", ""]
    for skill in suite.skills:
        lines.extend(
            [
                f"## {skill.title}",
                "",
                f"- Skill ID: `{skill.skill_id}`",
                f"- Evidence: {', '.join(f'`{item}`' for item in skill.supporting_evidence)}",
                "",
            ]
        )
    return "\n".join(lines).rstrip() + "\n"


def _duplicate_groups(skills: list[SuiteSkill]) -> list[list[str]]:
    by_title: dict[str, list[str]] = {}
    for skill in skills:
        key = re.sub(r"[^a-z0-9]+", "", skill.title.casefold())
        by_title.setdefault(key, []).append(skill.skill_id)
    return [ids for ids in by_title.values() if len(ids) > 1]


def _conflict_pairs(skills: list[SuiteSkill]) -> list[list[str]]:
    conflicts = []
    for index, left in enumerate(skills):
        for right in skills[index + 1 :]:
            if (
                _normalize(left.trigger) == _normalize(right.trigger)
                and _normalize(left.purpose) != _normalize(right.purpose)
            ):
                conflicts.append([left.skill_id, right.skill_id])
    return conflicts


def _validate_candidate_ids(candidate_ids: list[str]) -> None:
    if len(candidate_ids) != len(set(candidate_ids)):
        raise ValueError("Skill Suite candidate IDs must be unique")
    invalid = [
        candidate_id
        for candidate_id in candidate_ids
        if re.fullmatch(r"[a-z0-9][a-z0-9_-]*", candidate_id) is None
    ]
    if invalid:
        raise ValueError(
            f"Skill Suite candidate IDs contain unsafe path values: {', '.join(invalid)}"
        )


def _has_cycle(graph: dict[str, list[str]]) -> bool:
    visiting = set()
    visited = set()

    def visit(node: str) -> bool:
        if node in visiting:
            return True
        if node in visited:
            return False
        visiting.add(node)
        if any(visit(dependency) for dependency in graph.get(node, [])):
            return True
        visiting.remove(node)
        visited.add(node)
        return False

    return any(visit(node) for node in graph)


def _normalize(value: str) -> str:
    return re.sub(r"\s+", " ", value.casefold()).strip()


def _slug(value: str) -> str:
    slug = re.sub(r"[^a-z0-9]+", "-", value.casefold()).strip("-")
    return slug or "skill-suite"


def _read_json(path: Path) -> dict:
    if not path.exists():
        raise FileNotFoundError(f"Skill candidate plan not found: {path}")
    payload = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(payload, dict):
        raise ValueError("skill_candidates.json must contain an object")
    return payload
