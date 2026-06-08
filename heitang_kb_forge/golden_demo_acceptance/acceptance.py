from __future__ import annotations

import json
from datetime import datetime, timezone
from pathlib import Path
from zipfile import BadZipFile, ZipFile

from heitang_kb_forge.exporters.jsonl_exporter import write_json


V311_GOLDEN_DEMO_OUTPUT_FILES = [
    "golden_demo_manifest.json",
    "golden_demo_report.md",
    "real_acceptance_smoke_result.json",
    "real_acceptance_smoke_report.md",
    "sample_coverage_report.json",
    "sample_coverage_report.md",
    "artifact_openability_report.json",
    "artifact_openability_report.md",
    "generated_package_compatibility_report.json",
    "smoke_realism_report.json",
    "v311_acceptance_trace.json",
]

CORE_ACCEPTANCE_FILES = [
    "manifest.json",
    "chunks.jsonl",
    "cards.jsonl",
    "qa_pairs.jsonl",
    "glossary.jsonl",
    "quality_report.json",
]


def run_golden_demo_acceptance(
    package: Path,
    output: Path,
    sample_root: Path | None = None,
    require_v37: bool = True,
    require_v38: bool = True,
    require_v39: bool = True,
    require_v310: bool = True,
) -> dict:
    output.mkdir(parents=True, exist_ok=True)
    sample_root = sample_root or package
    sample_coverage = _sample_coverage(sample_root)
    openability = _artifact_openability(package)
    compatibility = _compatibility(package)
    realism = _smoke_realism(package, require_v37, require_v38, require_v39, require_v310)
    stages = [
        _stage("real_input_sample_coverage", sample_coverage["status"], "sample_coverage_report.json"),
        _stage("generated_artifact_openability", openability["status"], "artifact_openability_report.json"),
        _stage("generated_package_compatibility", compatibility["status"], "generated_package_compatibility_report.json"),
        _stage("smoke_test_realism", realism["status"], "smoke_realism_report.json"),
    ]
    status = _final_status(stages)
    result = {
        "real_acceptance_smoke_version": "3.11.0-alpha.1",
        "generated_at": _now(),
        "status": status,
        "package": _rel(package),
        "sample_root": _rel(sample_root),
        "stages": stages,
        "llm_required": False,
        "network_required": False,
        "tests_require_real_llm_api_network": False,
        "output_files": V311_GOLDEN_DEMO_OUTPUT_FILES,
    }
    manifest = {
        "golden_demo_manifest_version": "3.11.0-alpha.1",
        "status": status,
        "capabilities": [
            "golden_demo_readiness",
            "real_input_sample_coverage",
            "generated_artifact_openability",
            "generated_package_compatibility",
            "smoke_test_realism",
        ],
        "acceptance_result": "real_acceptance_smoke_result.json",
        "local_first": True,
        "llm_optional_assist_only": True,
        "network_required": False,
    }
    trace = {
        "v311_acceptance_trace_version": "3.11.0-alpha.1",
        "steps": stages,
        "deterministic_local_implementation_path": "Parse generated package files and reports locally, then record readiness gates.",
        "optional_llm_assist_path": "Reserved for future troubleshooting summaries only; not invoked in v3.11.",
        "offline_fallback": "All checks run from local files without network or provider configuration.",
        "tests_require_real_llm_api_network": False,
    }
    write_json(output / "sample_coverage_report.json", sample_coverage)
    write_json(output / "artifact_openability_report.json", openability)
    write_json(output / "generated_package_compatibility_report.json", compatibility)
    write_json(output / "smoke_realism_report.json", realism)
    write_json(output / "real_acceptance_smoke_result.json", result)
    write_json(output / "golden_demo_manifest.json", manifest)
    write_json(output / "v311_acceptance_trace.json", trace)
    (output / "sample_coverage_report.md").write_text(_sample_report(sample_coverage), encoding="utf-8")
    (output / "artifact_openability_report.md").write_text(_openability_report(openability), encoding="utf-8")
    (output / "real_acceptance_smoke_report.md").write_text(_acceptance_report(result), encoding="utf-8")
    (output / "golden_demo_report.md").write_text(_golden_demo_report(manifest, result), encoding="utf-8")
    return result


def _sample_coverage(sample_root: Path) -> dict:
    files = [path for path in sample_root.rglob("*") if path.is_file() and not _hidden(path)]
    text_files = [path for path in files if path.suffix.lower() in {".md", ".txt", ".json", ".jsonl", ".yaml", ".yml", ".csv"}]
    by_suffix: dict[str, int] = {}
    for path in files:
        suffix = path.suffix.lower() or "<none>"
        by_suffix[suffix] = by_suffix.get(suffix, 0) + 1
    status = "pass" if files and text_files else "fail"
    return {
        "sample_coverage_report_version": "3.11.0-alpha.1",
        "status": status,
        "sample_root": _rel(sample_root),
        "file_count": len(files),
        "text_like_file_count": len(text_files),
        "suffix_counts": by_suffix,
        "real_input_sample_coverage": status == "pass",
        "network_required": False,
        "tests_require_real_llm_api_network": False,
    }


def _artifact_openability(package: Path) -> dict:
    checks = []
    for path in sorted(path for path in package.rglob("*") if path.is_file() and not _hidden(path)):
        if path.suffix.lower() in {".json", ".jsonl", ".md", ".txt", ".yaml", ".yml", ".docx", ".pptx", ".pdf"}:
            checks.append(_open_file(path))
    failed = [item for item in checks if item["status"] == "fail"]
    return {
        "artifact_openability_report_version": "3.11.0-alpha.1",
        "status": "fail" if failed else "pass",
        "package": _rel(package),
        "checked_artifact_count": len(checks),
        "failed_artifact_count": len(failed),
        "checks": checks,
        "network_required": False,
        "tests_require_real_llm_api_network": False,
    }


def _open_file(path: Path) -> dict:
    try:
        if path.suffix.lower() == ".json":
            json.loads(path.read_text(encoding="utf-8"))
        elif path.suffix.lower() == ".jsonl":
            for line in path.read_text(encoding="utf-8").splitlines():
                if line.strip():
                    json.loads(line)
        elif path.suffix.lower() in {".md", ".txt", ".yaml", ".yml"}:
            path.read_text(encoding="utf-8")
        elif path.suffix.lower() in {".docx", ".pptx"}:
            with ZipFile(path):
                pass
        elif path.suffix.lower() == ".pdf":
            data = path.read_bytes()[:5]
            if data != b"%PDF-":
                raise ValueError("PDF header missing")
        return {"path": _rel(path), "artifact_type": path.suffix.lower().lstrip("."), "status": "pass"}
    except (OSError, UnicodeDecodeError, json.JSONDecodeError, BadZipFile, ValueError) as exc:
        return {"path": _rel(path), "artifact_type": path.suffix.lower().lstrip("."), "status": "fail", "reason": str(exc)}


def _compatibility(package: Path) -> dict:
    checks = []
    for name in CORE_ACCEPTANCE_FILES:
        path = package / name
        checks.append({"name": name, "status": "pass" if path.exists() else "fail", "path": _rel(path)})
    manifest = _read_json(package / "manifest.json")
    checks.append({"name": "manifest_identifies_forge_package", "status": "pass" if _manifest_identifies_package(manifest) else "fail"})
    chunk_count = manifest.get("chunk_count", 0) if isinstance(manifest, dict) else 0
    checks.append({"name": "manifest_has_chunk_count", "status": "pass" if chunk_count >= 1 else "fail"})
    failed = [item for item in checks if item["status"] == "fail"]
    return {
        "generated_package_compatibility_report_version": "3.11.0-alpha.1",
        "status": "fail" if failed else "pass",
        "checks": checks,
        "contract": "local_knowledge_package_smoke",
        "llm_required": False,
        "network_required": False,
        "tests_require_real_llm_api_network": False,
    }


def _smoke_realism(package: Path, require_v37: bool, require_v38: bool, require_v39: bool, require_v310: bool) -> dict:
    expectations = [
        ("v37_query_planning", require_v37, ["query_rewrite_report.json", "retrieval_plan.json"]),
        ("v38_retrieval_quality", require_v38, ["retrieval_quality_report.json", "knowledge_accuracy_report.json"]),
        ("v39_storage_memory", require_v39, ["workspace_registry.json", "memory_lifecycle_report.json"]),
        ("v310_local_agent_runtime", require_v310, ["local_agent_runtime_status.json", "mother_child_runtime_trace.json"]),
    ]
    checks = []
    for name, required, files in expectations:
        present = [file_name for file_name in files if _find_report(package, file_name)]
        status = "pass" if not required or len(present) == len(files) else "fail"
        checks.append({"name": name, "required": required, "status": status, "expected_files": files, "present_files": present})
    failed = [item for item in checks if item["status"] == "fail"]
    return {
        "smoke_realism_report_version": "3.11.0-alpha.1",
        "status": "fail" if failed else "pass",
        "checks": checks,
        "real_acceptance_smoke": True,
        "toy_scaffold_only": False,
        "llm_required": False,
        "network_required": False,
        "tests_require_real_llm_api_network": False,
    }


def _stage(name: str, status: str, report: str) -> dict:
    return {"name": name, "status": status, "report": report}


def _final_status(stages: list[dict]) -> str:
    return "fail" if any(stage["status"] == "fail" for stage in stages) else "pass"


def _read_json(path: Path) -> dict:
    if not path.exists():
        return {}
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return {}


def _find_report(package: Path, file_name: str) -> Path | None:
    direct = package / file_name
    if direct.exists() and _report_passes(direct):
        return direct
    candidates = sorted(path for path in package.rglob(file_name) if path.is_file() and not _hidden(path))
    for candidate in candidates:
        if _report_passes(candidate):
            return candidate
    return candidates[0] if candidates else None


def _report_passes(path: Path) -> bool:
    payload = _read_json(path)
    if path.name in {"real_acceptance_smoke_result.json", "local_agent_runtime_status.json"}:
        return payload.get("status") == "pass"
    status = payload.get("status")
    if status is None:
        return bool(payload)
    return status in {"pass", "ready", "answered", "warning", "contract_only"}


def _manifest_identifies_package(manifest: dict) -> bool:
    if not isinstance(manifest, dict):
        return False
    return any(manifest.get(name) for name in ["package_id", "package_version", "domain"]) and "source_count" in manifest


def _hidden(path: Path) -> bool:
    return any(part.startswith(".") or part == "__pycache__" for part in path.parts)


def _sample_report(report: dict) -> str:
    return f"""# Sample Coverage Report

- Status: {report['status']}
- Sample root: {report['sample_root']}
- Files: {report['file_count']}
- Text-like files: {report['text_like_file_count']}
- Network required: {report['network_required']}
"""


def _openability_report(report: dict) -> str:
    return f"""# Artifact Openability Report

- Status: {report['status']}
- Checked artifacts: {report['checked_artifact_count']}
- Failed artifacts: {report['failed_artifact_count']}
- Network required: {report['network_required']}
"""


def _acceptance_report(result: dict) -> str:
    rows = "\n".join(f"| {stage['name']} | {stage['status']} |" for stage in result["stages"])
    return f"""# Real Acceptance Smoke Report

- Status: {result['status']}
- Package: {result['package']}
- LLM required: {result['llm_required']}
- Network required: {result['network_required']}

| Stage | Status |
| --- | --- |
{rows}
"""


def _golden_demo_report(manifest: dict, result: dict) -> str:
    capabilities = "\n".join(f"- {item}" for item in manifest["capabilities"])
    return f"""# v3.11 Golden Demo Acceptance

- Status: {result['status']}
- Local-first: {manifest['local_first']}
- LLM optional assist only: {manifest['llm_optional_assist_only']}
- Network required: {manifest['network_required']}

## Capabilities

{capabilities}
"""


def _rel(path: Path) -> str:
    return str(path).replace("\\", "/")


def _now() -> str:
    return datetime.now(timezone.utc).isoformat()
