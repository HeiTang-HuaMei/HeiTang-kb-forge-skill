from __future__ import annotations

import hashlib
import json
import re
import shutil
from pathlib import Path

import yaml

from heitang_kb_forge.exporters.jsonl_exporter import write_json
from heitang_kb_forge.schemas.skill_suite_schema import (
    SkillPackManifest,
    SkillSuiteManifest,
)


SKILL_PACK_OUTPUT_FILES = [
    "skill_pack_manifest.json",
    "description_trigger_quality_report.json",
    "allowed_files_boundary_report.json",
    "skill_eval_checklist.md",
    "skill_optimization_notes.md",
    "PACK_README.md",
]

REQUIRED_SUITE_FILES = [
    "suite.json",
    "SKILL_INDEX.md",
    "ROUTING.md",
    "METHODOLOGY_MAP.md",
    "SOURCE_TRACE.md",
    "DEPENDENCY_GRAPH.json",
    "SKILL_HIERARCHY.json",
    "hierarchy_analysis.json",
]
OPTIONAL_SUITE_REPORT_FILES = [
    "suite_validation_report.json",
    "VALIDATION_REPORT.md",
    "skill_suite_diff_report.json",
    "DIFF_REPORT.md",
    "skill_suite_installability_report.json",
    "INSTALLABILITY_REPORT.md",
    "skill_suite_governance_report.json",
    "GOVERNANCE_REPORT.md",
]
_GENERIC_DESCRIPTION_MARKERS = {"todo", "tbd", "skill description", "placeholder"}


def export_skill_pack(suite: Path, output: Path) -> dict:
    suite_root = suite.resolve()
    output_root = output.resolve()
    if output_root == suite_root or suite_root in output_root.parents:
        raise ValueError("Skill Pack output must be outside the source suite directory")
    if output.exists() and not output.is_dir():
        raise ValueError("Skill Pack output path must be a directory")
    if output.exists() and any(output.iterdir()):
        raise ValueError("Skill Pack output directory must be empty")

    suite_manifest = SkillSuiteManifest.model_validate(
        _read_json(suite / "suite.json")
    )
    skill_paths = [safe_skill_path(skill.path) for skill in suite_manifest.skills]
    allowed_files = [Path(item) for item in REQUIRED_SUITE_FILES] + skill_paths
    allowed_files.extend(
        Path(item) for item in OPTIONAL_SUITE_REPORT_FILES if (suite / item).is_file()
    )
    missing_files = [
        path.as_posix()
        for path in allowed_files
        if not (suite / path).is_file() or (suite / path).is_symlink()
    ]
    if missing_files:
        raise ValueError(
            f"Skill Pack source is missing required regular files: {', '.join(missing_files)}"
        )

    quality_rows = [
        inspect_skill_markdown(
            suite / path,
            path.as_posix(),
            expected_name=skill.title,
            expected_skill_type=skill.skill_type,
        )
        for skill, path in zip(suite_manifest.skills, skill_paths, strict=True)
    ]
    quality_blockers = [
        blocker
        for row in quality_rows
        for blocker in row["blockers"]
    ]
    if quality_blockers:
        raise ValueError(
            f"Skill Pack description/trigger quality failed: {', '.join(quality_blockers)}"
        )

    source_files = {
        path.relative_to(suite).as_posix()
        for path in suite.rglob("*")
        if path.is_file() and not path.is_symlink()
    }
    allowed_set = {path.as_posix() for path in allowed_files}
    excluded_files = sorted(source_files - allowed_set)

    output.mkdir(parents=True, exist_ok=True)
    copied_files = []
    file_hashes = {}
    for relative in allowed_files:
        source = suite / relative
        target = output / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, target)
        name = relative.as_posix()
        copied_files.append(name)
        file_hashes[name] = _sha256(target)

    quality_report = {
        "description_trigger_quality_version": "v4.2-p2.2-1",
        "status": "pass",
        "skills": quality_rows,
        "tests_require_real_llm_api_network": False,
    }
    boundary_report = {
        "allowed_files_boundary_version": "v4.2-p2.2-1",
        "status": "pass",
        "allowed_files": sorted(allowed_set),
        "excluded_files": excluded_files,
        "symlinks_allowed": False,
        "arbitrary_source_files_copied": False,
        "tests_require_real_llm_api_network": False,
    }
    validation_status = _gate_status(suite / "suite_validation_report.json")
    installability_status = _gate_status(
        suite / "skill_suite_installability_report.json"
    )
    governance_status = _governance_status(
        suite / "skill_suite_governance_report.json"
    )
    pack_status = (
        "ready"
        if suite_manifest.status == "ready"
        and validation_status == "pass"
        and installability_status == "pass"
        and governance_status == "pass"
        else "review_required"
        if suite_manifest.status != "ready"
        or "fail"
        in {validation_status, installability_status, governance_status}
        else "packaging_ready"
    )
    write_json(output / "description_trigger_quality_report.json", quality_report)
    write_json(output / "allowed_files_boundary_report.json", boundary_report)
    (output / "skill_eval_checklist.md").write_text(
        _render_eval_checklist(
            suite_manifest,
            validation_status,
            installability_status,
            governance_status,
        ),
        encoding="utf-8",
    )
    (output / "skill_optimization_notes.md").write_text(
        _render_optimization_notes(suite_manifest), encoding="utf-8"
    )
    (output / "PACK_README.md").write_text(
        _render_pack_readme(
            suite_manifest.suite_id,
            pack_status,
            validation_status,
            installability_status,
            governance_status,
        ),
        encoding="utf-8",
    )
    generated_payload_files = [
        item for item in SKILL_PACK_OUTPUT_FILES if item != "skill_pack_manifest.json"
    ]
    for name in generated_payload_files:
        file_hashes[name] = _sha256(output / name)
    pack_manifest = SkillPackManifest(
        suite_id=suite_manifest.suite_id,
        status=pack_status,
        files=sorted(copied_files + generated_payload_files),
        file_hashes=file_hashes,
        description_trigger_quality_status="pass",
        allowed_files_boundary_status="pass",
        suite_validation_status=validation_status,
        installability_check_status=installability_status,
        suite_governance_status=governance_status,
        anthropic_skill_creator_integration={
            "integration_level": "L3_contract_absorbed+partial_L4_packaging_governance_fused",
            "anthropic_platform_binding": False,
            "claude_skills_runtime": False,
            "account_or_upload_required": False,
            "provider_api_required": False,
        },
    )
    write_json(output / "skill_pack_manifest.json", pack_manifest)
    return pack_manifest.model_dump(mode="json")


def inspect_skill_markdown(
    path: Path,
    relative_path: str,
    *,
    expected_name: str,
    expected_skill_type: str,
) -> dict:
    text = path.read_text(encoding="utf-8")
    frontmatter, body = _parse_frontmatter(text)
    name = str(frontmatter.get("name") or "").strip()
    description = str(frontmatter.get("description") or "").strip()
    skill_type = str(frontmatter.get("skill_type") or "").strip()
    trigger = _section(body, "Trigger")
    blockers = []
    if not name:
        blockers.append(f"{relative_path}:missing_name")
    elif name != expected_name:
        blockers.append(f"{relative_path}:name_manifest_mismatch")
    if len(description) < 24:
        blockers.append(f"{relative_path}:description_too_short")
    if any(marker in description.casefold() for marker in _GENERIC_DESCRIPTION_MARKERS):
        blockers.append(f"{relative_path}:generic_description")
    if len(trigger) < 8:
        blockers.append(f"{relative_path}:trigger_too_short")
    if skill_type != expected_skill_type:
        blockers.append(f"{relative_path}:skill_type_manifest_mismatch")
    return {
        "path": relative_path,
        "name": name,
        "description": description,
        "skill_type": skill_type,
        "trigger": trigger,
        "status": "pass" if not blockers else "fail",
        "blockers": blockers,
    }


def _parse_frontmatter(text: str) -> tuple[dict, str]:
    match = re.match(r"\A---\s*\n(.*?)\n---\s*\n?(.*)\Z", text, flags=re.DOTALL)
    if not match:
        return {}, text
    payload = yaml.safe_load(match.group(1))
    return (payload if isinstance(payload, dict) else {}), match.group(2)


def _section(body: str, heading: str) -> str:
    match = re.search(
        rf"^##\s+{re.escape(heading)}\s*$\n(.*?)(?=^##\s+|\Z)",
        body,
        flags=re.MULTILINE | re.DOTALL,
    )
    return re.sub(r"\s+", " ", match.group(1)).strip() if match else ""


def safe_skill_path(value: str) -> Path:
    path = Path(value)
    if path.is_absolute() or ".." in path.parts or path.as_posix() != value.replace("\\", "/"):
        raise ValueError(f"Skill Pack contains unsafe manifest path: {value}")
    if not re.fullmatch(r"skills/(planning|functional|atomic)/[a-z0-9][a-z0-9_-]*/SKILL\.md", path.as_posix()):
        raise ValueError(f"Skill Pack contains unsupported Skill path: {value}")
    return path


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(65536), b""):
            digest.update(block)
    return digest.hexdigest()


def _read_json(path: Path) -> dict:
    if not path.exists():
        raise FileNotFoundError(f"Skill Suite manifest not found: {path}")
    payload = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(payload, dict):
        raise ValueError("suite.json must contain an object")
    return payload


def _gate_status(path: Path) -> str:
    if not path.exists():
        return "deferred_to_slice_8"
    payload = _read_json(path)
    return "pass" if payload.get("status") == "pass" else "fail"


def _governance_status(path: Path) -> str:
    if not path.exists():
        return "deferred_to_slice_8"
    payload = _read_json(path)
    return (
        "pass"
        if payload.get("status") == "pass" and payload.get("release_ready") is True
        else "fail"
    )


def _render_eval_checklist(
    suite: SkillSuiteManifest,
    validation_status: str,
    installability_status: str,
    governance_status: str,
) -> str:
    validation_check = "x" if validation_status == "pass" else " "
    installability_check = "x" if installability_status == "pass" else " "
    governance_check = "x" if governance_status == "pass" else " "
    return f"""# Skill Evaluation Checklist

- [x] Suite manifest present: `{suite.suite_id}`
- [x] Skill hierarchy present
- [x] Routing rules present
- [x] Dependency graph present
- [x] Description and trigger quality checked
- [x] Allowed-files boundary checked
- [{validation_check}] Suite validation: {validation_status}
- [{installability_check}] Installability check: {installability_status}
- [{governance_check}] Suite governance: {governance_status}
"""


def _render_optimization_notes(suite: SkillSuiteManifest) -> str:
    review_count = len([skill for skill in suite.skills if skill.status != "ready"])
    return f"""# Skill Optimization Notes

- Suite: `{suite.suite_id}`
- Skill count: {suite.skill_count}
- Review-required skills: {review_count}
- Preserve evidence trace when changing descriptions, triggers, routing, or dependencies.
- Do not bind this pack to an external platform or runtime.
"""


def _render_pack_readme(
    suite_id: str,
    status: str,
    validation_status: str,
    installability_status: str,
    governance_status: str,
) -> str:
    return f"""# Skill Pack

- Suite: `{suite_id}`
- Packaging status: `{status}`
- Description/trigger quality: `pass`
- Allowed-files boundary: `pass`
- Suite validation: `{validation_status}`
- Installability: `{installability_status}`
- Suite governance: `{governance_status}`

This is a local-first Skill Pack. It does not require Anthropic platform binding,
Claude Skills runtime, an external account, or a provider API.
"""
