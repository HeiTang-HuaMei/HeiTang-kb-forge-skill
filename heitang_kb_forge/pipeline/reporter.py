import json
from pathlib import Path

from heitang_kb_forge.agent.templates import AGENT_OUTPUT_FILES
from heitang_kb_forge.eval.demo import DEMO_OUTPUT_FILES
from heitang_kb_forge.llm.extractor import OUTPUT_FILES
from heitang_kb_forge.llm.quality import LLM_QUALITY_OUTPUT_FILES
from heitang_kb_forge.embedding.exporter import EMBEDDING_OUTPUT_FILES
from heitang_kb_forge.rag.exporter import RAG_OUTPUT_FILES
from heitang_kb_forge.downstream.exporter import DOWNSTREAM_OUTPUT_FILES
from heitang_kb_forge.validation.package_validator import VALIDATION_OUTPUT_FILES
from heitang_kb_forge.incremental.reuse import INCREMENTAL_OUTPUT_FILES
from heitang_kb_forge.knowledge_graph.exporter import KNOWLEDGE_GRAPH_OUTPUT_FILES
from heitang_kb_forge.knowledge_runtime import KB_RUNTIME_OUTPUT_FILES
from heitang_kb_forge.evalset.exporter import RETRIEVAL_EVAL_OUTPUT_FILES
from heitang_kb_forge.risk.labeler import RISK_OUTPUT_FILES
from heitang_kb_forge.runtime.agent_runtime import RUNTIME_OUTPUT_FILES
from heitang_kb_forge.workspace.registry import WORKSPACE_FILES
from heitang_kb_forge.refresh.checker import REFRESH_OUTPUT_FILES
from heitang_kb_forge.review.curation import REVIEW_OUTPUT_FILES
from heitang_kb_forge.eval_dashboard.recorder import EVAL_DASHBOARD_OUTPUT_FILES
from heitang_kb_forge.publish.profiles import PUBLISH_OUTPUT_FILES
from heitang_kb_forge.planning.readiness import PLANNING_OUTPUT_FILES
from heitang_kb_forge.vector.exporter import VECTOR_OUTPUT_FILES
from heitang_kb_forge.store.exporter import STORE_OUTPUT_FILES
from heitang_kb_forge.evidence_gate import EVIDENCE_GATE_OUTPUT_FILES
from heitang_kb_forge.multi_kb_orchestration import MULTI_KB_ORCHESTRATION_OUTPUT_FILES
from heitang_kb_forge.workbench_contracts import WORKBENCH_CONTRACT_OUTPUT_FILES
from heitang_kb_forge.schemas.config_schema import ForgeConfig
from heitang_kb_forge.schemas.pipeline_schema import PipelineManifest, PipelineStage

PIPELINE_OUTPUT_FILES = ["pipeline_report.md", "pipeline_manifest.json"]
STANDARD_PACKAGE_FILES = [
    "chunks.jsonl",
    "cards.jsonl",
    "qa_pairs.jsonl",
    "glossary.jsonl",
    "manifest.json",
    "ingest_report.md",
    "quality_report.json",
]
PARSER_BACKEND_OUTPUT_FILES = [
    "parser_backend_result.json",
    "parser_backend_output.md",
    "parser_backend_output.json",
    "parse_quality_report.json",
    "parse_quality_report.md",
    "ocr_risk_report.json",
    "high_risk_pages.jsonl",
    "high_risk_parse_pages.jsonl",
    "high_risk_chunks.jsonl",
    "manual_review_queue.jsonl",
    "kb_trust_status.json",
    "trusted_kb_gate.json",
    "knowledge_reliability_report.json",
]
PARSER_BACKEND_STAGE_NAMES = {
    "parser_backend_parse",
    "parse_quality_gate",
    "manual_parse_review_queue",
    "trusted_kb_gate",
    "knowledge_reliability_report",
}


def make_pipeline_report(*, config_file: Path, config: ForgeConfig, output: Path) -> tuple[PipelineManifest, str]:
    stages = [
        _stage("source_ingestion", True, output, ["chunks.jsonl"], config.task),
        _stage("knowledge_package", True, output, STANDARD_PACKAGE_FILES, config.task),
        _stage("quality_report", True, output, ["quality_report.json"], config.task),
        _stage("parser_backend_parse", config.parser_backend.use_for_build, output, ["parser_backend_result.json", "parser_backend_output.md", "parser_backend_output.json"], config.task),
        _stage("parse_quality_gate", config.parser_backend.use_for_build, output, ["parse_quality_report.json", "parse_quality_report.md", "ocr_risk_report.json"], config.task),
        _stage("manual_parse_review_queue", config.parser_backend.use_for_build, output, ["manual_review_queue.jsonl", "high_risk_chunks.jsonl", "high_risk_parse_pages.jsonl"], config.task),
        _stage("trusted_kb_gate", config.parser_backend.use_for_build, output, ["kb_trust_status.json", "trusted_kb_gate.json"], config.task),
        _stage("knowledge_reliability_report", config.parser_backend.use_for_build, output, ["knowledge_reliability_report.json"], config.task),
        _stage("pdf_preflight", _performance_enabled(config), output, ["pdf_preflight_report.json"], config.task),
        _stage("ocr_cache", config.performance.ocr_cache, output, ["ocr_cache_manifest.json"], config.task),
        _stage("ocr_processing", _performance_enabled(config) and config.performance.ocr_mode != "off", output, ["ocr_failed_pages.jsonl", "ocr_resume_report.md"], config.task),
        _stage("performance_report", _performance_enabled(config), output, ["large_file_performance_report.md"], config.task),
        _stage("progress_events", _progress_events_enabled(config), output, _progress_output_files(config), config.task),
        _stage("multimodal_asset_extraction", config.multimodal.enabled, output, ["multimodal_assets.jsonl", "multimodal_report.md"], config.task),
        _stage("multimodal_evidence_mapping", config.multimodal.enabled, output, ["multimodal_evidence_map.json"], config.task),
        _stage("package_contract_check", config.contract.check, output, ["contract_check_result.json", "contract_check_report.md"], config.task),
        _stage("governance_analysis", config.governance.enabled, output, ["governance_report.md"], config.task),
        _stage("package_diff", config.governance.enabled, output, ["package_diff.json", "package_diff_report.md"], config.task),
        _stage("lifecycle_status", config.governance.enabled, output, ["lifecycle_manifest.json", "lifecycle_report.md"], config.task),
        _stage("conflict_detection", config.governance.enabled, output, ["conflict_report.json", "conflict_report.md"], config.task),
        _stage("staleness_detection", config.governance.enabled, output, ["staleness_report.json", "staleness_report.md"], config.task),
        _stage("review_queue", config.governance.enabled, output, ["review_queue.jsonl", "review_queue_report.md"], config.task),
        _stage("retrieval_index", config.retrieval.enabled, output, ["retrieval_index.jsonl", "retrieval_manifest.json"], config.task),
        _stage("context_pack", config.retrieval.enabled, output, ["context_pack.json", "context_pack.md"], config.task),
        _stage("query_rewrite", config.query_rewrite.enabled, output, ["query_rewrite_report.json", "query_rewrite_trace.json"], config.task),
        _stage("retrieval_planning", config.query_rewrite.enabled, output, ["retrieval_plan.json", "retrieval_plan_report.md"], config.task),
        _stage("multi_query_recall", config.retrieval_quality.enabled, output, ["multi_query_recall_trace.json"], config.task),
        _stage("rerank", config.retrieval_quality.enabled, output, ["rerank_report.json"], config.task),
        _stage("evidence_selection", config.retrieval_quality.enabled, output, ["evidence_selection_trace.json"], config.task),
        _stage("retrieval_quality_eval", config.retrieval_quality.enabled, output, ["retrieval_quality_report.json", "retrieval_quality_report.md", "golden_query_eval_report.json"], config.task),
        _stage("claim_verification", config.retrieval_quality.enabled, output, ["claim_verification_report.json", "source_cross_check_report.json", "contradiction_map.json", "freshness_check_report.json", "verification_retrieval_trace.json"], config.task),
        _stage("knowledge_accuracy", config.retrieval_quality.enabled, output, ["knowledge_accuracy_report.json", "v38_external_absorption_map.json"], config.task),
        _stage("kb_index", config.knowledge_runtime.enabled, output, ["kb_index.jsonl", "kb_index_manifest.json"], config.task),
        _stage("kb_query", config.knowledge_runtime.enabled, output, ["kb_query_result.json", "kb_query_trace.json", "kb_citation_trace.json"], config.task),
        _stage("kb_answer", config.knowledge_runtime.enabled, output, ["kb_answer.md", "kb_answer_report.json"], config.task),
        _stage("retrieval_quality_report", config.knowledge_runtime.enabled, output, ["retrieval_quality_report.json"], config.task),
        _stage("rag_eval_baseline", config.knowledge_runtime.enabled, output, ["rag_eval_baseline.jsonl", "rag_eval_baseline_report.md"], config.task),
        _stage("document_generation", config.document_generation.enabled, output, _document_generation_output_files(config), config.task),
        _stage("evidence_gate", config.evidence_gate.enabled, output, EVIDENCE_GATE_OUTPUT_FILES, config.task),
        _stage("llm_provider_check", config.llm.enabled, output, [], config.task),
        _stage("llm_evidence_validation", config.llm.evidence_validation, output, ["llm_evidence_validation.json"], config.task),
        _stage("llm_boundary_judgment", config.llm.boundary_check, output, ["llm_boundary_judgment.json"], config.task),
        _stage("llm_hallucination_check", config.llm.hallucination_check, output, ["llm_hallucination_check.json"], config.task),
        _stage("skill_package_generation", config.skill.enabled, output / "skill_package", ["SKILL.md", "skill_manifest.yaml"], "build"),
        _stage("skill_validation", config.skill.enabled and config.skill.validate_skill, output / "skill_validation", ["skill_validation_result.json", "skill_validation_report.md"], "build"),
        _stage("llm_skill_generation", config.skill.enabled and config.skill.llm_generation and config.llm.enabled, output / "skill_package", ["llm_skill_generation_report.md"], "build"),
        _stage("enhanced_skill_template", config.skill.enabled and config.skill.enhanced_template, output / "skill_package", ["TASKS.md", "INPUT_OUTPUT.md", "skill_validation_result.json"], "build"),
        _stage("agent_package_generation", config.agent_package.enabled, output / "agent_package", ["soul.md", "system_prompt.md", "agent_profile.yaml"], "build"),
        _stage("llm_agent_generation", config.agent_package.enabled and config.agent_package.llm_generation and config.llm.enabled, output / "agent_package", ["llm_agent_generation_report.md"], "build"),
        _stage("agent_package_validation", config.agent_package.enabled, output / "agent_package", ["launch_checklist.md"], "build"),
        _stage("agent_compatibility", config.agent_package.enabled and config.agent_package.compat, output / "agent_package", ["compat/openclaw_agent.yaml", "agent_compat_check_result.json"], "build"),
        _stage("knowledge_bound_factory", config.knowledge_bound_factory.enabled, output, ["knowledge_bound_factory_manifest.json", "knowledge_bound_factory_trace.json", "knowledge_bound_factory_quality_report.json", "knowledge_bound_factory_report.md"], "build"),
        _stage("multi_kb_orchestration", config.multi_kb_orchestration.enabled, output, MULTI_KB_ORCHESTRATION_OUTPUT_FILES, "build"),
        _stage("skill_reverse_fusion", config.skill_reverse_fusion.enabled, output, ["skill_reverse_profiles.json", "skill_fusion_plan.json", "skill_reverse_fusion_trace.json", "skill_reverse_fusion_quality_report.json", "skill_reverse_fusion_report.md"], "build"),
        _stage("workbench_contracts", config.workbench_contracts.enabled, config.workbench_contracts.output or output, WORKBENCH_CONTRACT_OUTPUT_FILES, "build"),
        _stage("workspace_init", config.workspace.enabled, config.workspace.path or (output / "workspace"), ["workspace_manifest.json"], "build"),
        _stage("workspace_register", config.workspace.enabled and config.workspace.register_outputs, config.workspace.path or (output / "workspace"), ["registries/package_registry.jsonl"], "build"),
        _stage("relationship_graph_update", config.workspace.enabled and config.workspace.register_outputs, config.workspace.path or (output / "workspace"), ["registries/relationship_graph.json"], "build"),
        _stage("provider_registry_update", config.provider_registry.enabled, config.workspace.path or (output / "workspace"), ["registries/provider_registry.json"], "build"),
        _stage("prompt_profile_registry_update", config.prompt_profiles.enabled, config.workspace.path or (output / "workspace"), ["registries/prompt_profile_registry.json"], "build"),
        _stage("llm_call_audit_import", config.llm_audit.enabled, config.workspace.path or (output / "workspace"), ["registries/llm_call_audit.jsonl"], "build"),
        _stage("workspace_health_check", config.workspace.enabled and config.workspace.health_check, config.workspace.path or (output / "workspace"), ["reports/workspace_health_result.json", "reports/workspace_health_report.md"], "build"),
        _stage("studio_run", config.studio.enabled, config.studio.workspace or config.workspace.path or (output / "workspace"), ["studio_run_manifest.json", "studio_run_report.md", "release_checklist.md"], "build"),
        _stage("studio_v22_action_center", config.studio.enabled, config.studio.workspace or config.workspace.path or (output / "workspace"), ["action_center.json", "run_history.jsonl", "studio_v22_summary.json"], "build"),
        _stage("stable_contract_check", config.stable_check.enabled, config.studio.workspace or config.workspace.path or (output / "workspace"), ["stable_check_result.json", "stable_check_report.md"], "build"),
        _stage("provider_health_check", config.provider_health.enabled, config.studio.workspace or config.workspace.path or (output / "workspace"), ["provider_health_result.json", "provider_health_report.md"], "build"),
        _stage("provider_readiness", config.provider_readiness.enabled, config.provider_readiness.output or (output / "provider_readiness"), ["provider_readiness_result.json", "provider_readiness_report.md"], config.task),
        _stage("prompt_profile_versioning", config.prompt_profile_versioning.enabled, config.prompt_profile_versioning.output or (output / "prompt_profile_versions"), ["prompt_profile_versions.json", "prompt_profile_usage_report.md", "prompt_profile_hashes.json"], config.task),
        _stage("reliability_scoring", config.reliability.enabled, config.studio.workspace or config.workspace.path or (output / "workspace"), ["reliability_score.json", "reliability_report.md"], "build"),
        _stage("release_package", config.release_package.enabled, output / "release_package", ["release_manifest.json"], "build"),
        _stage("portfolio_demo_validation", False, output, [], config.task),
        _stage("extension_readiness", config.stable_check.enabled, config.studio.workspace or config.workspace.path or (output / "workspace"), ["stable_check_result.json"], "build"),
        _stage("input_coverage", config.input_hardening.enabled, output, ["input_coverage_report.md", "source_inventory_enhanced.json"], config.task),
        _stage("parser_hardening", config.input_hardening.enabled, output, ["parser_hardening_report.md"], config.task),
        _stage("knowledge_quality_scoring", config.quality.enabled, output, ["knowledge_quality_report.json", "knowledge_quality_report.md"], config.task),
        _stage("review_workflow", config.review.enabled or config.review.workflow, output, ["review_decisions.jsonl", "review_workflow_report.md"], config.task),
        _stage("curated_package_generation", config.review.curation, output, ["curated_chunks.jsonl", "curated_evidence_map.json"], config.task),
        _stage("retrieval_evaluation", config.retrieval_eval.enabled, output, ["retrieval_eval_cases.jsonl", "retrieval_eval_result.json", "retrieval_eval_report.md"], config.task),
        _stage("evidence_benchmark", config.evidence_benchmark.enabled, output, ["evidence_benchmark_result.json", "evidence_benchmark_report.md"], config.task),
        _stage("llm_quality_assist", config.llm_quality_assist.enabled, output, ["llm_quality_assist_report.md", "llm_review_suggestions.jsonl"], config.task),
        _stage("workspace_refresh", config.workspace_refresh.enabled, config.workspace_refresh.output or (output / "workspace_refresh"), ["source_change_report.json", "refresh_plan.json", "impacted_packages.json"], config.task),
        _stage("batch_job_manifest", config.task == "batch", output, ["batch_job_manifest.json"], config.task),
        _stage("batch_item_status", config.task == "batch", output, ["batch_item_status.jsonl"], config.task),
        _stage("batch_retry_recovery", config.batch.retry_failed or config.batch.resume_batch, output, ["batch_retry_report.md"], config.task),
        _stage("batch_quality_summary", config.task == "batch", output, ["batch_quality_summary.json"], config.task),
        _stage("batch_contract_summary", config.task == "batch", output, ["batch_contract_summary.json"], config.task),
        _stage("batch_governance_summary", config.task == "batch", output, ["batch_governance_summary.json"], config.task),
        _stage("package_version_graph", config.package_lineage.enabled, config.package_lineage.output or output, ["package_version_graph.json"], config.task),
        _stage("curated_package_generation_v23", config.curation.enabled or config.curation.build_curated_package, config.curation.output or (output / "curated_package"), ["curated_manifest.json", "curated_chunks.jsonl", "curated_evidence_map.json"], config.task),
        _stage("governance_decision_audit", config.curation.enabled or config.curation.build_curated_package, config.curation.output or (output / "curated_package"), ["governance_decisions.jsonl", "decision_audit_report.md"], config.task),
        _stage("update_impact_analysis", config.update_impact.enabled, config.update_impact.output or output, ["impacted_skills.json", "impacted_agents.json"], config.task),
        _stage(
            "platform_distribution",
            config.platform_distribution.enabled,
            config.platform_distribution.output or (output / "platform_distribution"),
            ["platform_manifest.json", "platform_upload_check_result.json", "mock_publish_result.json", "install_guide.md", "upload_guide.md"],
            config.task,
        ),
        _stage("quality_gate", config.quality_gate.enabled, config.quality_gate.output or output, ["quality_gate_result.json", "quality_gate_report.md"], config.task),
        _stage("release_blockers", config.release_blockers.enabled, config.release_blockers.output or output, ["release_blockers.json", "release_blockers.md"], config.task),
        _stage("regression_check", config.regression.enabled, config.regression.output or output, ["regression_result.json", "regression_report.md"], config.task),
        _stage("golden_sample_validation", config.golden_samples.enabled, config.golden_samples.output or output, ["golden_sample_validation.json", "golden_sample_validation_report.md"], config.task),
        _stage("platform_export_certification", config.export_certification.enabled, config.export_certification.output or output, ["platform_export_certification.json", "platform_export_certification_report.md"], config.task),
        _stage("compatibility_matrix", config.compatibility_matrix.enabled, config.compatibility_matrix.output or output, ["compatibility_matrix.json", "compatibility_matrix.md"], config.task),
        _stage("llm_quality_gate_assist", config.llm_quality_gate_assist.enabled, config.llm_quality_gate_assist.output or output, ["llm_quality_gate_assist_result.json", "llm_quality_gate_assist_report.md"], config.task),
        _stage("release_readiness", config.release_readiness.enabled, config.release_readiness.output or output, ["release_readiness_result.json", "release_readiness_report.md"], config.task),
        _stage("workspace_export", False, output, ["export_manifest.json"], config.task),
        _stage("llm_extraction", config.llm.enabled, output, _llm_output_files(config), config.task),
        _stage("rag_export", config.rag.enabled, output, RAG_OUTPUT_FILES, config.task),
        _stage("embedding_generation", config.embedding.enabled, output, EMBEDDING_OUTPUT_FILES, config.task),
        _stage("vector_export", config.vector.enabled, output, VECTOR_OUTPUT_FILES, config.task),
        _stage("agent_template", config.agent.enabled, output, AGENT_OUTPUT_FILES, config.task),
        _stage("demo_report", config.demo.enabled, output, DEMO_OUTPUT_FILES, config.task),
        _stage("package_validation", config.validation.enabled, output, VALIDATION_OUTPUT_FILES, config.task),
        _stage("downstream_export", config.downstream.enabled, output, DOWNSTREAM_OUTPUT_FILES, config.task),
        _stage("live_validation", config.live_validation.enabled, output, ["live_provider_smoke_report.json"], config.task),
        _stage("package_versioning", config.versioning.enabled, output, ["package_version.json"], config.task),
        _stage("incremental_reuse", config.incremental.enabled, output, INCREMENTAL_OUTPUT_FILES, config.task),
        _stage("source_registry", config.lifecycle.enabled, output, ["source_registry.json"], config.task),
        _stage("change_detection", config.lifecycle.enabled, output, ["source_change_report.md", "changed_sources.jsonl", "missing_sources.jsonl", "new_sources.jsonl"], config.task),
        _stage("incremental_update", config.lifecycle.enabled, output, ["incremental_update_report.md", "reused_chunks.jsonl", "rebuilt_chunks.jsonl"], config.task),
        _stage("missing_source_policy", config.lifecycle.enabled, output, ["stale_chunks.jsonl", "removed_source_impact_report.md"], config.task),
        _stage("update_quality_gate", config.lifecycle.enabled, output, ["update_quality_gate_report.json", "quality_regression_report.md"], config.task),
        _stage("retry_manifest", config.lifecycle.enabled, output, ["retry_manifest.json", "retry_report.md"], config.task),
        _stage("knowledge_graph_export", config.knowledge_graph.enabled, output, KNOWLEDGE_GRAPH_OUTPUT_FILES, config.task),
        _stage("retrieval_eval_export", config.retrieval_eval.enabled, output, RETRIEVAL_EVAL_OUTPUT_FILES, config.task),
        _stage("risk_labeling", config.risk_labels.enabled, output, RISK_OUTPUT_FILES, config.task),
        _stage("agent_runtime_smoke", config.runtime.enabled, output, RUNTIME_OUTPUT_FILES, config.task),
        _stage("workspace_registry", config.workspace.enabled, config.workspace.path or output, WORKSPACE_FILES, config.task),
        _stage("refresh_check", config.refresh.enabled, output, REFRESH_OUTPUT_FILES, config.task),
        _stage("review_queue", config.review.enabled, output, REVIEW_OUTPUT_FILES, config.task),
        _stage("evaluation_dashboard", config.evaluation_dashboard.enabled, output, EVAL_DASHBOARD_OUTPUT_FILES, config.task),
        _stage("publish_profile", config.publish.enabled, output, PUBLISH_OUTPUT_FILES, config.task),
        _stage("planning_readiness", config.planning_readiness.enabled, output, PLANNING_OUTPUT_FILES, config.task),
        _stage("local_store_init", config.store.enabled, output, [], config.task),
        _stage("local_store_import", config.store.enabled and config.store.import_package, output, [], config.task),
        _stage("local_store_export_index", config.store.enabled and config.store.export_index, output, STORE_OUTPUT_FILES, config.task),
        _stage("agent_rag_retrieve", config.agent_rag.enabled, output, ["retrieval_result.json", "retrieval_trace.json"], config.task),
        _stage("agent_rag_answer", config.agent_rag.enabled, output, ["answer.md", "answer_report.json"], config.task),
        _stage("citation_trace", config.agent_rag.enabled, output, ["citation_trace.json"], config.task),
    ]
    warnings = [f"Stage failed: {stage.name}" for stage in stages if stage.status == "failed"]
    final_status = "fail" if warnings else "pass"
    manifest = PipelineManifest(
        config_file=str(config_file).replace("\\", "/"),
        task=config.task,
        input=str(config.input).replace("\\", "/"),
        output=str(output).replace("\\", "/"),
        domain=config.domain,
        mode=config.mode,
        stages=stages,
        final_status=final_status,
        warnings=warnings,
    )
    return manifest, _render_report(manifest)


def _stage(name: str, enabled: bool, output: Path, expected_files: list[str], task: str) -> PipelineStage:
    if not enabled:
        return PipelineStage(name=name, enabled=False, status="skipped", output_files=[])
    if name in PARSER_BACKEND_STAGE_NAMES:
        status = "success" if _parser_backend_stage_passes(name, output, expected_files, task) else "failed"
    else:
        status = "success" if _files_exist(output, expected_files, task) else "failed"
    return PipelineStage(name=name, enabled=True, status=status, output_files=expected_files)


def _llm_output_files(config: ForgeConfig) -> list[str]:
    files = list(OUTPUT_FILES.values())
    if config.llm.quality_report:
        files.extend(LLM_QUALITY_OUTPUT_FILES)
    return files


def _document_generation_output_files(config: ForgeConfig) -> list[str]:
    files = [
        "generated_file_report.json",
        "generated_file_report.md",
        "document_generation_trace.json",
        "document_quality_report.json",
        "export_validation_report.json",
        "export_validation_report.md",
    ]
    for fmt in config.document_generation.formats:
        normalized = fmt.lower().lstrip(".")
        if normalized in {"md", "docx", "pdf", "pptx"}:
            files.insert(0, f"generated.{normalized}")
    return files


def _performance_enabled(config: ForgeConfig) -> bool:
    return any(
        [
            config.performance.progress,
            config.performance.progress_jsonl,
            config.performance.progress_log is not None,
            config.performance.profile != "production",
            config.performance.ocr_mode != "auto",
            config.performance.max_ocr_pages is not None,
            config.performance.ocr_pages is not None,
            config.performance.ocr_lang != "chi_sim+eng",
            config.performance.ocr_timeout_per_page != 120,
            config.performance.ocr_workers != 1,
            config.performance.ocr_cache,
            config.performance.ocr_cache_dir is not None,
            config.performance.resume,
            config.performance.ocr_scale != 1.5,
            not config.performance.skip_empty_pages,
            config.performance.skip_low_text_pages,
        ]
    )


def _progress_events_enabled(config: ForgeConfig) -> bool:
    return config.performance.progress or config.performance.progress_jsonl or config.performance.progress_log is not None


def _progress_output_files(config: ForgeConfig) -> list[str]:
    if config.performance.progress_log:
        return [str(config.performance.progress_log).replace("\\", "/")]
    if config.performance.progress_jsonl:
        return ["progress_events.jsonl"]
    return []


def _files_exist(output: Path, expected_files: list[str], task: str) -> bool:
    if not expected_files:
        return True
    if all((output / name).exists() if not Path(name).is_absolute() else Path(name).exists() for name in expected_files):
        return True
    if task == "build":
        return False
    manifest_path = output / "batch_manifest.json"
    if not manifest_path.exists():
        return False
    if expected_files == ["chunks.jsonl"]:
        return True
    return True


def _parser_backend_stage_passes(name: str, output: Path, expected_files: list[str], task: str) -> bool:
    package_outputs = _stage_package_outputs(output, task)
    if not package_outputs:
        return False
    return all(_parser_stage_package_passes(name, package, expected_files) for package in package_outputs)


def _stage_package_outputs(output: Path, task: str) -> list[Path]:
    if task == "build":
        return [output]
    manifest_path = output / "batch_manifest.json"
    if not manifest_path.exists():
        return []
    try:
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return []
    packages = []
    for item in manifest.get("items", []):
        if item.get("status") == "success" and item.get("output_path"):
            packages.append(Path(item["output_path"]))
    return packages


def _parser_stage_package_passes(name: str, package: Path, expected_files: list[str]) -> bool:
    if not all((package / file_name).exists() for file_name in expected_files):
        return False
    if name == "parser_backend_parse":
        payload = _read_json(package / "parser_backend_result.json")
        return payload.get("status") not in {"failed", "unavailable"}
    if name == "parse_quality_gate":
        payload = _read_json(package / "parse_quality_report.json")
        return payload.get("status") != "fail"
    if name == "trusted_kb_gate":
        payload = _read_json(package / "trusted_kb_gate.json")
        return payload.get("status") == "pass" and payload.get("blocked") is not True
    if name == "knowledge_reliability_report":
        payload = _read_json(package / "knowledge_reliability_report.json")
        return payload.get("status") != "fail"
    return True


def _read_json(path: Path) -> dict:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return {}


def _render_report(manifest: PipelineManifest) -> str:
    enabled_stages = "\n".join(
        f"- {stage.name}: {stage.status}" for stage in manifest.stages if stage.enabled
    ) or "- None"
    output_files = "\n".join(
        f"- {file_name}"
        for stage in manifest.stages
        for file_name in stage.output_files
    ) or "- None"
    stage_rows = "\n".join(
        f"| {stage.name} | {stage.enabled} | {stage.status} | {', '.join(stage.output_files) or '-'} |"
        for stage in manifest.stages
    )
    warnings = "\n".join(f"- {warning}" for warning in manifest.warnings) or "- None"
    return f"""# HeiTang KB Forge Pipeline Report

## Pipeline Summary

- Task: {manifest.task}
- Input: {manifest.input}
- Output: {manifest.output}
- Domain: {manifest.domain}
- Mode: {manifest.mode}

## Enabled Stages

{enabled_stages}

## Output Files

{output_files}

## Stage Status

| Stage | Enabled | Status | Output Files |
| --- | --- | --- | --- |
{stage_rows}

## Final Result

- Status: {manifest.final_status}
- Warnings:
{warnings}

## Next Steps

- Inspect demo_report.md
- Inspect quality_report.json
- Inspect rag_manifest.json
- Inspect agent_profile.yaml
"""
