import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app
from heitang_kb_forge.exporters.workflow_report_exporter import FULL_WORKFLOW_REQUIRED_STAGES
from heitang_kb_forge.test_governance import build_validation_plan, load_manifest


def _write_json(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")


def _write_text(path, text):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")


def _make_workflow_evidence(tmp_path):
    chain = tmp_path / "office_table_e2e"
    skill = tmp_path / "skill_generation"
    agent = tmp_path / "agent_binding"

    _write_json(chain / "batch_import" / "batch_import_report.json", {"status": "passed"})
    _write_json(chain / "batch_import" / "document_preflight.json", {"items": []})
    _write_text(chain / "batch_import" / "preflight_report.md", "# Preflight\n")
    _write_json(chain / "document_understanding" / "document_understanding_manifest.json", {"status": "completed"})
    _write_text(chain / "document_understanding" / "document_understanding_report.md", "# DU\n")
    _write_text(chain / "document_understanding" / "progress_events.jsonl", '{"stage":"started"}\n')
    _write_text(chain / "document_understanding" / "backend_runs" / "doc-0001" / "backend_run.log", "runtime log\n")
    _write_json(chain / "knowledge_base" / "knowledge_base_build_report.json", {"status": "pass"})
    _write_text(chain / "knowledge_base" / "quality_report.md", "# Quality\n")
    _write_text(chain / "knowledge_base" / "chunks.jsonl", '{"text":"raw stream"}\n')
    _write_json(chain / "knowledge_package" / "knowledge_package_build_report.json", {"status": "pass"})
    _write_text(chain / "knowledge_package" / "knowledge_package_build_report.md", "# Package\n")
    _write_json(chain / "knowledge_verification" / "claim_verification_report.json", {"status": "passed"})
    _write_json(chain / "methodology" / "methodology_map.json", {"modules": []})
    _write_text(chain / "methodology" / "methodology_map.md", "# Methodology\n")
    _write_text(chain / "input" / "source.md", "raw input must not be copied\n")
    _write_text(chain / "document_understanding" / "normalized_sources" / "source.md", "normalized raw source\n")

    _write_json(skill / "run_manifest.json", {"status": "passed"})
    _write_json(skill / "skill_plan" / "skill_candidates.json", {"skills": []})
    _write_json(skill / "skill_suite" / "suite_validation_report.json", {"status": "passed"})
    _write_text(skill / "skill_suite" / "GOVERNANCE_REPORT.md", "# Governance\n")

    _write_json(agent / "run_manifest.json", {"status": "passed"})
    _write_json(agent / "agent_package" / "agent_manifest.json", {"agent": "kb_bound"})
    _write_text(agent / "agent_package" / "agent_profile.yaml", "agent: kb_bound\n")
    _write_json(agent / "local_agent_runtime" / "local_agent_runtime_status.json", {"status": "passed"})
    _write_json(
        agent / "agent_output_verification" / "agent_output_verification_report.json",
        {"status": "passed", "trusted_claim_count": 1},
    )
    _write_text(agent / "agent_output_verification" / "agent_output_verification_report.md", "# Verification\n")

    return chain, skill, agent


def test_export_knowledge_report_writes_governed_openable_bundle(tmp_path):
    chain, skill, agent = _make_workflow_evidence(tmp_path)
    output = tmp_path / "export"

    result = CliRunner().invoke(
        app,
        [
            "export-knowledge-report",
            "--source",
            str(chain),
            "--source",
            str(skill),
            "--source",
            str(agent),
            "--output",
            str(output),
            "--run-id",
            "test_report_export",
        ],
    )

    assert result.exit_code == 0, result.output
    manifest = json.loads((output / "workflow_report_export_manifest.json").read_text(encoding="utf-8"))
    artifact_index = json.loads((output / "artifact_index.json").read_text(encoding="utf-8"))
    openability = json.loads((output / "openability_check.json").read_text(encoding="utf-8"))
    summary = (output / "workflow_report_export_summary.md").read_text(encoding="utf-8")

    assert manifest["status"] == "passed"
    assert manifest["run_id"] == "test_report_export"
    assert manifest["missing_required_stages"] == []
    assert set(manifest["required_stages"]) == set(FULL_WORKFLOW_REQUIRED_STAGES)
    assert all(item["covered"] for item in manifest["stage_coverage"].values())
    assert openability["status"] == "passed"
    assert artifact_index["artifact_count"] > 0
    assert "Runtime logs excluded: true" in summary
    assert not any(item["exported_path"].endswith((".log", ".jsonl")) for item in artifact_index["artifacts"])
    assert not any("progress_events.jsonl" in item["exported_path"] for item in artifact_index["artifacts"])
    assert not any("/input/" in item["exported_path"] for item in artifact_index["artifacts"])
    assert not any("/normalized_sources/" in item["exported_path"] for item in artifact_index["artifacts"])
    assert any(item["relative_path"].endswith("progress_events.jsonl") for item in artifact_index["skipped_files"])


def test_export_workflow_report_alias_uses_same_contract(tmp_path):
    chain, skill, agent = _make_workflow_evidence(tmp_path)
    output = tmp_path / "export"

    result = CliRunner().invoke(
        app,
        [
            "export-workflow-report",
            "--source",
            str(chain),
            "--source",
            str(skill),
            "--source",
            str(agent),
            "--output",
            str(output),
        ],
    )

    assert result.exit_code == 0, result.output
    manifest = json.loads((output / "workflow_report_export_manifest.json").read_text(encoding="utf-8"))
    assert manifest["schema_version"] == "workflow_report_export.v1"
    assert manifest["status"] == "passed"


def test_export_knowledge_report_fails_when_json_is_not_openable(tmp_path):
    chain, skill, agent = _make_workflow_evidence(tmp_path)
    (chain / "knowledge_package" / "knowledge_package_build_report.json").write_text("{bad json", encoding="utf-8")
    output = tmp_path / "export"

    result = CliRunner().invoke(
        app,
        [
            "export-knowledge-report",
            "--source",
            str(chain),
            "--source",
            str(skill),
            "--source",
            str(agent),
            "--output",
            str(output),
        ],
    )

    assert result.exit_code == 1, result.output
    manifest = json.loads((output / "workflow_report_export_manifest.json").read_text(encoding="utf-8"))
    openability = json.loads((output / "openability_check.json").read_text(encoding="utf-8"))
    assert manifest["status"] == "failed"
    assert openability["failed_count"] == 1


def test_report_export_has_own_fast_gate_mapping():
    manifest = load_manifest()
    plan = build_validation_plan(
        ["heitang_kb_forge/exporters/workflow_report_exporter.py"],
        phase="development",
        manifest=manifest,
    )

    assert plan["matched_rules"] == ["report_export"]
    assert [gate["name"] for gate in plan["selected_gates"]] == ["core_fast_report_export"]
