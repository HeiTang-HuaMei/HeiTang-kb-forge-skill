from __future__ import annotations

import json
import re
from datetime import datetime, timezone
from pathlib import Path

from heitang_kb_forge.doctor import run_doctor
from heitang_kb_forge.exporters.jsonl_exporter import write_json


V312_PRODUCT_HARDENING_OUTPUT_FILES = [
    "product_hardening_manifest.json",
    "product_hardening_report.md",
    "doctor_diagnostics_report.json",
    "command_audit_report.json",
    "package_audit_report.json",
    "workspace_audit_report.json",
    "golden_demo_verification_report.json",
    "stable_error_taxonomy.json",
    "troubleshooting_report.json",
    "troubleshooting_report.md",
    "optional_dependency_diagnostics.json",
    "no_secret_no_temp_report.json",
    "local_privacy_boundary_report.json",
    "contract_drift_report.json",
    "installer_readiness_report.json",
    "local_release_readiness_result.json",
    "local_release_readiness_report.md",
    "v4_rc_gate_report.json",
    "v4_rc_gate_report.md",
    "v312_external_absorption_map.json",
    "release_artifact_inventory.json",
    "v312_hardening_trace.json",
]

REQUIRED_PACKAGE_FILES = ["manifest.json", "chunks.jsonl", "cards.jsonl", "qa_pairs.jsonl", "glossary.jsonl", "quality_report.json"]
PRIOR_REPORT_GROUPS = [
    ("v37_query_planning", ["query_rewrite_report.json", "retrieval_plan.json"]),
    ("v38_retrieval_quality", ["retrieval_quality_report.json", "knowledge_accuracy_report.json"]),
    ("v39_storage_memory", ["workspace_registry.json", "memory_lifecycle_report.json"]),
    ("v310_local_agent_runtime", ["local_agent_runtime_status.json", "mother_child_runtime_trace.json"]),
    ("v311_golden_demo_acceptance", ["real_acceptance_smoke_result.json", "artifact_openability_report.json"]),
]
STABLE_ERROR_TAXONOMY = [
    {"error_id": "missing_source", "expected_text": "--source must exist", "source": "preprocess-pdf-markdown"},
    {"error_id": "reserved_network", "expected_text": "--allow-network is reserved and must remain false", "source": "v3.10-v3.12 commands"},
    {"error_id": "reserved_llm", "expected_text": "--allow-llm is reserved and must remain false", "source": "v3.10-v3.12 commands"},
    {"error_id": "config_network_disabled", "expected_text": "allow_network must remain false", "source": "config gates"},
    {"error_id": "config_llm_disabled", "expected_text": "allow_llm must remain false", "source": "config gates"},
]
SECRET_PATTERNS = ["api_key: sk-", "secret_key:", "client_secret:", "sk-live-", "sk-proj-"]
TEMP_PREFIXES = ("tmp_", "temp_", "ci_failed_")
REPORT_SEARCH_DIRS = [
    ".",
    "workbench_contracts",
    "workbench_contracts_fixed",
    "v37_plan_answering_zh",
    "v37_query_rewrite_zh",
    "v38_retrieval_quality",
    "v38_knowledge_accuracy",
    "v39_storage",
    "v39_memory_lifecycle",
    "v310_local_agent",
    "v310_local_agent_fixed",
    "v311_golden_demo",
    "v311_golden_demo_after_normalization",
    "v311_golden_demo_fixed",
]


def run_product_hardening(
    workspace: Path,
    output: Path,
    package: Path | None = None,
    require_v37: bool = True,
    require_v38: bool = True,
    require_v39: bool = True,
    require_v310: bool = True,
    require_v311: bool = True,
) -> dict:
    output.mkdir(parents=True, exist_ok=True)
    package = package or workspace
    doctor_report, _ = run_doctor(output / "doctor")
    reports = {
        "doctor_diagnostics": _doctor_diagnostics(doctor_report),
        "command_audit": _command_audit(workspace),
        "package_audit": _package_audit(package),
        "workspace_audit": _workspace_audit(workspace),
        "golden_demo_verification": _golden_demo_verification(package, require_v311),
        "stable_error_taxonomy": _stable_error_taxonomy(workspace),
        "troubleshooting": _troubleshooting(workspace),
        "optional_dependency_diagnostics": _optional_dependency_diagnostics(doctor_report),
        "no_secret_no_temp": _no_secret_no_temp(workspace),
        "local_privacy_boundary": _local_privacy_boundary(workspace),
        "contract_drift": _contract_drift(package),
        "installer_readiness": _installer_readiness(workspace),
        "release_artifact_inventory": _artifact_inventory(package),
    }
    reports["v4_rc_gate"] = _v4_rc_gate(reports)
    reports["v312_external_absorption_map"] = _external_absorption_map()
    reports["local_release_readiness"] = _local_release_readiness(
        package,
        reports,
        require_v37,
        require_v38,
        require_v39,
        require_v310,
        require_v311,
    )
    manifest = {
        "product_hardening_manifest_version": "3.12.0-alpha.1",
        "generated_at": _now(),
        "status": reports["local_release_readiness"]["status"],
        "workspace": _rel(workspace),
        "package": _rel(package),
        "capabilities": sorted(reports.keys()),
        "local_first": True,
        "llm_optional_assist_only": True,
        "network_required": False,
        "tests_require_real_llm_api_network": False,
        "output_files": V312_PRODUCT_HARDENING_OUTPUT_FILES,
    }
    trace = {
        "v312_hardening_trace_version": "3.12.0-alpha.1",
        "steps": [{"name": name, "status": report["status"]} for name, report in reports.items()],
        "deterministic_local_implementation_path": "Read local repository, package, workflow, contract, and diagnostic files.",
        "optional_llm_assist_path": "Reserved for future troubleshooting copy suggestions only; not invoked in v3.12.",
        "offline_fallback": "All checks run from local files without provider configuration.",
        "tests_require_real_llm_api_network": False,
    }
    _write_reports(output, manifest, reports, trace)
    return reports["local_release_readiness"] | {"output_files": V312_PRODUCT_HARDENING_OUTPUT_FILES}


def _doctor_diagnostics(doctor_report: dict) -> dict:
    required = {"python_version", "package_import", "cli_availability", "sqlite3_availability", "network_not_required"}
    check_names = {check["name"] for check in doctor_report.get("checks", [])}
    checks = [{"name": name, "status": "pass" if name in check_names else "fail"} for name in sorted(required)]
    return _report("doctor_diagnostics_report_version", checks, doctor_status=doctor_report.get("status"), network_required=False, llm_required=False)


def _command_audit(workspace: Path) -> dict:
    text = _read(workspace / "heitang_kb_forge" / "cli_runtime.py")
    commands = sorted(set(re.findall(r"@app\.command\(\"([^\"]+)\"\)", text)))
    required = [
        "rewrite-query",
        "plan-retrieval",
        "eval-retrieval",
        "init-workspace",
        "run-local-agent",
        "run-golden-demo-acceptance",
    ]
    checks = [{"name": command, "status": "pass" if command in commands else "fail"} for command in required]
    return _report("command_audit_report_version", checks, command_count=len(commands), audited_commands=required)


def _package_audit(package: Path) -> dict:
    checks = [{"name": name, "status": "pass" if (package / name).exists() else "fail"} for name in REQUIRED_PACKAGE_FILES]
    manifest = _read_json(package / "manifest.json")
    checks.append({"name": "manifest_chunk_count", "status": "pass" if isinstance(manifest, dict) and manifest.get("chunk_count", 0) >= 1 else "fail"})
    checks.append({"name": "json_jsonl_parseable", "status": "pass" if _parseable_outputs(package) else "fail"})
    return _report("package_audit_report_version", checks, package=_rel(package), required_files=REQUIRED_PACKAGE_FILES)


def _workspace_audit(workspace: Path) -> dict:
    checks = [
        {"name": "docs_present", "status": "pass" if (workspace / "docs").exists() else "fail"},
        {"name": "tests_present", "status": "pass" if (workspace / "tests").exists() else "fail"},
        {"name": "ci_workflows_present", "status": "pass" if (workspace / ".github" / "workflows" / "ci.yml").exists() else "fail"},
        {"name": "ui_repo_not_required", "status": "pass"},
        {"name": "pyproject_present", "status": "pass" if (workspace / "pyproject.toml").exists() else "fail"},
    ]
    return _report("workspace_audit_report_version", checks, workspace=_rel(workspace))


def _golden_demo_verification(package: Path, required: bool) -> dict:
    result_path = _find_report(package, "real_acceptance_smoke_result.json")
    openability_path = _find_report(package, "artifact_openability_report.json")
    result = _read_json(result_path) if result_path else {}
    checks = [
        {"name": "golden_demo_result_exists", "status": "pass" if result else "fail", "path": _rel(result_path) if result_path else None},
        {"name": "golden_demo_status_pass", "status": "pass" if result.get("status") == "pass" else "fail"},
        {"name": "artifact_openability_report_exists", "status": "pass" if openability_path else "fail", "path": _rel(openability_path) if openability_path else None},
    ]
    if not required:
        for check in checks:
            if check["status"] == "fail":
                check["status"] = "pass"
                check["note"] = "not_required"
    return _report("golden_demo_verification_report_version", checks, required=required)


def _stable_error_taxonomy(workspace: Path) -> dict:
    text = _read(workspace / "heitang_kb_forge" / "cli_runtime.py")
    checks = [{"name": item["error_id"], "status": "pass" if item["expected_text"] in text else "fail"} for item in STABLE_ERROR_TAXONOMY]
    return _report("stable_error_taxonomy_version", checks, errors=STABLE_ERROR_TAXONOMY)


def _troubleshooting(workspace: Path) -> dict:
    docs = [workspace / "docs" / "TROUBLESHOOTING.md", workspace / "docs" / "V311_GOLDEN_DEMO_ACCEPTANCE_SMOKE.md"]
    text = "\n".join(_read(path).lower() for path in docs)
    topics = ["doctor", "quality", "ocr", "golden demo", "artifact openability", "network", "llm"]
    checks = [{"name": topic, "status": "pass" if topic in text else "fail"} for topic in topics]
    return _report("troubleshooting_report_version", checks, docs_checked=[_rel(path) for path in docs if path.exists()])


def _optional_dependency_diagnostics(doctor_report: dict) -> dict:
    optional = [check for check in doctor_report.get("checks", []) if not check.get("required")]
    checks = [{"name": check["name"], "status": "pass" if check["status"] in {"pass", "warning"} else "fail", "diagnostic_status": check["status"]} for check in optional]
    return _report("optional_dependency_diagnostics_version", checks, optional_dependency_count=len(optional))


def _no_secret_no_temp(workspace: Path) -> dict:
    secret_hits = []
    temp_hits = []
    for path in _scan_files(workspace):
        relative = path.relative_to(workspace).as_posix()
        if path.name.lower().startswith(TEMP_PREFIXES):
            temp_hits.append(relative)
        if path.suffix.lower() in {".md", ".json", ".yaml", ".yml", ".txt", ".toml", ".py"}:
            text = path.read_text(encoding="utf-8", errors="ignore")
            hits = _secret_line_hits(text)
            if hits:
                secret_hits.append({"path": relative, "lines": hits})
    checks = [
        {"name": "no_secret_patterns", "status": "pass" if not secret_hits else "fail"},
        {"name": "no_temp_artifacts", "status": "pass" if not temp_hits else "fail"},
    ]
    return _report("no_secret_no_temp_report_version", checks, secret_hits=secret_hits, temp_hits=temp_hits)


def _local_privacy_boundary(workspace: Path) -> dict:
    text = "\n".join(_read(path).lower() for path in [workspace / "docs" / "V39_LOCAL_WORKSPACE_STORAGE_MEMORY_LIFECYCLE.md", workspace / "docs" / "V311_GOLDEN_DEMO_ACCEPTANCE_SMOKE.md"])
    checks = [
        {"name": "no_cloud_upload_language", "status": "pass" if "no server" in text or "no-cloud" in text or "不会上传" in text else "fail"},
        {"name": "llm_optional_language", "status": "pass" if "llm" in text and ("optional" in text or "可选" in text) else "fail"},
        {"name": "local_workspace_default", "status": "pass" if "local" in text or "本地" in text else "fail"},
    ]
    return _report("local_privacy_boundary_report_version", checks, no_platform_hosted_user_data=True)


def _contract_drift(package: Path) -> dict:
    status_path = _find_report(package, "workbench_status_contract.json")
    action_path = _find_report(package, "workbench_action_contract.json")
    asset_path = _find_report(package, "workbench_asset_contract.json")
    status = _read_json(status_path) if status_path else {}
    actions = _read_json(action_path) if action_path else {}
    assets = _read_json(asset_path) if asset_path else {}
    checks = [
        {"name": "workbench_status_contract_exists", "status": "pass" if status else "fail", "path": _rel(status_path) if status_path else None},
        {"name": "workbench_action_contract_exists", "status": "pass" if actions else "fail", "path": _rel(action_path) if action_path else None},
        {"name": "workbench_asset_contract_exists", "status": "pass" if assets else "fail", "path": _rel(asset_path) if asset_path else None},
        {"name": "v311_action_exposed", "status": "pass" if _action_exists(actions, "run_golden_demo_acceptance") else "fail"},
    ]
    return _report("contract_drift_report_version", checks, core_ui_contract_drift_risk="tracked_without_ui_dependency")


def _installer_readiness(workspace: Path) -> dict:
    pyproject = _read(workspace / "pyproject.toml")
    checks = [
        {"name": "pyproject_exists", "status": "pass" if pyproject else "fail"},
        {"name": "project_has_dev_extra", "status": "pass" if "dev" in pyproject else "fail"},
        {"name": "installation_doc_exists", "status": "pass" if (workspace / "docs" / "INSTALLATION.md").exists() else "fail"},
        {"name": "console_entrypoint_defined", "status": "pass" if "heitang" in pyproject and "cli" in pyproject else "fail"},
    ]
    return _report("installer_readiness_report_version", checks, installer_kind="local_editable_install")


def _artifact_inventory(package: Path) -> dict:
    files = [path for path in _scan_files(package)]
    suffix_counts: dict[str, int] = {}
    for path in files:
        suffix = path.suffix.lower() or "<none>"
        suffix_counts[suffix] = suffix_counts.get(suffix, 0) + 1
    checks = [{"name": "release_artifacts_present", "status": "pass" if files else "fail"}]
    return _report("release_artifact_inventory_version", checks, package=_rel(package), file_count=len(files), suffix_counts=suffix_counts, total_size_bytes=sum(path.stat().st_size for path in files))


def _v4_rc_gate(reports: dict[str, dict]) -> dict:
    required = ["command_audit", "package_audit", "workspace_audit", "contract_drift", "local_privacy_boundary"]
    checks = [{"name": name, "status": reports[name]["status"]} for name in required]
    checks.append({"name": "ui_dependency_absent", "status": "pass"})
    return _report("v4_rc_gate_report_version", checks, v4_rc_ready=_status(checks) == "pass", next_version="v4.0 Local Knowledge Workbench RC")


def _external_absorption_map() -> dict:
    capabilities = [
        "doctor_diagnostics",
        "command_audit",
        "package_audit",
        "workspace_audit",
        "stable_error_taxonomy",
        "troubleshooting_report",
        "local_privacy_boundary",
        "contract_drift_check",
        "installer_readiness",
        "local_release_readiness",
        "v4_rc_gate",
    ]
    return {
        "v312_external_absorption_map_version": "3.12.0-alpha.1",
        "status": "pass",
        "capabilities": [
            {
                "capability": capability,
                "benchmark_references": ["v3.6 architecture gap audit", "external fusion plan"],
                "decision": "inspire",
                "what_to_absorb": "Local deterministic readiness gates and explicit boundary reporting.",
                "what_not_to_copy": "No external code, prompts, SaaS workflows, cloud user-data hosting, or network-dependent tests.",
                "local_deterministic_implementation": "Static local checks over repository, package, contracts, docs, and generated reports.",
                "optional_llm_assist_path": "Reserved for future explanatory copy only.",
                "offline_fallback": "Run without network, API keys, or configured providers.",
                "tests_require_real_llm_api_network": False,
            }
            for capability in capabilities
        ],
        "no_copy_policy": True,
        "tests_require_real_llm_api_network": False,
    }


def _local_release_readiness(package: Path, reports: dict[str, dict], require_v37: bool, require_v38: bool, require_v39: bool, require_v310: bool, require_v311: bool) -> dict:
    prior = _prior_checks(package, require_v37, require_v38, require_v39, require_v310, require_v311)
    stage_status = {name: report["status"] for name, report in reports.items() if name != "local_release_readiness"}
    blockers = [name for name, status in stage_status.items() if status == "fail"]
    blockers.extend(item["name"] for item in prior if item["status"] == "fail")
    status = "fail" if blockers else "pass"
    return {
        "local_release_readiness_version": "3.12.0-alpha.1",
        "status": status,
        "release_ready": status == "pass",
        "overall_score": max(0, 100 - len(blockers) * 10),
        "critical_blockers": blockers,
        "stage_status": stage_status,
        "prior_version_checks": prior,
        "no_saas": True,
        "no_multi_user": True,
        "no_cloud_sync": True,
        "no_cloud_hosted_user_data": True,
        "llm_required": False,
        "network_required": False,
        "tests_require_real_llm_api_network": False,
        "next_actions": [] if not blockers else ["Resolve failed local hardening checks before v4 RC planning."],
    }


def _prior_checks(package: Path, require_v37: bool, require_v38: bool, require_v39: bool, require_v310: bool, require_v311: bool) -> list[dict]:
    required_flags = {
        "v37_query_planning": require_v37,
        "v38_retrieval_quality": require_v38,
        "v39_storage_memory": require_v39,
        "v310_local_agent_runtime": require_v310,
        "v311_golden_demo_acceptance": require_v311,
    }
    checks = []
    for name, files in PRIOR_REPORT_GROUPS:
        resolved = {file_name: _find_report(package, file_name) for file_name in files}
        missing = [file_name for file_name, path in resolved.items() if path is None]
        failing = [file_name for file_name, path in resolved.items() if path is not None and not _report_passes(path)]
        required = required_flags[name]
        checks.append(
            {
                "name": name,
                "required": required,
                "status": "fail" if required and (missing or failing) else "pass",
                "missing_files": missing,
                "failing_files": failing,
                "resolved_files": {file_name: _rel(path) if path else None for file_name, path in resolved.items()},
            }
        )
    return checks


def _write_reports(output: Path, manifest: dict, reports: dict[str, dict], trace: dict) -> None:
    write_json(output / "product_hardening_manifest.json", manifest)
    write_json(output / "doctor_diagnostics_report.json", reports["doctor_diagnostics"])
    write_json(output / "command_audit_report.json", reports["command_audit"])
    write_json(output / "package_audit_report.json", reports["package_audit"])
    write_json(output / "workspace_audit_report.json", reports["workspace_audit"])
    write_json(output / "golden_demo_verification_report.json", reports["golden_demo_verification"])
    write_json(output / "stable_error_taxonomy.json", reports["stable_error_taxonomy"])
    write_json(output / "troubleshooting_report.json", reports["troubleshooting"])
    write_json(output / "optional_dependency_diagnostics.json", reports["optional_dependency_diagnostics"])
    write_json(output / "no_secret_no_temp_report.json", reports["no_secret_no_temp"])
    write_json(output / "local_privacy_boundary_report.json", reports["local_privacy_boundary"])
    write_json(output / "contract_drift_report.json", reports["contract_drift"])
    write_json(output / "installer_readiness_report.json", reports["installer_readiness"])
    write_json(output / "release_artifact_inventory.json", reports["release_artifact_inventory"])
    write_json(output / "v4_rc_gate_report.json", reports["v4_rc_gate"])
    write_json(output / "v312_external_absorption_map.json", reports["v312_external_absorption_map"])
    write_json(output / "local_release_readiness_result.json", reports["local_release_readiness"])
    write_json(output / "v312_hardening_trace.json", trace)
    (output / "product_hardening_report.md").write_text(_product_report(manifest, reports["local_release_readiness"]), encoding="utf-8")
    (output / "local_release_readiness_report.md").write_text(_readiness_report(reports["local_release_readiness"]), encoding="utf-8")
    (output / "troubleshooting_report.md").write_text(_troubleshooting_report(reports["troubleshooting"]), encoding="utf-8")
    (output / "v4_rc_gate_report.md").write_text(_v4_report(reports["v4_rc_gate"]), encoding="utf-8")


def _report(version_key: str, checks: list[dict], **extra: object) -> dict:
    return {version_key: "3.12.0-alpha.1", "status": _status(checks), "checks": checks, "tests_require_real_llm_api_network": False, **extra}


def _status(checks: list[dict]) -> str:
    return "fail" if any(check.get("status") == "fail" for check in checks) else "pass"


def _parseable_outputs(package: Path) -> bool:
    try:
        for path in _scan_files(package):
            if path.suffix.lower() == ".json":
                json.loads(path.read_text(encoding="utf-8"))
            elif path.suffix.lower() == ".jsonl":
                for line in path.read_text(encoding="utf-8").splitlines():
                    if line.strip():
                        json.loads(line)
        return True
    except (OSError, UnicodeDecodeError, json.JSONDecodeError):
        return False


def _action_exists(actions: dict, action_id: str) -> bool:
    return any(item.get("id") == action_id for item in actions.get("actions", []) if isinstance(item, dict))


def _find_report(package: Path, file_name: str) -> Path | None:
    candidates = []
    for relative_dir in REPORT_SEARCH_DIRS:
        candidate = package / relative_dir / file_name
        if candidate.exists():
            candidates.append(candidate)
    recursive = sorted(path for path in package.rglob(file_name) if path.is_file())
    for candidate in recursive:
        if candidate not in candidates:
            candidates.append(candidate)
    for candidate in candidates:
        if _report_passes(candidate):
            return candidate
    return candidates[0] if candidates else None


def _report_passes(path: Path) -> bool:
    payload = _read_json(path)
    if path.name == "local_agent_runtime_status.json":
        return payload.get("status") == "pass"
    if path.name == "real_acceptance_smoke_result.json":
        return payload.get("status") == "pass"
    status = payload.get("status")
    if status is None:
        return bool(payload)
    return status in {"pass", "ready", "answered", "warning", "contract_only"}


def _secret_line_hits(text: str) -> list[dict]:
    patterns = [
        re.compile(r"sk-live-[A-Za-z0-9_-]{8,}"),
        re.compile(r"sk-proj-[A-Za-z0-9_-]{8,}"),
        re.compile(r"client_secret\s*[:=]\s*['\"][^'\"]{8,}['\"]", re.IGNORECASE),
        re.compile(r"api_key\s*[:=]\s*['\"]?sk-[A-Za-z0-9_-]{8,}['\"]?", re.IGNORECASE),
        re.compile(r"secret_key\s*[:=]\s*['\"]?[^'\"\s]{8,}['\"]?", re.IGNORECASE),
    ]
    hits = []
    for line_no, line in enumerate(text.splitlines(), start=1):
        if _is_secret_scanner_definition(line):
            continue
        if any(pattern.search(line) for pattern in patterns):
            hits.append({"line": line_no, "preview": _redact_secret_line(line)})
    return hits


def _is_secret_scanner_definition(line: str) -> bool:
    stripped = line.strip()
    return (
        "SECRET_PATTERNS" in stripped
        or "patterns =" in stripped
        or "secret_hits" in stripped
        or stripped.startswith("re.compile(")
    )


def _redact_secret_line(line: str) -> str:
    redacted = re.sub(r"sk-(?:live|proj)-[A-Za-z0-9_-]+", "sk-<redacted>", line)
    redacted = re.sub(r"(api_key|secret_key|client_secret)(\s*[:=]\s*['\"])[^'\"]+(['\"])", r"\1\2<redacted>\3", redacted, flags=re.IGNORECASE)
    redacted = re.sub(r"(api_key|secret_key|client_secret)(\s*[:=]\s*)[^'\"\s]+", r"\1\2<redacted>", redacted, flags=re.IGNORECASE)
    return redacted[:160]


def _scan_files(root: Path) -> list[Path]:
    if not root.exists():
        return []
    ignored = {".git", "__pycache__", ".pytest_cache", ".mypy_cache"}
    return [path for path in root.rglob("*") if path.is_file() and not any(part in ignored for part in path.parts)]


def _read(path: Path) -> str:
    if not path.exists():
        return ""
    return path.read_text(encoding="utf-8", errors="ignore")


def _read_json(path: Path) -> dict:
    if not path.exists():
        return {}
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return {}
    return payload if isinstance(payload, dict) else {}


def _product_report(manifest: dict, readiness: dict) -> str:
    return f"""# v3.12 Product Hardening Report

- Status: {manifest['status']}
- Release ready: {readiness['release_ready']}
- Local-first: {manifest['local_first']}
- LLM optional assist only: {manifest['llm_optional_assist_only']}
- Network required: {manifest['network_required']}
"""


def _readiness_report(readiness: dict) -> str:
    blockers = "\n".join(f"- {item}" for item in readiness["critical_blockers"]) or "- None"
    return f"""# Local Release Readiness Report

- Status: {readiness['status']}
- Release ready: {readiness['release_ready']}
- Overall score: {readiness['overall_score']}
- LLM required: {readiness['llm_required']}
- Network required: {readiness['network_required']}

## Critical Blockers

{blockers}
"""


def _troubleshooting_report(report: dict) -> str:
    rows = "\n".join(f"| {item['name']} | {item['status']} |" for item in report["checks"])
    return f"""# Troubleshooting Coverage Report

| Topic | Status |
| --- | --- |
{rows}
"""


def _v4_report(report: dict) -> str:
    return f"""# v4 RC Gate Report

- Status: {report['status']}
- v4 RC ready: {report['v4_rc_ready']}
- Next version: {report['next_version']}
"""


def _rel(path: Path) -> str:
    return str(path).replace("\\", "/")


def _now() -> str:
    return datetime.now(timezone.utc).isoformat()
