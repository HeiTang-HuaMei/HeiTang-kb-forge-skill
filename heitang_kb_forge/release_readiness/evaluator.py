from pathlib import Path
import json

from heitang_kb_forge.exporters.jsonl_exporter import write_json
from heitang_kb_forge.release_readiness.report import render_release_readiness_checklist, render_release_readiness_report
from heitang_kb_forge.schemas.release_readiness_schema import ReleaseReadinessResult

INPUT_FILES = {
    "quality_gate": "quality_gate_result.json",
    "release_blockers": "release_blockers.json",
    "regression": "regression_result.json",
    "golden_samples": "golden_sample_validation.json",
    "export_certification": "platform_export_certification.json",
    "compatibility_matrix": "compatibility_matrix.json",
}


def evaluate_release_readiness(workspace: Path, output: Path) -> ReleaseReadinessResult:
    output.mkdir(parents=True, exist_ok=True)
    inputs = {name: _status(output / file_name) for name, file_name in INPUT_FILES.items()}
    critical = []
    warnings = []
    for name, status in inputs.items():
        if status == "fail":
            critical.append(f"{name}_failed")
        elif status == "not_found":
            warnings.append(f"{name}_not_found")
        elif status == "warning":
            warnings.append(f"{name}_warning")
    critical.extend(_repo_gate_failures(workspace))
    doctor_status = _status(output / "doctor_result.json")
    if doctor_status == "not_found":
        doctor_status = _status(workspace / "tmp_doctor" / "doctor_result.json")
    if doctor_status == "fail":
        critical.append("doctor_failed")
    quickstart = workspace / "tmp_quickstart_output"
    if quickstart.exists() and not all((quickstart / name).exists() for name in ["manifest.json", "chunks.jsonl", "quality_report.json"]):
        critical.append("quickstart_output_missing")
    platform = workspace / "platform_distribution"
    if platform.exists() and not (platform / "mock_publish_result.json").exists() and not any(platform.glob("*/mock_publish_result.json")):
        critical.append("platform_export_lacks_mock_boundary")
    score = max(0, 100 - len(critical) * 20 - len(warnings) * 5)
    status = "fail" if critical else "warning" if warnings else "pass"
    result = ReleaseReadinessResult(
        status=status,
        release_ready=status == "pass",
        overall_score=score,
        inputs=inputs,
        critical_blockers=critical,
        warnings=warnings,
        next_actions=[
            "Resolve critical blockers before release.",
            "Use v2.6 opt-in LLM live smoke for provider evidence.",
            "Use v2.8 parser backend reliability evidence for parser-risk validation.",
            "Keep P1 final gate, external registry, and S/A contract inclusion evidence attached for v4.0.0 stable.",
        ],
    )
    write_json(output / "release_readiness_result.json", result)
    (output / "release_readiness_report.md").write_text(render_release_readiness_report(result), encoding="utf-8")
    (output / "release_readiness_checklist.md").write_text(render_release_readiness_checklist(result), encoding="utf-8")
    return result


def _status(path: Path) -> str:
    if not path.exists():
        return "not_found"
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return "fail"
    return payload.get("status", "pass")


def _repo_gate_failures(workspace: Path) -> list[str]:
    failures: list[str] = []
    expected = "4.0.0"
    if not _versions_aligned(workspace, expected):
        failures.append("version_mismatch")
    for name, path in {
        "capability_status_missing": workspace / "docs" / "CAPABILITY_STATUS.md",
        "version_matrix_missing": workspace / "docs" / "VERSION_MATRIX.md",
        "release_checklist_missing": workspace / "docs" / "RELEASE_CHECKLIST.md",
    }.items():
        if not path.exists():
            failures.append(name)
    readme = workspace / "README.md"
    if readme.exists():
        text = readme.read_text(encoding="utf-8", errors="ignore")
        bad_claims = ["v2.6 Completed", "v2.7 Completed", "v2.8 Completed", "v2.9 Completed", "production-ready", "official XHS upload API"]
        if any(claim in text for claim in bad_claims):
            failures.append("readme_planned_as_completed")
    if _suspected_secret(workspace):
        failures.append("suspected_secret_leak")
    if not (workspace / ".github" / "workflows" / "ci.yml").exists():
        failures.append("ci_workflow_missing")
    if not (workspace / ".github" / "workflows" / "release-check.yml").exists():
        failures.append("release_check_workflow_missing")
    legacy_cli = workspace / "heitang_kb_forge" / "cli_commands" / "legacy.py"
    if legacy_cli.exists() and legacy_cli.stat().st_size >= 10_000:
        failures.append("legacy_cli_oversized")
    return failures


def _versions_aligned(workspace: Path, expected: str) -> bool:
    versions = []
    pyproject = workspace / "pyproject.toml"
    skill_json = workspace / "skill.json"
    if pyproject.exists():
        for line in pyproject.read_text(encoding="utf-8").splitlines():
            if line.startswith("version = "):
                versions.append(line.split("=", 1)[1].strip().strip('"'))
                break
    if skill_json.exists():
        try:
            versions.append(json.loads(skill_json.read_text(encoding="utf-8")).get("version"))
        except json.JSONDecodeError:
            return False
    for path in [
        workspace / "README.md",
        workspace / "README.zh-CN.md",
        workspace / "docs" / "CAPABILITY_STATUS.md",
        workspace / "docs" / "CAPABILITY_STATUS.zh-CN.md",
        workspace / "docs" / "VERSION_MATRIX.md",
        workspace / "docs" / "VERSION_MATRIX.zh-CN.md",
        workspace / "docs" / "RELEASE_CHECKLIST.md",
        workspace / "docs" / "RELEASE_CHECKLIST.zh-CN.md",
    ]:
        if path.exists() and expected not in path.read_text(encoding="utf-8", errors="ignore"):
            return False
    return bool(versions) and all(version == expected for version in versions)


def _suspected_secret(workspace: Path) -> bool:
    patterns = ["api_key: sk-", "secret_key:", "client_secret:"]
    for path in workspace.rglob("*"):
        if ".git" in path.parts or not path.is_file() or path.suffix.lower() not in {".md", ".json", ".yaml", ".yml", ".txt"}:
            continue
        text = path.read_text(encoding="utf-8", errors="ignore")
        if any(pattern in text for pattern in patterns):
            return True
    return False

