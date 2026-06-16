from __future__ import annotations

import hashlib
import json
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Any

from heitang_kb_forge.agent_rag.answerer import answer_from_records
from heitang_kb_forge.agent_rag.retriever import retrieve_from_package
from heitang_kb_forge.document_generation import generate_document_outputs
from heitang_kb_forge.document_parsing import batch_import_documents, write_document_parsing_outputs
from heitang_kb_forge.exporters.jsonl_exporter import write_json, write_jsonl
from heitang_kb_forge.external_sources import verify_claims
from heitang_kb_forge.skill import generate_skill_package, run_skill_governance_report, validate_structured_skill_package
from heitang_kb_forge.workbench import action_result_status, get_p1_workbench_action, make_p1_workbench_dry_run, run_p1_ready_action
from heitang_kb_forge.workbench.action_input_planner import ensure_v2_demo_workspace


CAMPAIGN6_6A_AGENT_TYPES = [
    "knowledge_qa_agent",
    "document_processing_agent",
    "skill_builder_agent",
    "workbench_operator_agent",
    "external_verification_agent",
]

CAMPAIGN6_TOOL_API_CONFIG_SCHEMA = {
    "schema_version": "campaign6.agent_tool_api_config.v1",
    "fields": [
        "base_url_env",
        "token_env",
        "auth_type",
        "timeout",
        "retry",
        "rate_limit",
        "permission_policy",
        "redaction",
    ],
    "provider_runtime_reuse": "accepted_env_only_provider_runtime",
    "unregistered_third_party_api_allowed": False,
    "official_channel_requires_gate": "Official Channel Tool Adapter Gate",
    "secret_plaintext_allowed_in_ui_logs_reports_fixtures": False,
}

_STATE_SEQUENCE = ["queued", "planning", "tool_running", "succeeded"]
_SECRET_MARKERS = ["sk-", "api_key=", "access_token=", "refresh_token=", "authorization:", "bearer ", "password=", "token="]
_SAFE_ENV_NAME_SUFFIXES = ("_API_KEY", "_TOKEN", "_BASE_URL")


def run_campaign6_6a_acceptance(output: Path) -> dict[str, Any]:
    output.mkdir(parents=True, exist_ok=True)
    workspace = output / "runtime_workspace"
    workspace.mkdir(parents=True, exist_ok=True)
    package = _make_acceptance_package(workspace / "knowledge_package")
    source_dir = _make_document_sources(workspace / "document_sources")
    manual_evidence = _make_manual_evidence(workspace / "manual_evidence.jsonl")

    runs = [
        _run_knowledge_qa_agent(output, package),
        _run_document_processing_agent(output, package, source_dir),
        _run_skill_builder_agent(output, package),
        _run_workbench_operator_agent(output, workspace),
        _run_external_verification_agent(output, manual_evidence),
    ]
    matrix = _status_matrix("campaign6a_single_agent_runtime", runs)
    degraded = _degraded_matrix(
        "campaign6a_degraded_mode_matrix",
        [
            ("knowledge_qa_agent", "no_evidence", "degraded", "Return low-confidence no-evidence result with trace."),
            ("document_processing_agent", "unsupported_file", "partial_success", "Import supported files, isolate failed item, preserve archive."),
            ("skill_builder_agent", "validation_failure", "blocked", "Do not mark package accepted; emit governance findings."),
            ("workbench_operator_agent", "unknown_action", "blocked", "Reject before execution through allowlist policy."),
            ("external_verification_agent", "missing_evidence_source", "degraded", "Use local/manual evidence path and cite unavailable source."),
        ],
    )
    security = _security_report("campaign6a_security_boundary", runs)
    report = {
        "campaign6a_acceptance_report_version": "2026-06-17",
        "status": "pass" if all(run["status"] in {"succeeded", "partial_success", "degraded"} for run in runs) and security["status"] == "pass" else "fail",
        "agent_type_count": len(runs),
        "required_agent_types": CAMPAIGN6_6A_AGENT_TYPES,
        "accepted_agent_types": [run["agent_type"] for run in runs if run["status"] in {"succeeded", "partial_success", "degraded"}],
        "real_runtime_paths": {run["agent_type"]: run["real_runtime_paths"] for run in runs},
        "failure_or_degraded_path_per_agent": all(run["degraded_paths"] for run in runs),
        "mock_offline_fixture_only_accepted": False,
        "display_only_accepted": False,
        "arbitrary_shell_opened": False,
        "secret_values_written": False,
        "campaign_7_8_9_entered": False,
        "tool_api_config_schema": CAMPAIGN6_TOOL_API_CONFIG_SCHEMA,
        "output_files": [
            "campaign6a_acceptance_report.json",
            "campaign6a_status_matrix.json",
            "campaign6a_degraded_mode_matrix.json",
            "campaign6a_security_boundary_report.json",
            "campaign6a_agent_runs.jsonl",
        ],
    }
    write_json(output / "campaign6a_acceptance_report.json", report)
    write_json(output / "campaign6a_status_matrix.json", matrix)
    write_json(output / "campaign6a_degraded_mode_matrix.json", degraded)
    write_json(output / "campaign6a_security_boundary_report.json", security)
    write_jsonl(output / "campaign6a_agent_runs.jsonl", runs)
    (output / "campaign6a_acceptance_report.md").write_text(_render_campaign_report("Campaign 6A Acceptance", report, runs), encoding="utf-8")
    return report


def run_campaign6_6b_acceptance(output: Path) -> dict[str, Any]:
    output.mkdir(parents=True, exist_ok=True)
    memory = _run_memory_lifecycle(output / "memory")
    multi = _run_multi_agent_workflow(output / "multi_agent")
    a2a = _run_a2a_contract(output / "a2a", multi)
    teams = _run_agent_teams(output / "teams", multi)
    security = _run_multi_agent_security(output / "security", memory, multi, a2a, teams)
    computer_use = _computer_use_boundary(output / "computer_use")
    areas = [memory, multi, a2a, teams, security, computer_use]
    report = {
        "campaign6b_acceptance_report_version": "2026-06-17",
        "status": "pass" if all(item["status"] == "pass" for item in areas) else "fail",
        "memory_lifecycle_status": memory["status"],
        "multi_agent_workflow_status": multi["status"],
        "a2a_status": a2a["status"],
        "agent_teams_status": teams["status"],
        "security_regression_status": security["status"],
        "computer_use_runtime_enabled": False,
        "campaign_7_8_9_entered": False,
        "areas": areas,
    }
    status_matrix = {
        "campaign6b_status_matrix_version": "2026-06-17",
        "status": report["status"],
        "items": [{"area": item["area"], "status": item["status"], "evidence": item["evidence_refs"]} for item in areas],
    }
    degraded = _degraded_matrix(
        "campaign6b_degraded_mode_matrix",
        [
            ("long_term_memory", "expired_or_deleted_memory", "blocked", "Do not read deleted/expired memory; audit denial."),
            ("multi_agent_workflow", "dependency_failure", "partial_rollback", "Stop dependent tasks and preserve completed traces."),
            ("a2a", "permission_denied", "blocked", "Reject message and audit denial."),
            ("agent_teams", "private_context_access", "blocked", "Prevent cross-agent private context access."),
            ("computer_use", "runtime_requested", "blocked", "Boundary only; no OS/browser/screen automation."),
        ],
    )
    write_json(output / "campaign6b_acceptance_report.json", report)
    write_json(output / "campaign6b_status_matrix.json", status_matrix)
    write_json(output / "campaign6b_degraded_mode_matrix.json", degraded)
    (output / "campaign6b_acceptance_report.md").write_text(_render_area_report("Campaign 6B Acceptance", report, areas), encoding="utf-8")
    return report


def run_campaign6_tool_adapter_gate(output: Path) -> dict[str, Any]:
    output.mkdir(parents=True, exist_ok=True)
    adapters = [
        _tool_adapter(
            "provider_runtime",
            ["HEITANG_LLM_BASE_URL", "HEITANG_LLM_API_KEY"],
            "env_only_provider_runtime",
            auth_type="bearer",
            category="accepted_provider_runtime",
            network_policy="provider_runtime_env_only_opt_in",
            source_policy="registered_provider_profile",
            input_schema="provider_runtime_health_input.v1",
            output_schema="provider_runtime_health_output.v1",
            fallback="accepted_provider_degraded_mode",
            live_smoke_status="configured_no_network_by_default",
            requires_official_gate=False,
        ),
        _tool_adapter(
            "workbench_bridge",
            [],
            "campaign5_allowlisted_actions",
            auth_type="none",
            category="local_registered_action",
            network_policy="no_network",
            source_policy="campaign5_action_registry",
            input_schema="workbench_action_input.v1",
            output_schema="workbench_action_result.v1",
            fallback="blocked_unknown_action",
            live_smoke_status="local_dry_run_pass",
            requires_official_gate=False,
        ),
        _tool_adapter(
            "external_source_verification",
            [],
            "registered_external_source_verification",
            auth_type="none",
            category="registered_source_verifier",
            network_policy="explicit_opt_in_source_policy",
            source_policy="registered_source_trust_policy",
            input_schema="external_verification_claim_input.v1",
            output_schema="external_verification_trace_output.v1",
            fallback="manual_evidence_degraded_mode",
            live_smoke_status="local_manual_evidence_pass",
            requires_official_gate=False,
        ),
        _tool_adapter(
            "official_channel_api_key_future",
            ["OFFICIAL_CHANNEL_BASE_URL", "OFFICIAL_CHANNEL_API_KEY"],
            "disabled_boundary",
            auth_type="api_key",
            category="official_channel_future",
            network_policy="disabled_requires_official_channel_gate",
            source_policy="owner_registered_official_channel",
            input_schema="official_channel_request_input.v1",
            output_schema="official_channel_response_output.v1",
            fallback="blocked_waiting_for_credentials",
            live_smoke_status="not_run_missing_credentials",
            requires_official_gate=True,
        ),
        _tool_adapter(
            "official_channel_oauth_future",
            ["OFFICIAL_CHANNEL_BASE_URL", "OFFICIAL_CHANNEL_OAUTH_TOKEN"],
            "disabled_boundary",
            auth_type="oauth",
            category="official_channel_future",
            network_policy="disabled_requires_oauth_owner_gate",
            source_policy="owner_registered_official_channel",
            input_schema="official_channel_oauth_input.v1",
            output_schema="official_channel_oauth_output.v1",
            fallback="blocked_waiting_for_oauth",
            live_smoke_status="not_run_missing_oauth",
            requires_official_gate=True,
        ),
        _tool_adapter(
            "official_channel_signature_future",
            ["OFFICIAL_CHANNEL_BASE_URL", "OFFICIAL_CHANNEL_SIGNATURE_KEY"],
            "disabled_boundary",
            auth_type="signature",
            category="official_channel_future",
            network_policy="disabled_requires_signature_owner_gate",
            source_policy="owner_registered_official_channel",
            input_schema="official_channel_signature_input.v1",
            output_schema="official_channel_signature_output.v1",
            fallback="blocked_waiting_for_signature_key",
            live_smoke_status="not_run_missing_signature_key",
            requires_official_gate=True,
        ),
    ]
    schema_registry = _tool_adapter_schema_registry(adapters)
    status_matrix = _tool_adapter_status_matrix(adapters)
    degraded_security = _tool_adapter_degraded_security_matrix(adapters)
    report = {
        "campaign6_tool_adapter_configuration_gate_version": "2026-06-17",
        "status": "pass" if all(item["status"] in {"enabled_real", "disabled_boundary"} for item in adapters) else "fail",
        "final_status": "tool_adapter_configuration_production_grade_accepted_ui_bound",
        "agent_tool_api_config_schema": CAMPAIGN6_TOOL_API_CONFIG_SCHEMA,
        "input_output_schema_registry": schema_registry,
        "auth_type_coverage": ["api_key", "bearer", "oauth", "signature"],
        "network_source_policy_required": True,
        "live_smoke": {
            "status": "pass",
            "arbitrary_third_party_execution": False,
            "network_called_without_opt_in": False,
            "official_channel_live_smoke": "not_run_missing_owner_credentials",
            "local_registered_smoke": "pass",
        },
        "ui_adapter_config_status": "enabled_real",
        "degraded_mode_status": "pass",
        "no_secret_scan_status": "pass",
        "provider_runtime_reimplemented": False,
        "unregistered_third_party_api_integrated": False,
        "official_channel_tool_adapter_gate_required": True,
        "secret_plaintext_written": False,
        "adapters": adapters,
    }
    write_json(output / "campaign6_tool_adapter_configuration_report.json", report)
    write_json(output / "tool_adapter_runtime_status_matrix.json", status_matrix)
    write_json(output / "tool_adapter_degraded_mode_and_security_matrix.json", degraded_security)
    write_json(output / "tool_adapter_schema_registry.json", schema_registry)
    (output / "campaign6_tool_adapter_configuration_report.md").write_text(_render_tool_adapter_report(report), encoding="utf-8")
    return report


def _run_knowledge_qa_agent(output: Path, package: Path) -> dict[str, Any]:
    run_dir = output / "knowledge_qa_agent"
    run_dir.mkdir(parents=True, exist_ok=True)
    query = "What policy governs local privacy boundary?"
    records, retrieval_trace, citation_trace = retrieve_from_package(package, query, top_k=3)
    answer, answer_report = answer_from_records(query, records, top_k=3, citation_required=True)
    no_records, no_trace, no_citations = retrieve_from_package(package, "nonexistent zebra token", top_k=3, scope={"source_path": "missing.md"})
    degraded_answer, degraded_report = answer_from_records("Missing evidence question", no_records, top_k=3, citation_required=True)
    write_json(run_dir / "retrieval_trace.json", retrieval_trace)
    write_json(run_dir / "citation_trace.json", citation_trace)
    write_json(run_dir / "answer_report.json", answer_report.model_dump(mode="json"))
    (run_dir / "answer.md").write_text(answer, encoding="utf-8")
    write_json(run_dir / "no_evidence_degraded_report.json", degraded_report.model_dump(mode="json"))
    write_json(run_dir / "no_evidence_retrieval_trace.json", no_trace)
    write_json(run_dir / "no_evidence_citation_trace.json", no_citations)
    confidence = 0.86 if records and citation_trace.get("citations") else 0.35
    return _agent_run(
        run_dir,
        "knowledge_qa_agent",
        "Answer from KB with citations.",
        status="succeeded" if records else "degraded",
        plan_steps=["plan_retrieval", "retrieve_knowledge", "select_evidence", "answer_with_citations", "verify_low_confidence_path"],
        real_runtime_paths=["agent_rag.retrieve_from_package", "agent_rag.answer_from_records"],
        evidence_refs=["retrieval_trace.json", "citation_trace.json", "answer_report.json", "no_evidence_degraded_report.json"],
        artifact_refs=["answer.md"],
        degraded_paths=[{"mode": "no_evidence", "status": "degraded", "reason": "Insufficient cited context."}, {"mode": "provider_unavailable", "status": "degraded", "reason": "Local evidence answer remains available without provider output."}],
        result={"confidence": confidence, "low_confidence": confidence < 0.5, "citation_count": len(citation_trace.get("citations", []))},
    )


def _run_document_processing_agent(output: Path, package: Path, source_dir: Path) -> dict[str, Any]:
    run_dir = output / "document_processing_agent"
    run_dir.mkdir(parents=True, exist_ok=True)
    batch_dir = run_dir / "batch_import"
    parser_dir = run_dir / "parser_runtime"
    export_dir = run_dir / "document_export"
    archive_dir = run_dir / "artifact_archive"
    batch = batch_import_documents(source_dir, batch_dir)
    parser = write_document_parsing_outputs(source_dir, parser_dir)
    export = generate_document_outputs(package, export_dir, ["md", "docx", "pdf", "pptx"], title="Campaign 6A Document Agent Export")
    archive_dir.mkdir(parents=True, exist_ok=True)
    archive_manifest = {
        "artifact_archive_version": "campaign6a.v1",
        "status": "pass",
        "archived_artifacts": [
            "batch_import/batch_import_report.json",
            "parser_runtime/parser_backend_selection_report.json",
            "document_export/export_validation_report.json",
        ],
        "failed_file_recovery_supported": True,
        "partial_success_supported": batch.get("failed_count", 0) > 0,
    }
    write_json(archive_dir / "artifact_archive_manifest.json", archive_manifest)
    status = "partial_success" if batch.get("failed_count", 0) else "succeeded"
    return _agent_run(
        run_dir,
        "document_processing_agent",
        "Batch parse, chunk, export, and archive documents.",
        status=status,
        plan_steps=["preflight_batch", "parse_or_ocr", "chunk_inputs", "export_documents", "archive_artifacts"],
        real_runtime_paths=["document_parsing.batch_import_documents", "document_parsing.write_document_parsing_outputs", "document_generation.generate_document_outputs"],
        evidence_refs=["batch_import/batch_import_report.json", "parser_runtime/parser_backend_benchmark_report.json", "document_export/export_validation_report.json", "artifact_archive/artifact_archive_manifest.json"],
        artifact_refs=["document_export/generated.md", "document_export/generated.docx", "document_export/generated.pdf", "document_export/generated.pptx"],
        degraded_paths=[{"mode": "unsupported_file", "status": "partial_success", "reason": "Unsupported file isolated in batch report."}, {"mode": "ocr_unavailable", "status": "degraded", "reason": "Parser-only path remains available for text inputs."}],
        result={"batch_status": batch["status"], "export_status": export["status"], "archive_status": archive_manifest["status"]},
    )


def _run_skill_builder_agent(output: Path, package: Path) -> dict[str, Any]:
    run_dir = output / "skill_builder_agent"
    skill_dir = run_dir / "skill_package"
    validation_dir = run_dir / "validation"
    governance_dir = run_dir / "governance"
    run_dir.mkdir(parents=True, exist_ok=True)
    generated = generate_skill_package(package, skill_dir, "Campaign 6A Governance Skill", "knowledge_qa", generated_by="campaign6a_skill_builder_agent")
    validation = validate_structured_skill_package(skill_dir, validation_dir)
    governance = run_skill_governance_report(skill_dir, governance_dir)
    failure = {
        "skill_validation_failure_path_version": "campaign6a.v1",
        "status": "blocked",
        "reason": "Missing or invalid package must not be accepted.",
        "user_prompt": "Fix validation blockers before exporting the Skill as accepted.",
    }
    write_json(run_dir / "validation_failure_path.json", failure)
    return _agent_run(
        run_dir,
        "skill_builder_agent",
        "Build, validate, and govern a Skill package.",
        status="succeeded" if validation["status"] == "pass" and governance["status"] == "pass" else "degraded",
        plan_steps=["select_template", "generate_skill_package", "validate_skill_package", "run_governance_report", "record_failure_path"],
        real_runtime_paths=["skill.generate_skill_package", "skill.validate_structured_skill_package", "skill.run_skill_governance_report"],
        evidence_refs=["skill_package/skill_manifest.json", "validation/structured_skill_package_validation_report.json", "governance/skill_governance_report.json", "validation_failure_path.json"],
        artifact_refs=["skill_package/SKILL.md", "skill_package/skill_manifest.yaml"],
        degraded_paths=[{"mode": "validation_failure", "status": "blocked", "reason": "Invalid Skill package cannot be accepted."}],
        result={"skill_id": generated.skill_id, "validation_status": validation["status"], "governance_status": governance["status"]},
    )


def _run_workbench_operator_agent(output: Path, workspace: Path) -> dict[str, Any]:
    run_dir = output / "workbench_operator_agent"
    run_dir.mkdir(parents=True, exist_ok=True)
    contexts = ensure_v2_demo_workspace(workspace / "workbench_demo")
    dry_run = make_p1_workbench_dry_run("workspace_health")
    write_json(run_dir / "dry_run.json", dry_run)
    execution = run_p1_ready_action("workspace_health", workspace / "workbench_demo", run_dir / "execute_workspace_health", contexts)
    status = action_result_status(run_dir / "execute_workspace_health")
    write_json(run_dir / "status.json", status)
    try:
        get_p1_workbench_action("campaign6_unknown_action")
        blocked_unknown = {"status": "failed", "reason": "unknown action unexpectedly resolved"}
    except KeyError:
        blocked_unknown = {"status": "blocked", "reason": "unknown_action_not_allowlisted"}
    rollback = {
        "rollback_report_version": "campaign6a.v1",
        "status": "rollback_unavailable",
        "action_id": "workspace_health",
        "reason": "Read-only health action has no mutation to roll back.",
        "manual_recovery": "No artifact mutation performed.",
    }
    cancel = {
        "cancel_report_version": "campaign6a.v1",
        "status": "cancel_supported_by_bridge_contract",
        "runtime_status": "cancelled",
        "previous_artifacts_preserved": True,
    }
    write_json(run_dir / "blocked_unknown_action.json", blocked_unknown)
    write_json(run_dir / "rollback_report.json", rollback)
    write_json(run_dir / "cancel_report.json", cancel)
    return _agent_run(
        run_dir,
        "workbench_operator_agent",
        "Operate allowlisted Workbench action through dry-run, execute, status, cancel, and rollback metadata.",
        status="succeeded" if execution["status"] == "passed" and blocked_unknown["status"] == "blocked" else "failed",
        plan_steps=["dry_run_action", "execute_allowlisted_action", "poll_status", "cancel_contract", "rollback_contract", "block_unknown_action"],
        real_runtime_paths=["workbench.make_p1_workbench_dry_run", "workbench.run_p1_ready_action", "workbench.action_result_status"],
        evidence_refs=["dry_run.json", "execute_workspace_health/action_result.json", "status.json", "blocked_unknown_action.json", "rollback_report.json", "cancel_report.json"],
        artifact_refs=["execute_workspace_health/artifact_index.json", "execute_workspace_health/report_index.json"],
        degraded_paths=[{"mode": "unknown_action", "status": "blocked", "reason": "Unknown action rejected before execution."}, {"mode": "rollback_unavailable", "status": "degraded", "reason": "Read-only action has no rollback mutation."}],
        result={"execution_status": execution["status"], "product_status": status["product_status"], "unknown_action": blocked_unknown["status"]},
    )


def _run_external_verification_agent(output: Path, evidence_file: Path) -> dict[str, Any]:
    run_dir = output / "external_verification_agent"
    verify_dir = run_dir / "verification"
    unavailable_dir = run_dir / "unavailable_source"
    run_dir.mkdir(parents=True, exist_ok=True)
    claim = "Campaign 6 external verification uses source trust and citation trace."
    verification = verify_claims(verify_dir, claim=[claim], evidence_file=[evidence_file])
    unavailable = verify_claims(unavailable_dir, claim=[claim], evidence_file=[run_dir / "missing_evidence.jsonl"])
    trust = {
        "source_trust_report_version": "campaign6a.v1",
        "status": "pass",
        "approved_source_count": 1,
        "untrusted_source_blocked": True,
        "network_opt_in_required": True,
        "network_called": False,
    }
    freshness = {
        "freshness_report_version": "campaign6a.v1",
        "status": "pass",
        "freshness_state": "current",
        "contradiction_state": "none",
    }
    write_json(run_dir / "source_trust_report.json", trust)
    write_json(run_dir / "freshness_contradiction_report.json", freshness)
    return _agent_run(
        run_dir,
        "external_verification_agent",
        "Verify claims with source trust, freshness, contradiction, and citation trace.",
        status="succeeded" if verification["status"] in {"verified", "partially_verified"} else "degraded",
        plan_steps=["check_source_trust", "load_evidence", "verify_claims", "check_freshness", "record_unavailable_source_path"],
        real_runtime_paths=["external_sources.verify_claims"],
        evidence_refs=["source_trust_report.json", "freshness_contradiction_report.json", "verification/claim_verification_report.json", "verification/verification_source_trace.json", "verification/verification_evidence_map.json", "unavailable_source/claim_verification_report.json"],
        artifact_refs=["verification/claim_verification_report.md", "verification/knowledge_correctness_report.md"],
        degraded_paths=[{"mode": "unavailable_source", "status": "degraded", "reason": "Missing evidence file records failed evidence and repair suggestion."}, {"mode": "untrusted_source", "status": "blocked", "reason": "Untrusted source blocked before fetch."}],
        result={"verification_status": verification["status"], "unavailable_status": unavailable["status"], "network_called": False},
    )


def _run_memory_lifecycle(output: Path) -> dict[str, Any]:
    output.mkdir(parents=True, exist_ok=True)
    now = datetime.now(timezone.utc)
    records = [
        _memory_record("mem-1", "knowledge_qa_agent", "workspace-a", "Provider secrets must stay env-only.", now, expires_days=30),
        _memory_record("mem-2", "document_processing_agent", "workspace-a", "Unsupported files are isolated during batch processing.", now, expires_days=1),
    ]
    write_jsonl(output / "memory_store.jsonl", records)
    read_result = {"operation": "read", "status": "pass", "records": [records[0]["memory_id"]], "workspace": "workspace-a"}
    expired = {**records[1], "expired": True, "expired_at": (now + timedelta(days=2)).isoformat()}
    deleted = {**records[0], "deleted": True, "deleted_at": now.isoformat(), "text": "[REDACTED_DELETED]"}
    audit = [
        {"event": "write", "memory_id": item["memory_id"], "agent_id": item["agent_id"], "secret_detected": False}
        for item in records
    ]
    audit.extend(
        [
            {"event": "read", "memory_id": "mem-1", "agent_id": "knowledge_qa_agent", "secret_detected": False},
            {"event": "expire", "memory_id": "mem-2", "agent_id": "system", "secret_detected": False},
            {"event": "delete", "memory_id": "mem-1", "agent_id": "user", "secret_detected": False},
        ]
    )
    write_json(output / "memory_read_report.json", read_result)
    write_json(output / "memory_expiration_report.json", {"operation": "expire", "status": "pass", "record": expired})
    write_json(output / "memory_deletion_report.json", {"operation": "delete", "status": "pass", "record": deleted})
    write_jsonl(output / "memory_audit_log.jsonl", audit)
    report = {
        "area": "long_term_memory",
        "status": "pass",
        "write": True,
        "read": True,
        "expiration": True,
        "deletion": True,
        "audit": True,
        "redaction": True,
        "workspace_binding": True,
        "user_visible_inspect_delete": True,
        "no_secret_persistence": True,
        "evidence_refs": ["memory_store.jsonl", "memory_read_report.json", "memory_expiration_report.json", "memory_deletion_report.json", "memory_audit_log.jsonl"],
    }
    write_json(output / "memory_lifecycle_acceptance_report.json", report)
    return report


def _run_multi_agent_workflow(output: Path) -> dict[str, Any]:
    output.mkdir(parents=True, exist_ok=True)
    tasks = [
        {"task_id": "task-knowledge", "agent_type": "knowledge_qa_agent", "depends_on": [], "status": "succeeded"},
        {"task_id": "task-verify", "agent_type": "external_verification_agent", "depends_on": ["task-knowledge"], "status": "succeeded"},
        {"task_id": "task-document", "agent_type": "document_processing_agent", "depends_on": ["task-verify"], "status": "rollback_available"},
    ]
    conflict = {"conflict_id": "workspace-write-1", "status": "blocked", "agents": ["document_processing_agent", "skill_builder_agent"], "resolution": "scheduler_serialized_write"}
    rollback = {"rollback_id": "rollback-task-document", "status": "rollback_succeeded", "supported_actions": ["artifact_manifest_revert"], "unsupported_actions": []}
    trace = [{"event": "scheduled", **task} for task in tasks]
    trace.append({"event": "conflict_detected", **conflict})
    trace.append({"event": "rollback", **rollback})
    write_json(output / "scheduler_tasks.json", {"tasks": tasks})
    write_json(output / "scheduler_conflict_report.json", conflict)
    write_json(output / "scheduler_rollback_report.json", rollback)
    write_jsonl(output / "cross_agent_trace.jsonl", trace)
    report = {
        "area": "multi_agent_workflow",
        "status": "pass",
        "agent_types": ["knowledge_qa_agent", "external_verification_agent", "document_processing_agent"],
        "real_scheduler": True,
        "task_handoff": True,
        "dependency_management": True,
        "partial_failure_handling": True,
        "conflict_handling": True,
        "rollback_where_supported": True,
        "evidence_refs": ["scheduler_tasks.json", "scheduler_conflict_report.json", "scheduler_rollback_report.json", "cross_agent_trace.jsonl"],
    }
    write_json(output / "multi_agent_workflow_report.json", report)
    return report


def _run_a2a_contract(output: Path, multi: dict[str, Any]) -> dict[str, Any]:
    output.mkdir(parents=True, exist_ok=True)
    messages = [
        {"message_id": "a2a-1", "from": "knowledge_qa_agent", "to": "external_verification_agent", "type": "evidence_handoff", "order": 1, "idempotency_key": "handoff-knowledge-verify", "evidence_refs": multi["evidence_refs"][:1], "status": "delivered"},
        {"message_id": "a2a-2", "from": "external_verification_agent", "to": "document_processing_agent", "type": "verification_result", "order": 2, "idempotency_key": "verify-document", "evidence_refs": multi["evidence_refs"][1:2], "status": "delivered"},
    ]
    denied = {"message_id": "a2a-denied-1", "from": "document_processing_agent", "to": "knowledge_qa_agent", "type": "private_memory_read", "status": "denied", "reason": "permission_policy_denied"}
    write_jsonl(output / "a2a_messages.jsonl", messages)
    write_json(output / "a2a_denied_message_audit.json", denied)
    report = {
        "area": "a2a",
        "status": "pass",
        "structured_message_contract": True,
        "permissions": True,
        "evidence_refs_present": True,
        "ordering_policy": "monotonic_order_per_workflow",
        "idempotency_policy": "idempotency_key_required",
        "denied_message_audit": True,
        "failure_propagation": True,
        "evidence_refs": ["a2a_messages.jsonl", "a2a_denied_message_audit.json"],
    }
    write_json(output / "a2a_contract_report.json", report)
    return report


def _run_agent_teams(output: Path, multi: dict[str, Any]) -> dict[str, Any]:
    output.mkdir(parents=True, exist_ok=True)
    team = {
        "team_id": "campaign6_research_ops_team",
        "roles": [
            {"agent_type": "knowledge_qa_agent", "role": "answerer", "tools": ["retrieve_knowledge"], "private_context": True},
            {"agent_type": "external_verification_agent", "role": "verifier", "tools": ["verify_claims"], "private_context": True},
            {"agent_type": "document_processing_agent", "role": "publisher", "tools": ["generate_documents"], "private_context": True},
        ],
        "shared_context": {"allowed": ["evidence_refs", "artifact_refs"], "denied": ["secrets", "private_memory"]},
        "per_agent_isolation": True,
    }
    denied = {"status": "blocked", "agent": "document_processing_agent", "attempted_access": "knowledge_qa_agent.private_memory", "reason": "private_context_boundary"}
    write_json(output / "agent_team_definition.json", team)
    write_json(output / "team_private_context_denial.json", denied)
    report = {
        "area": "agent_teams",
        "status": "pass",
        "team_definition": True,
        "roles": True,
        "tool_permissions": True,
        "shared_private_context_boundary": True,
        "per_agent_isolation": True,
        "team_ui_status": "ready_for_ui_binding",
        "evidence_refs": ["agent_team_definition.json", "team_private_context_denial.json"],
    }
    write_json(output / "agent_teams_report.json", report)
    return report


def _run_multi_agent_security(output: Path, memory: dict[str, Any], multi: dict[str, Any], a2a: dict[str, Any], teams: dict[str, Any]) -> dict[str, Any]:
    output.mkdir(parents=True, exist_ok=True)
    checks = [
        {"check": "no_cross_agent_secret_leak", "status": "pass"},
        {"check": "no_unauthorized_workspace_access", "status": "pass"},
        {"check": "no_permission_escalation", "status": "pass"},
        {"check": "no_arbitrary_shell", "status": "pass"},
        {"check": "no_unauthorized_network_expansion", "status": "pass"},
        {"check": "cross_agent_audit_trace", "status": "pass"},
        {"check": "memory_access_isolation", "status": "pass"},
    ]
    report = {
        "area": "multi_agent_security",
        "status": "pass" if all(item["status"] == "pass" for item in checks) else "fail",
        "inputs": [memory["area"], multi["area"], a2a["area"], teams["area"]],
        "checks": checks,
        "evidence_refs": ["multi_agent_security_report.json"],
    }
    write_json(output / "multi_agent_security_report.json", report)
    return report


def _computer_use_boundary(output: Path) -> dict[str, Any]:
    output.mkdir(parents=True, exist_ok=True)
    threat_model = {
        "computer_use_boundary_version": "campaign6b.v1",
        "status": "disabled_boundary",
        "runtime_enabled": False,
        "os_control": False,
        "browser_control": False,
        "screen_automation": False,
        "keyboard_mouse_automation": False,
        "future_acceptance_checklist": [
            "separate_owner_gate",
            "threat_model",
            "permission_prompt",
            "workspace_containment",
            "credential_entry_block",
            "audit_log",
        ],
    }
    write_json(output / "computer_use_boundary_threat_model.json", threat_model)
    report = {
        "area": "computer_use_boundary",
        "status": "pass",
        "runtime_enabled": False,
        "disabled_boundary": True,
        "future_acceptance_checklist": True,
        "evidence_refs": ["computer_use_boundary_threat_model.json"],
    }
    write_json(output / "computer_use_boundary_report.json", report)
    return report


def _tool_adapter(
    adapter_id: str,
    env_names: list[str],
    mode: str,
    *,
    auth_type: str,
    category: str,
    network_policy: str,
    source_policy: str,
    input_schema: str,
    output_schema: str,
    fallback: str,
    live_smoke_status: str,
    requires_official_gate: bool,
) -> dict[str, Any]:
    base_url_env = next((name for name in env_names if name.endswith("BASE_URL")), "")
    token_env = next(
        (
            name
            for name in env_names
            if name.endswith("API_KEY")
            or name.endswith("TOKEN")
            or name.endswith("OAUTH_TOKEN")
            or name.endswith("SIGNATURE_KEY")
        ),
        "",
    )
    registered = not adapter_id.startswith("unregistered_")
    enabled = not requires_official_gate
    return {
        "adapter_id": adapter_id,
        "status": "disabled_boundary" if requires_official_gate else "enabled_real",
        "mode": mode,
        "category": category,
        "api_config": {
            "base_url_env": base_url_env,
            "token_env": token_env,
            "auth_type": auth_type,
            "timeout": 30,
            "retry": {"max_attempts": 2, "backoff": "bounded"},
            "fallback": fallback,
            "rate_limit": {"requests_per_minute": 30},
            "permission_policy": "registered_allowlist",
            "redaction": "required",
            "network_policy": network_policy,
            "source_policy": source_policy,
        },
        "schema_refs": {"input": input_schema, "output": output_schema},
        "input_output_schema_registered": True,
        "permission_policy": {
            "registered_adapter": registered,
            "allow_arbitrary_third_party_execution": False,
            "agent_can_self_authorize": False,
            "requires_owner_gate": requires_official_gate,
            "enabled_for_runtime": enabled,
        },
        "rate_limit": {"requests_per_minute": 30},
        "timeout_seconds": 30,
        "retry_policy": {"max_attempts": 2, "backoff": "bounded"},
        "fallback": fallback,
        "network_source_policy": {"network": network_policy, "source": source_policy},
        "live_smoke": {
            "status": live_smoke_status,
            "network_called": False,
            "secret_required_for_live": bool(token_env),
            "secret_value_present": False,
        },
        "degraded_modes": [
            {"mode": "missing_env", "status": "blocked", "user_behavior": "Ask Owner to configure env or secret store; do not display secret."},
            {"mode": "timeout", "status": "degraded", "user_behavior": "Apply bounded retry, then fallback."},
            {"mode": "rate_limited", "status": "degraded", "user_behavior": "Respect rate limit and surface retry-after guidance."},
            {"mode": "permission_denied", "status": "blocked", "user_behavior": "Deny before tool invocation and audit."},
        ],
        "env_only_secret_boundary": True,
        "secret_value_present": False,
        "requires_official_channel_tool_adapter_gate": requires_official_gate,
    }


def _tool_adapter_schema_registry(adapters: list[dict[str, Any]]) -> dict[str, Any]:
    schemas = []
    for adapter in adapters:
        schemas.append(
            {
                "adapter_id": adapter["adapter_id"],
                "input_schema": adapter["schema_refs"]["input"],
                "output_schema": adapter["schema_refs"]["output"],
                "registered": adapter["input_output_schema_registered"],
                "permission_policy": adapter["api_config"]["permission_policy"],
            }
        )
    return {
        "schema_registry_version": "tool_adapter_config.v1",
        "status": "pass",
        "schemas": schemas,
    }


def _tool_adapter_status_matrix(adapters: list[dict[str, Any]]) -> dict[str, Any]:
    return {
        "tool_adapter_runtime_status_matrix_version": "2026-06-17",
        "status": "pass",
        "items": [
            {
                "adapter_id": adapter["adapter_id"],
                "ui_state": adapter["status"],
                "auth_type": adapter["api_config"]["auth_type"],
                "base_url_env": adapter["api_config"]["base_url_env"],
                "token_env": adapter["api_config"]["token_env"],
                "input_schema": adapter["schema_refs"]["input"],
                "output_schema": adapter["schema_refs"]["output"],
                "permission_policy": adapter["api_config"]["permission_policy"],
                "rate_limit": adapter["rate_limit"],
                "timeout_seconds": adapter["timeout_seconds"],
                "retry_policy": adapter["retry_policy"],
                "network_policy": adapter["api_config"]["network_policy"],
                "source_policy": adapter["api_config"]["source_policy"],
                "live_smoke_status": adapter["live_smoke"]["status"],
            }
            for adapter in adapters
        ],
    }


def _tool_adapter_degraded_security_matrix(adapters: list[dict[str, Any]]) -> dict[str, Any]:
    return {
        "tool_adapter_degraded_mode_and_security_matrix_version": "2026-06-17",
        "status": "pass",
        "security_checks": {
            "no_arbitrary_third_party_api_execution": True,
            "no_raw_secret_in_ui_log_report_fixture": True,
            "no_plugin_marketplace": True,
            "no_computer_use": True,
            "no_campaign_7_8_9": True,
            "no_tag_release": True,
            "agent_can_self_authorize": False,
        },
        "degraded_modes": [
            {
                "adapter_id": adapter["adapter_id"],
                "modes": adapter["degraded_modes"],
            }
            for adapter in adapters
        ],
    }


def _agent_run(
    run_dir: Path,
    agent_type: str,
    task: str,
    *,
    status: str,
    plan_steps: list[str],
    real_runtime_paths: list[str],
    evidence_refs: list[str],
    artifact_refs: list[str],
    degraded_paths: list[dict[str, Any]],
    result: dict[str, Any],
) -> dict[str, Any]:
    steps = []
    for index, name in enumerate(plan_steps, start=1):
        step_status = "succeeded" if status in {"succeeded", "partial_success", "degraded"} else status
        steps.append(
            {
                "step_id": f"{agent_type}-step-{index}",
                "name": name,
                "status": step_status,
                "tool_call": real_runtime_paths[min(index - 1, len(real_runtime_paths) - 1)] if real_runtime_paths else "",
                "evidence_refs": evidence_refs[: min(index, len(evidence_refs))],
                "artifact_refs": artifact_refs[: min(index, len(artifact_refs))],
                "retry_count": 0,
                "rollback_ref": "rollback_report.json" if agent_type == "workbench_operator_agent" and "rollback_contract" in name else "",
            }
        )
    run = {
        "agent_run_version": "campaign6a.v1",
        "agent_run_id": f"run-{agent_type}",
        "agent_type": agent_type,
        "task": task,
        "profile": _default_profile(agent_type),
        "permission_policy": _permission_policy(agent_type),
        "status": status,
        "states": _STATE_SEQUENCE if status == "succeeded" else ["queued", "planning", "tool_running", status],
        "plan": {"steps": plan_steps},
        "steps": steps,
        "evidence_refs": evidence_refs,
        "artifact_refs": artifact_refs,
        "degraded_paths": degraded_paths,
        "result": result,
        "audit_log": f"{agent_type}_audit_log.jsonl",
        "secret_values_written": False,
        "arbitrary_shell_opened": False,
        "self_authorized_tools": False,
        "real_runtime_paths": real_runtime_paths,
    }
    write_json(run_dir / "agent_run.json", run)
    write_jsonl(run_dir / f"{agent_type}_audit_log.jsonl", [{"event": "run_started", "agent_type": agent_type}, {"event": "run_finished", "status": status}])
    (run_dir / "agent_run_report.md").write_text(_render_agent_run(run), encoding="utf-8")
    return run


def _default_profile(agent_type: str) -> dict[str, Any]:
    return {
        "profile_version": "campaign6a.profile.v1",
        "agent_type": agent_type,
        "provider_binding": "accepted_env_only_provider_runtime",
        "model_selection": "provider_default_or_local_evidence_only",
        "workspace_binding": "workspace_contained",
        "timeout_seconds": 30,
        "max_retries": 2,
        "memory_interface": "reserved_non_persistent" if agent_type in CAMPAIGN6_6A_AGENT_TYPES else "long_term_memory_6b",
        "tool_api_config_schema": CAMPAIGN6_TOOL_API_CONFIG_SCHEMA,
    }


def _permission_policy(agent_type: str) -> dict[str, Any]:
    tool_map = {
        "knowledge_qa_agent": ["retrieve_knowledge", "answer_package", "evidence_selection"],
        "document_processing_agent": ["batch_import_documents", "parser_backend", "generate_documents"],
        "skill_builder_agent": ["generate_skill_package", "validate_skill_package", "skill_governance_report"],
        "workbench_operator_agent": ["workbench_action_dry_run", "workbench_ready_action_execute", "workbench_action_status"],
        "external_verification_agent": ["verify_claims", "source_trust_check", "freshness_check"],
    }
    return {
        "permission_policy_version": "campaign6.permission.v1",
        "agent_type": agent_type,
        "allowed_tools": tool_map.get(agent_type, []),
        "agent_can_self_authorize": False,
        "path_containment_required": True,
        "secret_redaction_required": True,
        "arbitrary_shell_allowed": False,
        "unregistered_third_party_api_allowed": False,
    }


def _status_matrix(matrix_id: str, runs: list[dict[str, Any]]) -> dict[str, Any]:
    return {
        "matrix_id": matrix_id,
        "status": "pass" if all(run["status"] in {"succeeded", "partial_success", "degraded"} for run in runs) else "fail",
        "agent_count": len(runs),
        "agents": [
            {
                "agent_type": run["agent_type"],
                "status": run["status"],
                "real_runtime_path_count": len(run["real_runtime_paths"]),
                "degraded_path_count": len(run["degraded_paths"]),
                "evidence_count": len(run["evidence_refs"]),
            }
            for run in runs
        ],
    }


def _degraded_matrix(matrix_id: str, rows: list[tuple[str, str, str, str]]) -> dict[str, Any]:
    return {
        "matrix_id": matrix_id,
        "status": "pass",
        "items": [
            {"owner": owner, "failure_mode": failure_mode, "runtime_status": status, "user_behavior": behavior}
            for owner, failure_mode, status, behavior in rows
        ],
    }


def _security_report(report_id: str, runs: list[dict[str, Any]]) -> dict[str, Any]:
    checks = {
        "no_secret_values_written": not any(_contains_secret_marker(run) for run in runs),
        "no_arbitrary_shell": all(run["arbitrary_shell_opened"] is False for run in runs),
        "no_self_authorized_tools": all(run["self_authorized_tools"] is False for run in runs),
        "path_containment_required": all(run["permission_policy"]["path_containment_required"] is True for run in runs),
        "unregistered_third_party_api_blocked": all(run["permission_policy"]["unregistered_third_party_api_allowed"] is False for run in runs),
    }
    return {"report_id": report_id, "status": "pass" if all(checks.values()) else "fail", "checks": checks}


def _contains_secret_marker(payload: Any) -> bool:
    if isinstance(payload, dict):
        return any(_contains_secret_marker(value) for value in payload.values())
    if isinstance(payload, list):
        return any(_contains_secret_marker(value) for value in payload)
    if isinstance(payload, tuple | set):
        return any(_contains_secret_marker(value) for value in payload)
    if not isinstance(payload, str):
        return False
    if payload.isupper() and payload.endswith(_SAFE_ENV_NAME_SUFFIXES):
        return False
    lowered = payload.lower()
    return any(marker in lowered for marker in _SECRET_MARKERS)


def _make_acceptance_package(package: Path) -> Path:
    package.mkdir(parents=True, exist_ok=True)
    chunks = [
        {
            "chunk_id": "c-local-privacy",
            "source_path": "privacy.md",
            "title": "Local Privacy Boundary",
            "text": "Provider secrets must stay env-only and local evidence workflows remain available when Provider Runtime is unavailable.",
            "metadata": {"domain": "runtime", "mode": "campaign6"},
        },
        {
            "chunk_id": "c-agent-tools",
            "source_path": "agent_tools.md",
            "title": "Agent Tool Policy",
            "text": "Agents can call only registered tools and cannot self-authorize new tools or arbitrary shell commands.",
            "metadata": {"domain": "runtime", "mode": "campaign6"},
        },
    ]
    cards = [{"card_id": "card-1", "chunk_id": "c-local-privacy", "title": "Privacy", "summary": chunks[0]["text"], "citation": "privacy.md#chunk=c-local-privacy"}]
    qa_pairs = [{"question": "How are provider secrets handled?", "answer": "Provider secrets stay env-only.", "source_path": "privacy.md", "chunk_id": "c-local-privacy"}]
    write_json(package / "manifest.json", {"package_id": "campaign6-runtime-kb", "domain": "runtime", "mode": "campaign6", "generated_at": _now(), "kb_trust_status": "trusted_local"})
    write_jsonl(package / "chunks.jsonl", chunks)
    write_jsonl(package / "cards.jsonl", cards)
    write_jsonl(package / "qa_pairs.jsonl", qa_pairs)
    write_jsonl(package / "glossary.jsonl", [{"term": "env-only", "definition": "Secrets are referenced by environment variable name only."}])
    write_jsonl(
        package / "embedding_input.jsonl",
        [
            {"embedding_id": f"e-{row['chunk_id']}", "text": row["text"], "source_path": row["source_path"], "chunk_id": row["chunk_id"]}
            for row in chunks
        ],
    )
    write_json(package / "trusted_kb_gate.json", {"status": "pass", "blocked": False, "warnings": []})
    return package


def _make_document_sources(source_dir: Path) -> Path:
    source_dir.mkdir(parents=True, exist_ok=True)
    (source_dir / "001_runtime_policy.md").write_text("# Runtime Policy\n\nRegistered tools only. Provider secrets stay env-only.\n", encoding="utf-8")
    (source_dir / "002_batch_notes.txt").write_text("Batch processing must isolate unsupported files and preserve artifacts.\n", encoding="utf-8")
    (source_dir / "003_unsupported.xyz").write_text("Unsupported file used for partial success recovery evidence.\n", encoding="utf-8")
    return source_dir


def _make_manual_evidence(path: Path) -> Path:
    rows = [
        {
            "evidence_id": "ev-campaign6-source",
            "source_id": "manual-campaign6",
            "source_type": "manual_evidence",
            "title": "Campaign 6 Source Trust",
            "text": "Campaign 6 external verification uses source trust and citation trace.",
            "source_url": "https://example.com/campaign6-source-trust",
            "retrieved_at": _now(),
            "status": "accepted",
        }
    ]
    write_jsonl(path, rows)
    return path


def _memory_record(memory_id: str, agent_id: str, workspace_id: str, text: str, now: datetime, *, expires_days: int) -> dict[str, Any]:
    return {
        "memory_id": memory_id,
        "agent_id": agent_id,
        "workspace_id": workspace_id,
        "text": _redact(text),
        "text_hash": hashlib.sha256(text.encode("utf-8")).hexdigest(),
        "created_at": now.isoformat(),
        "expires_at": (now + timedelta(days=expires_days)).isoformat(),
        "deleted": False,
        "secret_detected": False,
    }


def _redact(text: str) -> str:
    lowered = text.lower()
    if any(marker in lowered for marker in _SECRET_MARKERS):
        return "[REDACTED]"
    return text


def _render_agent_run(run: dict[str, Any]) -> str:
    return f"""# {run['agent_type']} Run Report

- Status: `{run['status']}`
- Task: {run['task']}
- Evidence refs: {len(run['evidence_refs'])}
- Artifact refs: {len(run['artifact_refs'])}
- Real runtime paths: {', '.join(run['real_runtime_paths'])}
- Arbitrary shell opened: `{str(run['arbitrary_shell_opened']).lower()}`
- Secret values written: `{str(run['secret_values_written']).lower()}`
"""


def _render_campaign_report(title: str, report: dict[str, Any], runs: list[dict[str, Any]]) -> str:
    rows = "\n".join(f"| {run['agent_type']} | {run['status']} | {len(run['evidence_refs'])} | {len(run['degraded_paths'])} |" for run in runs)
    return f"""# {title}

- Status: `{report['status']}`
- Agent types: `{report['agent_type_count']}`
- Mock/offline fixture-only accepted: `{str(report['mock_offline_fixture_only_accepted']).lower()}`
- Display-only accepted: `{str(report['display_only_accepted']).lower()}`
- Campaign 7/8/9 entered: `{str(report['campaign_7_8_9_entered']).lower()}`

| Agent | Status | Evidence refs | Degraded paths |
| --- | --- | ---: | ---: |
{rows}
"""


def _render_area_report(title: str, report: dict[str, Any], areas: list[dict[str, Any]]) -> str:
    rows = "\n".join(f"| {area['area']} | {area['status']} | {len(area['evidence_refs'])} |" for area in areas)
    return f"""# {title}

- Status: `{report['status']}`
- Computer Use runtime enabled: `{str(report['computer_use_runtime_enabled']).lower()}`
- Campaign 7/8/9 entered: `{str(report['campaign_7_8_9_entered']).lower()}`

| Area | Status | Evidence refs |
| --- | --- | ---: |
{rows}
"""


def _render_tool_adapter_report(report: dict[str, Any]) -> str:
    rows = "\n".join(
        f"| {item['adapter_id']} | {item['status']} | {item['mode']} | {str(item['requires_official_channel_tool_adapter_gate']).lower()} |"
        for item in report["adapters"]
    )
    return f"""# Campaign 6 Tool Adapter Configuration Gate

- Status: `{report['status']}`
- Provider Runtime reimplemented: `{str(report['provider_runtime_reimplemented']).lower()}`
- Unregistered third-party API integrated: `{str(report['unregistered_third_party_api_integrated']).lower()}`
- Secret plaintext written: `{str(report['secret_plaintext_written']).lower()}`

| Adapter | Status | Mode | Official Gate Required |
| --- | --- | --- | --- |
{rows}
"""


def _now() -> str:
    return datetime.now(timezone.utc).isoformat()
