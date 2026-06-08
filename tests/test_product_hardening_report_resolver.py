import json

from heitang_kb_forge.exporters.jsonl_exporter import write_json
from heitang_kb_forge.product_hardening import run_product_hardening
from tests.test_v312_product_hardening import _workspace


def test_product_hardening_resolves_reports_from_stage_subdirectories(tmp_path):
    workspace = _workspace(tmp_path)
    package = tmp_path / "package"
    package.mkdir()
    write_json(package / "manifest.json", {"package_id": "pkg-alpha", "chunk_count": 1})
    write_json(package / "quality_report.json", {"status": "pass"})
    for name in ["chunks.jsonl", "cards.jsonl", "qa_pairs.jsonl", "glossary.jsonl"]:
        (package / name).write_text(json.dumps({"id": "x", "text": "Evidence."}) + "\n", encoding="utf-8")

    write_json(package / "retrieval_quality_report.json", {"status": "pass"})
    write_json(package / "v37_plan_answering_zh" / "query_rewrite_report.json", {"status": "pass"})
    write_json(package / "v37_plan_answering_zh" / "retrieval_plan.json", {"status": "pass"})
    write_json(package / "v38_knowledge_accuracy" / "knowledge_accuracy_report.json", {"status": "warning"})
    write_json(package / "v39_storage" / "workspace_registry.json", {"status": "pass"})
    write_json(package / "v39_memory_lifecycle" / "memory_lifecycle_report.json", {"status": "pass"})
    write_json(package / "v310_local_agent" / "local_agent_runtime_status.json", {"status": "pass"})
    write_json(package / "v310_local_agent" / "mother_child_runtime_trace.json", {"status": "pass"})
    write_json(package / "v311_golden_demo_after_normalization" / "real_acceptance_smoke_result.json", {"status": "pass"})
    write_json(package / "v311_golden_demo_after_normalization" / "artifact_openability_report.json", {"status": "pass"})
    write_json(package / "workbench_contracts" / "workbench_status_contract.json", {"status": "ready"})
    write_json(package / "workbench_contracts" / "workbench_action_contract.json", {"actions": [{"id": "run_golden_demo_acceptance"}]})
    write_json(package / "workbench_contracts" / "workbench_asset_contract.json", {"status": "ready"})

    output = tmp_path / "hardening"
    result = run_product_hardening(workspace, output, package)

    assert result["status"] == "pass"
    readiness = json.loads((output / "local_release_readiness_result.json").read_text(encoding="utf-8"))
    assert "v37_query_planning" not in readiness["critical_blockers"]
    assert "v38_retrieval_quality" not in readiness["critical_blockers"]
    assert "v39_storage_memory" not in readiness["critical_blockers"]
    assert "v310_local_agent_runtime" not in readiness["critical_blockers"]
    assert "v311_golden_demo_acceptance" not in readiness["critical_blockers"]
    v38 = next(item for item in readiness["prior_version_checks"] if item["name"] == "v38_retrieval_quality")
    assert v38["resolved_files"]["knowledge_accuracy_report.json"]
    contract = json.loads((output / "contract_drift_report.json").read_text(encoding="utf-8"))
    assert contract["status"] == "pass"


def test_product_hardening_resolves_after_fix_golden_demo_directory(tmp_path):
    workspace = _workspace(tmp_path)
    package = tmp_path / "package"
    package.mkdir()
    write_json(package / "manifest.json", {"package_id": "pkg-alpha", "chunk_count": 1})
    write_json(package / "quality_report.json", {"status": "pass"})
    for name in ["chunks.jsonl", "cards.jsonl", "qa_pairs.jsonl", "glossary.jsonl"]:
        (package / name).write_text(json.dumps({"id": "x", "text": "Evidence."}) + "\n", encoding="utf-8")

    write_json(package / "v311_golden_demo_after_fix" / "real_acceptance_smoke_result.json", {"status": "pass"})
    write_json(package / "v311_golden_demo_after_fix" / "artifact_openability_report.json", {"status": "pass"})
    write_json(package / "workbench_contracts" / "workbench_status_contract.json", {"status": "ready"})
    write_json(package / "workbench_contracts" / "workbench_action_contract.json", {"actions": [{"id": "run_golden_demo_acceptance"}]})
    write_json(package / "workbench_contracts" / "workbench_asset_contract.json", {"status": "ready"})

    output = tmp_path / "hardening"
    result = run_product_hardening(
        workspace,
        output,
        package,
        require_v37=False,
        require_v38=False,
        require_v39=False,
        require_v310=False,
        require_v311=True,
    )

    assert result["status"] == "pass"
    verification = json.loads((output / "golden_demo_verification_report.json").read_text(encoding="utf-8"))
    assert verification["status"] == "pass"
