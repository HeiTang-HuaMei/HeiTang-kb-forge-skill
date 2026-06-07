import json
from pathlib import Path

from heitang_kb_forge.exporters.jsonl_exporter import write_json
from heitang_kb_forge.product_hardening import V312_PRODUCT_HARDENING_OUTPUT_FILES, run_product_hardening


def test_product_hardening_writes_complete_release_gate_reports(tmp_path):
    workspace = _workspace(tmp_path)
    package = _package(tmp_path)
    output = tmp_path / "hardening"

    result = run_product_hardening(workspace, output, package, require_v37=False, require_v38=False, require_v39=False, require_v310=False)

    assert result["status"] == "pass"
    for name in V312_PRODUCT_HARDENING_OUTPUT_FILES:
        assert (output / name).exists(), name
    readiness = _json(output / "local_release_readiness_result.json")
    assert readiness["release_ready"] is True
    assert readiness["llm_required"] is False
    assert readiness["network_required"] is False
    assert _json(output / "v312_external_absorption_map.json")["no_copy_policy"] is True


def test_product_hardening_detects_missing_required_prior_version_report(tmp_path):
    workspace = _workspace(tmp_path)
    package = _package(tmp_path)
    output = tmp_path / "hardening"

    result = run_product_hardening(workspace, output, package, require_v37=True, require_v38=False, require_v39=False, require_v310=False, require_v311=False)

    assert result["status"] == "fail"
    readiness = _json(output / "local_release_readiness_result.json")
    assert "v37_query_planning" in readiness["critical_blockers"]


def test_hardening_reports_cover_required_v312_categories(tmp_path):
    workspace = _workspace(tmp_path)
    package = _package(tmp_path)
    output = tmp_path / "hardening"

    run_product_hardening(workspace, output, package, require_v37=False, require_v38=False, require_v39=False, require_v310=False)

    required_reports = [
        "doctor_diagnostics_report.json",
        "command_audit_report.json",
        "package_audit_report.json",
        "workspace_audit_report.json",
        "golden_demo_verification_report.json",
        "stable_error_taxonomy.json",
        "troubleshooting_report.json",
        "optional_dependency_diagnostics.json",
        "no_secret_no_temp_report.json",
        "local_privacy_boundary_report.json",
        "contract_drift_report.json",
        "installer_readiness_report.json",
        "v4_rc_gate_report.json",
    ]
    for name in required_reports:
        payload = _json(output / name)
        assert payload["status"] == "pass", name
        assert payload["tests_require_real_llm_api_network"] is False


def _workspace(tmp_path: Path) -> Path:
    source = Path.cwd()
    workspace = tmp_path / "workspace"
    (workspace / "docs").mkdir(parents=True)
    (workspace / "tests").mkdir()
    (workspace / "heitang_kb_forge").mkdir()
    (workspace / ".github" / "workflows").mkdir(parents=True)
    for name in ["pyproject.toml", "skill.json"]:
        (workspace / name).write_text((source / name).read_text(encoding="utf-8"), encoding="utf-8")
    (workspace / "heitang_kb_forge" / "cli_runtime.py").write_text((source / "heitang_kb_forge" / "cli_runtime.py").read_text(encoding="utf-8"), encoding="utf-8")
    (workspace / ".github" / "workflows" / "ci.yml").write_text((source / ".github" / "workflows" / "ci.yml").read_text(encoding="utf-8"), encoding="utf-8")
    (workspace / ".github" / "workflows" / "release-check.yml").write_text("name: Release Check\n", encoding="utf-8")
    (workspace / "docs" / "INSTALLATION.md").write_text("Install with python -m pip install -e .\n", encoding="utf-8")
    (workspace / "docs" / "TROUBLESHOOTING.md").write_text("doctor quality OCR Golden Demo artifact openability network LLM\n", encoding="utf-8")
    (workspace / "docs" / "V311_GOLDEN_DEMO_ACCEPTANCE_SMOKE.md").write_text("Golden Demo artifact openability network LLM optional\n", encoding="utf-8")
    (workspace / "docs" / "V39_LOCAL_WORKSPACE_STORAGE_MEMORY_LIFECYCLE.md").write_text("local workspace no-cloud no server upload LLM optional\n", encoding="utf-8")
    (workspace / "examples" / "quickstart" / "input").mkdir(parents=True)
    return workspace


def _package(tmp_path: Path) -> Path:
    package = tmp_path / "package"
    package.mkdir()
    write_json(package / "manifest.json", {"package_version": "3.12.0-alpha.1", "domain": "general", "source_count": 1, "chunk_count": 1})
    write_json(package / "quality_report.json", {"status": "pass"})
    for name in ["chunks.jsonl", "cards.jsonl", "qa_pairs.jsonl", "glossary.jsonl"]:
        (package / name).write_text(json.dumps({"id": "x", "text": "Hardening evidence."}) + "\n", encoding="utf-8")
    for name in [
        "real_acceptance_smoke_result.json",
        "artifact_openability_report.json",
        "workbench_status_contract.json",
        "workbench_action_contract.json",
        "workbench_asset_contract.json",
    ]:
        payload = {"status": "pass"}
        if name == "workbench_action_contract.json":
            payload = {"actions": [{"id": "run_golden_demo_acceptance"}]}
        write_json(package / name, payload)
    return package


def _json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))
