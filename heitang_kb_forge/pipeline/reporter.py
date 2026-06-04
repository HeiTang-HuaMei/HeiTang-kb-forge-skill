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


def make_pipeline_report(*, config_file: Path, config: ForgeConfig, output: Path) -> tuple[PipelineManifest, str]:
    stages = [
        _stage("source_ingestion", True, output, ["chunks.jsonl"], config.task),
        _stage("knowledge_package", True, output, STANDARD_PACKAGE_FILES, config.task),
        _stage("quality_report", True, output, ["quality_report.json"], config.task),
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
    status = "success" if _files_exist(output, expected_files, task) else "failed"
    return PipelineStage(name=name, enabled=True, status=status, output_files=expected_files)


def _llm_output_files(config: ForgeConfig) -> list[str]:
    files = list(OUTPUT_FILES.values())
    if config.llm.quality_report:
        files.extend(LLM_QUALITY_OUTPUT_FILES)
    return files


def _files_exist(output: Path, expected_files: list[str], task: str) -> bool:
    if task == "build":
        return all((output / name).exists() for name in expected_files)
    manifest_path = output / "batch_manifest.json"
    if not manifest_path.exists():
        return False
    if expected_files == ["chunks.jsonl"]:
        return True
    return True


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
