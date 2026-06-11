from __future__ import annotations

import hashlib
import json
from pathlib import Path

from heitang_kb_forge.exporters.jsonl_exporter import write_json
from heitang_kb_forge.schemas.skill_suite_schema import SkillSuiteManifest
from heitang_kb_forge.skill_suite.packaging import (
    REQUIRED_SUITE_FILES,
    inspect_skill_markdown,
    safe_skill_path,
)


SUITE_VALIDATION_OUTPUT_FILES = [
    "suite_validation_report.json",
    "VALIDATION_REPORT.md",
]
SUITE_DIFF_OUTPUT_FILES = ["skill_suite_diff_report.json", "DIFF_REPORT.md"]
SUITE_INSTALLABILITY_OUTPUT_FILES = [
    "skill_suite_installability_report.json",
    "INSTALLABILITY_REPORT.md",
]
SUITE_GOVERNANCE_OUTPUT_FILES = [
    "skill_suite_governance_report.json",
    "GOVERNANCE_REPORT.md",
]


def validate_skill_suite(suite: Path, output: Path | None = None) -> dict:
    target = output or suite
    manifest = SkillSuiteManifest.model_validate(_read_json(suite / "suite.json"))
    blockers = []
    warnings = []
    missing_files = [
        name for name in REQUIRED_SUITE_FILES if not (suite / name).is_file()
    ]
    blockers.extend(f"missing_required_file:{name}" for name in missing_files)

    expected_skill_ids = {skill.skill_id for skill in manifest.skills}
    actual_hierarchy_counts = {
        skill_type: len(
            [skill for skill in manifest.skills if skill.skill_type == skill_type]
        )
        for skill_type in ("planning", "functional", "atomic")
    }
    if manifest.skill_count != len(manifest.skills):
        blockers.append("skill_count_manifest_mismatch")
    if manifest.hierarchy_counts != actual_hierarchy_counts:
        blockers.append("hierarchy_count_manifest_mismatch")
    expected_edges = {
        (skill.skill_id, dependency)
        for skill in manifest.skills
        for dependency in skill.depends_on
    }
    graph_from_manifest = {
        skill.skill_id: skill.depends_on for skill in manifest.skills
    }
    if _has_cycle(graph_from_manifest):
        blockers.append("dependency_cycle")
    if any(
        dependency not in expected_skill_ids
        for dependencies in graph_from_manifest.values()
        for dependency in dependencies
    ):
        blockers.append("missing_dependency")

    routing_text = (
        (suite / "ROUTING.md").read_text(encoding="utf-8")
        if (suite / "ROUTING.md").is_file()
        else ""
    )
    quality_rows = []
    for skill in manifest.skills:
        try:
            relative = safe_skill_path(skill.path)
        except ValueError as exc:
            blockers.append(str(exc))
            continue
        path = suite / relative
        if not path.is_file() or path.is_symlink():
            blockers.append(f"missing_skill_file:{skill.path}")
            continue
        quality = inspect_skill_markdown(
            path,
            skill.path,
            expected_name=skill.title,
            expected_skill_type=skill.skill_type,
        )
        quality_rows.append(quality)
        blockers.extend(quality["blockers"])
        if skill.skill_id not in routing_text or skill.path not in routing_text:
            blockers.append(f"routing_missing_skill:{skill.skill_id}")
        if not skill.supporting_evidence:
            blockers.append(f"missing_supporting_evidence:{skill.skill_id}")

    hierarchy = _read_optional_json(suite / "SKILL_HIERARCHY.json")
    hierarchy_ids = {
        str(item)
        for category in ("planning", "functional", "atomic")
        for item in hierarchy.get(category, [])
    }
    if hierarchy_ids != expected_skill_ids:
        blockers.append("hierarchy_manifest_mismatch")

    graph = _read_optional_json(suite / "DEPENDENCY_GRAPH.json")
    graph_ids = {
        str(item.get("skill_id"))
        for item in graph.get("nodes", [])
        if isinstance(item, dict)
    }
    graph_edges = {
        (str(item.get("source")), str(item.get("target")))
        for item in graph.get("edges", [])
        if isinstance(item, dict)
    }
    if graph_ids != expected_skill_ids:
        blockers.append("dependency_graph_node_mismatch")
    if graph_edges != expected_edges:
        blockers.append("dependency_graph_edge_mismatch")

    if manifest.duplicate_skill_groups:
        blockers.append("duplicate_skills_present")
    if manifest.conflict_skill_pairs:
        blockers.append("conflicting_skills_present")
    if any(skill.status != "ready" for skill in manifest.skills):
        blockers.append("review_required_skill_present")
    if manifest.status != "ready":
        blockers.append("suite_status_not_ready")
    if (
        manifest.skillx_integration.get("runtime_integration") != "none"
        or manifest.skillx_integration.get("trajectory_mining") is not False
        or manifest.skillx_integration.get("self_evolving_skills") is not False
    ):
        blockers.append("external_runtime_boundary_violation")

    blockers = sorted(set(blockers))
    result = {
        "suite_validation_version": "v4.2-p2.2-1",
        "suite_id": manifest.suite_id,
        "status": "pass" if not blockers else "fail",
        "release_ready": not blockers,
        "checks": {
            "required_files": {
                "status": "pass" if not missing_files else "fail",
                "missing": missing_files,
            },
            "skill_markdown_quality": {
                "status": "pass"
                if all(row["status"] == "pass" for row in quality_rows)
                and len(quality_rows) == manifest.skill_count
                else "fail",
                "skills": quality_rows,
            },
            "hierarchy": {
                "status": "pass"
                if hierarchy_ids == expected_skill_ids
                else "fail"
            },
            "routing": {
                "status": "pass"
                if not any(item.startswith("routing_missing_skill:") for item in blockers)
                else "fail"
            },
            "dependency_graph": {
                "status": "pass"
                if graph_ids == expected_skill_ids
                and graph_edges == expected_edges
                and not _has_cycle(graph_from_manifest)
                else "fail"
            },
            "duplicates_conflicts": {
                "status": "pass"
                if not manifest.duplicate_skill_groups
                and not manifest.conflict_skill_pairs
                else "fail"
            },
            "evidence_trace": {
                "status": "pass"
                if all(skill.supporting_evidence for skill in manifest.skills)
                else "fail"
            },
            "runtime_boundary": {
                "status": "pass"
                if "external_runtime_boundary_violation" not in blockers
                else "fail",
                "external_runtime_required": False,
                "provider_api_required": False,
            },
        },
        "blockers": blockers,
        "warnings": warnings,
        "tests_require_real_llm_api_network": False,
    }
    target.mkdir(parents=True, exist_ok=True)
    write_json(target / "suite_validation_report.json", result)
    (target / "VALIDATION_REPORT.md").write_text(
        _render_validation(result), encoding="utf-8"
    )
    return result


def check_skill_suite_installability(
    suite: Path,
    output: Path | None = None,
    *,
    validation: dict | None = None,
) -> dict:
    target = output or suite
    validation_result = validation or validate_skill_suite(suite, target)
    manifest = SkillSuiteManifest.model_validate(_read_json(suite / "suite.json"))
    blockers = list(validation_result["blockers"])
    for skill in manifest.skills:
        try:
            relative = safe_skill_path(skill.path)
        except ValueError:
            blockers.append(f"unsafe_skill_path:{skill.skill_id}")
            continue
        if not (suite / relative).is_file():
            blockers.append(f"skill_file_missing:{skill.skill_id}")
    blockers = sorted(set(blockers))
    result = {
        "skill_suite_installability_version": "v4.2-p2.2-1",
        "suite_id": manifest.suite_id,
        "status": "pass" if not blockers else "fail",
        "release_ready": not blockers,
        "validation_command": "heitang-kb-forge validate-skill-suite --suite .",
        "installability_command": "heitang-kb-forge check-skill-suite-installability --suite .",
        "install_mode": "copy_or_extract_local_skill_pack",
        "supported_targets": ["generic_local_skill_pack"],
        "target_specific_runtime_validation": "not_claimed",
        "local_first": True,
        "external_runtime_required": False,
        "provider_api_required": False,
        "blockers": blockers,
        "tests_require_real_llm_api_network": False,
    }
    target.mkdir(parents=True, exist_ok=True)
    write_json(target / "skill_suite_installability_report.json", result)
    (target / "INSTALLABILITY_REPORT.md").write_text(
        _render_installability(result), encoding="utf-8"
    )
    return result


def diff_skill_suites(before: Path, after: Path, output: Path) -> dict:
    before_manifest = SkillSuiteManifest.model_validate(
        _read_json(before / "suite.json")
    )
    after_manifest = SkillSuiteManifest.model_validate(_read_json(after / "suite.json"))
    before_skills = {skill.skill_id: skill for skill in before_manifest.skills}
    after_skills = {skill.skill_id: skill for skill in after_manifest.skills}
    added = sorted(set(after_skills) - set(before_skills))
    removed = sorted(set(before_skills) - set(after_skills))
    changed = []
    for skill_id in sorted(set(before_skills) & set(after_skills)):
        left = before_skills[skill_id]
        right = after_skills[skill_id]
        changed_fields = [
            field
            for field in (
                "title",
                "skill_type",
                "trigger",
                "purpose",
                "depends_on",
                "supporting_evidence",
                "confidence",
                "status",
            )
            if getattr(left, field) != getattr(right, field)
        ]
        if _skill_hash(before, left.path) != _skill_hash(after, right.path):
            changed_fields.append("SKILL.md")
        if changed_fields:
            changed.append({"skill_id": skill_id, "changed_fields": changed_fields})
    result = {
        "skill_suite_diff_version": "v4.2-p2.2-1",
        "status": "pass",
        "baseline_provided": True,
        "before_suite_id": before_manifest.suite_id,
        "after_suite_id": after_manifest.suite_id,
        "added_skill_ids": added,
        "removed_skill_ids": removed,
        "changed_skills": changed,
        "routing_changed": _sha256(before / "ROUTING.md")
        != _sha256(after / "ROUTING.md"),
        "dependency_graph_changed": _sha256(before / "DEPENDENCY_GRAPH.json")
        != _sha256(after / "DEPENDENCY_GRAPH.json"),
        "tests_require_real_llm_api_network": False,
    }
    output.mkdir(parents=True, exist_ok=True)
    write_json(output / "skill_suite_diff_report.json", result)
    (output / "DIFF_REPORT.md").write_text(_render_diff(result), encoding="utf-8")
    return result


def run_skill_suite_governance(
    suite: Path,
    output: Path | None = None,
    old_suite: Path | None = None,
) -> dict:
    target = output or suite
    validation = validate_skill_suite(suite, target)
    installability = check_skill_suite_installability(
        suite, target, validation=validation
    )
    diff = (
        diff_skill_suites(old_suite, suite, target)
        if old_suite is not None
        else {
            "status": "not_run",
            "baseline_provided": False,
            "added_skill_ids": [],
            "removed_skill_ids": [],
            "changed_skills": [],
        }
    )
    baseline_provided = diff["baseline_provided"] is True
    release_ready = (
        validation["release_ready"] is True
        and installability["release_ready"] is True
        and baseline_provided
    )
    warnings = [] if baseline_provided else ["diff_baseline_not_provided"]
    result = {
        "skill_suite_governance_version": "v4.2-p2.2-1",
        "suite_id": validation["suite_id"],
        "status": "pass"
        if release_ready
        else "fail"
        if validation["status"] == "fail" or installability["status"] == "fail"
        else "review_required",
        "release_ready": release_ready,
        "checks": {
            "validation": {
                "status": validation["status"],
                "release_ready": validation["release_ready"],
            },
            "diff_comparison": {
                "status": diff["status"],
                "baseline_provided": baseline_provided,
                "added_skill_count": len(diff["added_skill_ids"]),
                "removed_skill_count": len(diff["removed_skill_ids"]),
                "changed_skill_count": len(diff["changed_skills"]),
            },
            "installability": {
                "status": installability["status"],
                "release_ready": installability["release_ready"],
            },
            "runtime_boundary": {
                "status": "pass",
                "local_first": True,
                "external_runtime_required": False,
                "provider_api_required": False,
            },
        },
        "warnings": warnings,
        "tests_require_real_llm_api_network": False,
    }
    write_json(target / "skill_suite_governance_report.json", result)
    (target / "GOVERNANCE_REPORT.md").write_text(
        _render_governance(result), encoding="utf-8"
    )
    return result


def _read_json(path: Path) -> dict:
    if not path.exists():
        raise FileNotFoundError(f"Required suite evidence not found: {path}")
    payload = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(payload, dict):
        raise ValueError(f"{path.name} must contain an object")
    return payload


def _read_optional_json(path: Path) -> dict:
    try:
        return _read_json(path)
    except (FileNotFoundError, ValueError, json.JSONDecodeError):
        return {}


def _sha256(path: Path) -> str:
    if not path.is_file():
        return "missing"
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(65536), b""):
            digest.update(block)
    return digest.hexdigest()


def _skill_hash(root: Path, value: str) -> str:
    return _sha256(root / safe_skill_path(value))


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


def _render_validation(result: dict) -> str:
    return f"""# Skill Suite Validation Report

- Suite: `{result['suite_id']}`
- Status: `{result['status']}`
- Release ready: `{str(result['release_ready']).lower()}`
- Blockers: {', '.join(result['blockers']) if result['blockers'] else 'none'}
"""


def _render_installability(result: dict) -> str:
    return f"""# Skill Suite Installability Report

- Suite: `{result['suite_id']}`
- Status: `{result['status']}`
- Release ready: `{str(result['release_ready']).lower()}`
- Install mode: `{result['install_mode']}`
- External runtime required: `false`
- Provider API required: `false`
"""


def _render_diff(result: dict) -> str:
    return f"""# Skill Suite Diff Report

- Status: `{result['status']}`
- Added: {', '.join(result['added_skill_ids']) if result['added_skill_ids'] else 'none'}
- Removed: {', '.join(result['removed_skill_ids']) if result['removed_skill_ids'] else 'none'}
- Changed: {', '.join(item['skill_id'] for item in result['changed_skills']) if result['changed_skills'] else 'none'}
- Routing changed: `{str(result['routing_changed']).lower()}`
- Dependency graph changed: `{str(result['dependency_graph_changed']).lower()}`
"""


def _render_governance(result: dict) -> str:
    return f"""# Skill Suite Governance Report

- Suite: `{result['suite_id']}`
- Status: `{result['status']}`
- Release ready: `{str(result['release_ready']).lower()}`
- Validation: `{result['checks']['validation']['status']}`
- Diff baseline: `{str(result['checks']['diff_comparison']['baseline_provided']).lower()}`
- Installability: `{result['checks']['installability']['status']}`
- Warnings: {', '.join(result['warnings']) if result['warnings'] else 'none'}
"""
