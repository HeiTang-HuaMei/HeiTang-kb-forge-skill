from pathlib import Path
from datetime import datetime, timezone
from dataclasses import dataclass
import os
import re

import typer

from heitang_kb_forge.agent.generator import make_agent_template
from heitang_kb_forge.agent_package import AGENT_PACKAGE_FILES, generate_agent_package
from heitang_kb_forge.agent_compat import export_agent_compat
from heitang_kb_forge.agent.templates import AGENT_OUTPUT_FILES
from heitang_kb_forge.agent_rag.answerer import answer_from_records
from heitang_kb_forge.agent_rag.retriever import retrieve_from_package, retrieve_from_store
from heitang_kb_forge.agent_rag.scope import parse_scope
from heitang_kb_forge.agent_tools.exporter import make_tool_exports
from heitang_kb_forge.agent_tools.invoker import invoke_tool
from heitang_kb_forge.agent_tools.registry import get_agent_tool, list_agent_tools
from heitang_kb_forge.batch_jobs import build_job_outputs, retry_failed_items, write_job_outputs
from heitang_kb_forge.batch_jobs.report import write_batch_summaries
from heitang_kb_forge.config.loader import load_config
from heitang_kb_forge.contracts.checker import check_package_contract
from heitang_kb_forge.contracts.report import make_contract_report
from heitang_kb_forge.contracts.stable_checker import run_stable_check
from heitang_kb_forge.doctor import run_doctor
from heitang_kb_forge.downstream.exporter import DOWNSTREAM_OUTPUT_FILES, make_downstream_exports
from heitang_kb_forge.embedding.exporter import EMBEDDING_OUTPUT_FILES, make_embeddings
from heitang_kb_forge.eval.demo import DEMO_OUTPUT_FILES, make_demo_report
from heitang_kb_forge.evidence_gate import EVIDENCE_GATE_OUTPUT_FILES, run_evidence_gate
from heitang_kb_forge.evalset.exporter import RETRIEVAL_EVAL_OUTPUT_FILES, make_retrieval_eval_set
from heitang_kb_forge.exporters.jsonl_exporter import write_json, write_jsonl
from heitang_kb_forge.governance import GOVERNANCE_OUTPUT_FILES, run_governance
from heitang_kb_forge.hardening.batch import make_batch_hardening_outputs
from heitang_kb_forge.hardening.run_trace import make_run_manifest, new_run_id, now_iso, stage_record
from heitang_kb_forge.incremental.reuse import INCREMENTAL_OUTPUT_FILES, make_incremental_report
from heitang_kb_forge.knowledge_graph.exporter import KNOWLEDGE_GRAPH_OUTPUT_FILES, make_knowledge_graph
from heitang_kb_forge.lifecycle.change_detector import (
    LIFECYCLE_OUTPUT_FILES,
    detect_source_changes,
    load_source_registry,
    make_incremental_outputs,
    make_update_quality_gate,
    render_source_change_report,
)
from heitang_kb_forge.lifecycle.source_registry import make_source_registry
from heitang_kb_forge.eval_dashboard.recorder import make_eval_dashboard
from heitang_kb_forge.exporters.report_exporter import write_report
from heitang_kb_forge.llm.extractor import LLMOptions, OUTPUT_FILES, extract_llm_assets
from heitang_kb_forge.llm.agent_package_generator import generate_llm_agent_package
from heitang_kb_forge.llm.boundary_judge import judge_boundary_with_llm
from heitang_kb_forge.llm.call_log import write_call_log
from heitang_kb_forge.llm.audit import import_llm_call_logs
from heitang_kb_forge.llm.audit_report import render_llm_audit_report
from heitang_kb_forge.llm.evidence_validator import validate_evidence_with_llm
from heitang_kb_forge.llm.hallucination_checker import check_hallucination_with_llm
from heitang_kb_forge.llm.provider import ProviderSettings
from heitang_kb_forge.llm.validation_report import render_llm_evidence_report
from heitang_kb_forge.llm.prompt_profile import load_prompt_profile
from heitang_kb_forge.llm.provider_health import check_provider_health
from heitang_kb_forge.llm.skill_generator import generate_llm_skill_package
from heitang_kb_forge.master_skill import (
    analyze_master_skill,
    generate_derived_skill,
    import_master_skill,
    run_skill_safety_check,
    run_skill_similarity_check,
)
from heitang_kb_forge.llm.quality import LLM_QUALITY_OUTPUT_FILES, make_llm_quality_report
from heitang_kb_forge.ocr.report import make_performance_report, make_resume_report
from heitang_kb_forge.multimodal.classifier import IMAGE_SUFFIXES
from heitang_kb_forge.multimodal.builder import MultimodalOptions, build_multimodal_assets
from heitang_kb_forge.parsers.docx_parser import parse_docx
from heitang_kb_forge.parsers.hardening import parse_epub, parse_html, parse_zip
from heitang_kb_forge.parsers.image_parser import parse_image
from heitang_kb_forge.parsers.markdown_parser import parse_markdown
from heitang_kb_forge.parsers.pdf_parser import PDFParseOptions, parse_pdf
from heitang_kb_forge.parsers.slide_parser import parse_slide
from heitang_kb_forge.parsers.table_parser import parse_csv, parse_tsv, parse_xlsx
from heitang_kb_forge.parsers.text_parser import parse_text
from heitang_kb_forge.processors.chunker import chunk_text
from heitang_kb_forge.processors.chunk_profiles import get_chunk_profile
from heitang_kb_forge.processors.cleaner import clean_text
from heitang_kb_forge.processors.extractor import make_cards, make_glossary, make_qa_pairs
from heitang_kb_forge.processors.quality import make_quality_report
from heitang_kb_forge.processors.validator import validate_chunks
from heitang_kb_forge.pipeline.reporter import make_pipeline_report
from heitang_kb_forge.package_lineage import make_package_lineage
from heitang_kb_forge.platform_distribution import check_platform_upload, export_platform_package, mock_publish_package
from heitang_kb_forge.progress.reporter import ProgressReporter, make_progress_reporter
from heitang_kb_forge.quality_gate.gate import QUALITY_GATE_OUTPUT_FILES, evaluate_quality_gate
from heitang_kb_forge.quality_gate import run_quality_gate
from heitang_kb_forge.quality import V21_OUTPUT_FILES, make_v21_quality_outputs
from heitang_kb_forge.release_blockers import detect_release_blockers
from heitang_kb_forge.regression import run_regression_check
from heitang_kb_forge.golden_samples import validate_golden_samples
from heitang_kb_forge.export_certification import certify_platform_export
from heitang_kb_forge.export_certification.compatibility import make_compatibility_matrix
from heitang_kb_forge.release_readiness import evaluate_release_readiness
from heitang_kb_forge.llm.quality_gate_assist import run_llm_quality_gate_assist
from heitang_kb_forge.rag.exporter import RAGOptions, RAG_OUTPUT_FILES, make_rag_export
from heitang_kb_forge.release import make_release_package
from heitang_kb_forge.reliability import make_reliability_score
from heitang_kb_forge.retrieval import RETRIEVAL_OUTPUT_FILES, build_retrieval_outputs
from heitang_kb_forge.retrieval.index_builder import build_retrieval_index
from heitang_kb_forge.refresh.checker import make_refresh_plan
from heitang_kb_forge.risk.labeler import RISK_OUTPUT_FILES, make_risk_labels
from heitang_kb_forge.runtime.agent_runtime import RUNTIME_OUTPUT_FILES, ask_package
from heitang_kb_forge.skill import SKILL_PACKAGE_FILES, generate_skill_package
from heitang_kb_forge.skill_validation import SKILL_VALIDATION_FILES, validate_skill_package
from heitang_kb_forge.skill_templates import render_enhanced_skill_template
from heitang_kb_forge.studio import finalize_studio_workspace
from heitang_kb_forge.studio_v22 import write_studio_v22_outputs
from heitang_kb_forge.review.curation import apply_review_decisions, create_review_queue, empty_decision_template
from heitang_kb_forge.publish.profiles import make_publish_package
from heitang_kb_forge.planning.readiness import make_planning_readiness
from heitang_kb_forge.providers import add_provider, list_providers
from heitang_kb_forge.providers.readiness import make_provider_readiness
from heitang_kb_forge.prompt_profiles import add_prompt_profile, list_prompt_profiles
from heitang_kb_forge.prompt_profiles.versioning import make_prompt_profile_versions
from heitang_kb_forge.validation.package_validator import VALIDATION_OUTPUT_FILES, validate_package
from heitang_kb_forge.vector.exporter import VECTOR_OUTPUT_FILES, make_vector_export
from heitang_kb_forge.versioning.diff import DIFF_OUTPUT_FILES, diff_packages
from heitang_kb_forge.versioning.package_version import make_package_version
from heitang_kb_forge.workspace.registry import init_workspace, register_package, workspace_status
from heitang_kb_forge.workspace.exporter import export_workspace
from heitang_kb_forge.workspace.health import check_workspace_health
from heitang_kb_forge.workspace.importer import import_workspace_asset
from heitang_kb_forge.workspace.initializer import init_portable_workspace
from heitang_kb_forge.workspace.search import search_workspace
from heitang_kb_forge.workspace.v19_registry import list_workspace_assets, register_workspace_asset
from heitang_kb_forge.workspace_refresh import make_workspace_refresh
from heitang_kb_forge.schemas.config_schema import ForgeConfig
from heitang_kb_forge.schemas.chunk_schema import Chunk
from heitang_kb_forge.schemas.agent_schema import AgentOptions
from heitang_kb_forge.schemas.manifest_schema import Manifest
from heitang_kb_forge.mcp.config import make_mcp_config
from heitang_kb_forge.store.db import init_store
from heitang_kb_forge.store.exporter import STORE_OUTPUT_FILES, export_store_index
from heitang_kb_forge.store.importer import import_package, sync_workspace
from heitang_kb_forge.store.query import list_packages, package_status, query_packages
from heitang_kb_forge.curation import build_curated_package
from heitang_kb_forge.update_impact import analyze_update_impact

app = typer.Typer(help="Build local standardized knowledge base packages.")
workspace_app = typer.Typer(help="Manage local knowledge package workspaces.")
store_app = typer.Typer(help="Manage local SQLite knowledge store indexes.")
tools_app = typer.Typer(help="Export and invoke local Agent-callable tool declarations.")
mcp_app = typer.Typer(help="Export MCP readiness configuration.")
app.add_typer(workspace_app, name="workspace")
app.add_typer(store_app, name="store")
app.add_typer(tools_app, name="tools")
app.add_typer(mcp_app, name="mcp")

PARSERS = {
    ".md": parse_markdown,
    ".markdown": parse_markdown,
    ".txt": parse_text,
    ".html": parse_html,
    ".htm": parse_html,
    ".pdf": parse_pdf,
    ".docx": parse_docx,
    ".csv": parse_csv,
    ".tsv": parse_tsv,
    ".xlsx": parse_xlsx,
    ".epub": parse_epub,
    ".zip": parse_zip,
    ".png": parse_image,
    ".jpg": parse_image,
    ".jpeg": parse_image,
    ".ppt": parse_slide,
    ".pptx": parse_slide,
}


@dataclass
class ConfigRunResult:
    config: ForgeConfig
    output: Path
    message: str


@dataclass
class EmbeddingOptions:
    enabled: bool = False
    provider: str = "fake"
    model: str = "fake-embedding-model"


@dataclass
class VectorOptions:
    enabled: bool = False
    store: str = "local_json"


@dataclass
class ValidationOptions:
    enabled: bool = False


@dataclass
class DownstreamOptions:
    enabled: bool = False


@dataclass
class V11Options:
    versioning: bool = False
    incremental: bool = False
    previous_package: Path | None = None
    chunk_profile: str = "default"
    knowledge_graph: bool = False
    retrieval_eval: bool = False
    risk_labels: bool = False
    runtime: bool = False
    runtime_top_k: int = 5
    runtime_provider: str = "fake"
    runtime_model: str = "fake-model"


@dataclass
class HardeningOptions:
    quality_gate: bool = False
    quality_gate_strict: bool = False
    run_manifest: bool = False


@dataclass
class V21Options:
    input_coverage: bool = False
    parser_hardening: bool = False
    quality_score: bool = False
    review_workflow: bool = False
    retrieval_eval: bool = False
    evidence_benchmark: bool = False
    llm_quality_assist: bool = False


@dataclass
class BatchJobOptions:
    profile: str = "production"
    retry_enabled: bool = True
    resume_enabled: bool = True


@dataclass
class LifecycleOptions:
    enabled: bool = False
    update_mode: str = "full"
    previous_package: Path | None = None
    missing_source_policy: str = "mark_stale"
    quality_gate: bool = False
    retry_manifest: Path | None = None


@dataclass
class StoreOptions:
    enabled: bool = False
    db_path: Path | None = None
    import_package: bool = False
    export_index: bool = False


@dataclass
class PerformanceOptions:
    enabled: bool = False
    progress: bool = False
    progress_jsonl: bool = False
    progress_log: Path | None = None
    verbose: bool = False
    profile: str = "production"
    ocr_mode: str = "auto"
    ocr_lang: str = "chi_sim+eng"
    ocr_timeout_per_page: int = 120
    max_ocr_pages: int | None = None
    ocr_pages: str | None = None
    ocr_workers: int = 1
    ocr_scale: float = 1.5
    ocr_cache: bool = False
    ocr_cache_dir: Path | None = None
    resume: bool = False
    skip_empty_pages: bool = True
    skip_low_text_pages: bool = False


@dataclass
class ContractOptions:
    version: str | None = None
    check: bool = False
    strict: bool = False


@dataclass
class GovernanceOptions:
    enabled: bool = False
    previous_package: Path | None = None


@dataclass
class RetrievalIndexOptions:
    enabled: bool = False
    query: str = "Summarize this knowledge package."


@dataclass
class EvidenceGateOptions:
    enabled: bool = False
    query: str = "Summarize this knowledge package."


HARDENING_TRACE_FILES = ["run_manifest.json", "stage_trace.jsonl", "error_report.json"]


@app.callback()
def main() -> None:
    """KB Forge command group."""


@app.command()
def build(
    input: Path = typer.Option(..., "--input", "-i", exists=True, file_okay=True, dir_okay=True, readable=True),
    output: Path = typer.Option(..., "--output", "-o"),
    domain: str = typer.Option("general", "--domain"),
    mode: str = typer.Option("reference", "--mode"),
    max_chars: int = typer.Option(1200, "--max-chars"),
    overlap_chars: int = typer.Option(120, "--overlap-chars"),
    llm: bool = typer.Option(False, "--llm"),
    llm_provider: str = typer.Option("fake", "--llm-provider"),
    llm_model: str = typer.Option("fake-model", "--llm-model"),
    llm_cache: bool = typer.Option(True, "--llm-cache/--no-llm-cache"),
    llm_strict: bool = typer.Option(False, "--llm-strict"),
    prompt_profile: Path | None = typer.Option(None, "--prompt-profile"),
    llm_quality_report: bool = typer.Option(False, "--llm-quality-report"),
    rag_export: bool = typer.Option(False, "--rag-export"),
    rag_profile: str = typer.Option("basic", "--rag-profile"),
    rag_include_llm: bool = typer.Option(False, "--rag-include-llm"),
    embedding: bool = typer.Option(False, "--embedding"),
    embedding_provider: str = typer.Option("fake", "--embedding-provider"),
    embedding_model: str = typer.Option("fake-embedding-model", "--embedding-model"),
    vector_export: bool = typer.Option(False, "--vector-export"),
    vector_store: str = typer.Option("local_json", "--vector-store"),
    validate_package: bool = typer.Option(False, "--validate-package"),
    downstream_export: bool = typer.Option(False, "--downstream-export"),
    incremental: bool = typer.Option(False, "--incremental"),
    previous_package: Path | None = typer.Option(None, "--previous-package", exists=True, file_okay=False, dir_okay=True),
    lifecycle: bool = typer.Option(False, "--lifecycle"),
    update_mode: str = typer.Option("full", "--update-mode"),
    missing_source_policy: str = typer.Option("mark_stale", "--missing-source-policy"),
    retry_manifest: Path | None = typer.Option(None, "--retry-manifest", exists=True, file_okay=True, dir_okay=False),
    chunk_profile: str = typer.Option("default", "--chunk-profile"),
    knowledge_graph_export: bool = typer.Option(False, "--knowledge-graph-export"),
    retrieval_eval_export: bool = typer.Option(False, "--retrieval-eval-export"),
    risk_labels: bool = typer.Option(False, "--risk-labels"),
    quality_gate: bool = typer.Option(False, "--quality-gate"),
    quality_gate_strict: bool = typer.Option(False, "--quality-gate-strict"),
    run_manifest: bool = typer.Option(False, "--run-manifest"),
    input_coverage_report: bool = typer.Option(False, "--input-coverage-report"),
    parser_hardening_report: bool = typer.Option(False, "--parser-hardening-report"),
    quality_score: bool = typer.Option(False, "--quality-score"),
    review_workflow: bool = typer.Option(False, "--review-workflow"),
    retrieval_eval: bool = typer.Option(False, "--retrieval-eval"),
    evidence_benchmark: bool = typer.Option(False, "--evidence-benchmark"),
    llm_quality_assist: bool = typer.Option(False, "--llm-quality-assist"),
    agent_template: bool = typer.Option(False, "--agent-template"),
    agent_type: str = typer.Option("generic_agent", "--agent-type"),
    agent_name: str | None = typer.Option(None, "--agent-name"),
    agent_language: str = typer.Option("zh-CN", "--agent-language"),
    demo_report: bool = typer.Option(False, "--demo-report"),
    progress: bool = typer.Option(False, "--progress"),
    progress_jsonl: bool = typer.Option(False, "--progress-jsonl"),
    progress_log: Path | None = typer.Option(None, "--progress-log"),
    verbose: bool = typer.Option(False, "--verbose"),
    profile: str = typer.Option("production", "--profile"),
    ocr_mode: str = typer.Option("auto", "--ocr-mode"),
    ocr_lang: str = typer.Option("chi_sim+eng", "--ocr-lang"),
    ocr_timeout_per_page: int = typer.Option(120, "--ocr-timeout-per-page"),
    max_ocr_pages: int | None = typer.Option(None, "--max-ocr-pages"),
    ocr_pages: str | None = typer.Option(None, "--ocr-pages"),
    ocr_workers: int = typer.Option(1, "--ocr-workers"),
    ocr_scale: float = typer.Option(1.5, "--ocr-scale"),
    ocr_cache: bool = typer.Option(False, "--ocr-cache"),
    ocr_cache_dir: Path | None = typer.Option(None, "--ocr-cache-dir"),
    resume: bool = typer.Option(False, "--resume"),
    skip_empty_pages: bool = typer.Option(True, "--skip-empty-pages/--no-skip-empty-pages"),
    skip_low_text_pages: bool = typer.Option(False, "--skip-low-text-pages"),
    multimodal: bool = typer.Option(False, "--multimodal"),
    multimodal_images: bool = typer.Option(True, "--multimodal-images/--no-multimodal-images"),
    multimodal_charts: bool = typer.Option(True, "--multimodal-charts/--no-multimodal-charts"),
    multimodal_slides: bool = typer.Option(True, "--multimodal-slides/--no-multimodal-slides"),
    multimodal_formulas: bool = typer.Option(True, "--multimodal-formulas/--no-multimodal-formulas"),
    multimodal_mindmaps: bool = typer.Option(True, "--multimodal-mindmaps/--no-multimodal-mindmaps"),
    multimodal_report: bool = typer.Option(True, "--multimodal-report/--no-multimodal-report"),
    contract_version: str | None = typer.Option(None, "--contract-version"),
    check_contract: bool = typer.Option(False, "--check-contract"),
    governance: bool = typer.Option(False, "--governance"),
    retrieval_index: bool = typer.Option(False, "--retrieval-index"),
    evidence_gate: bool = typer.Option(False, "--evidence-gate"),
    evidence_query: str = typer.Option("Summarize this knowledge package.", "--evidence-query"),
) -> None:
    """Parse source files and write a V0 knowledge base package."""
    manifest = _build_package(
        input,
        output,
        domain,
        mode,
        max_chars,
        overlap_chars,
        llm_options=_make_llm_options(
            llm,
            llm_provider,
            llm_model,
            llm_cache,
            llm_strict,
            prompt_profile,
            llm_quality_report,
        ),
        rag_options=RAGOptions(rag_export, rag_profile, rag_include_llm),
        agent_options=AgentOptions(
            enabled=agent_template,
            agent_type=agent_type,
            agent_name=agent_name,
            language=agent_language,
        ),
        embedding_options=_make_embedding_options(embedding, embedding_provider, embedding_model, rag_export),
        vector_options=_make_vector_options(vector_export, vector_store, embedding),
        validation_options=ValidationOptions(validate_package),
        downstream_options=DownstreamOptions(downstream_export),
        v11_options=V11Options(
            versioning=incremental,
            incremental=incremental,
            previous_package=previous_package,
            chunk_profile=chunk_profile,
            knowledge_graph=knowledge_graph_export,
            retrieval_eval=retrieval_eval_export,
            risk_labels=risk_labels,
        ),
        lifecycle_options=LifecycleOptions(
            enabled=lifecycle or update_mode != "full" or retry_manifest is not None,
            update_mode=update_mode,
            previous_package=previous_package,
            missing_source_policy=missing_source_policy,
            quality_gate=quality_gate or quality_gate_strict,
            retry_manifest=retry_manifest,
        ),
        hardening_options=HardeningOptions(quality_gate or quality_gate_strict, quality_gate_strict, run_manifest),
        v21_options=V21Options(
            input_coverage_report,
            parser_hardening_report,
            quality_score,
            review_workflow,
            retrieval_eval,
            evidence_benchmark,
            llm_quality_assist,
        ),
        performance_options=_make_performance_options(
            progress,
            progress_jsonl,
            progress_log,
            verbose,
            profile,
            ocr_mode,
            ocr_lang,
            ocr_timeout_per_page,
            max_ocr_pages,
            ocr_pages,
            ocr_workers,
            ocr_scale,
            ocr_cache,
            ocr_cache_dir,
            resume,
            skip_empty_pages,
            skip_low_text_pages,
        ),
        multimodal_options=MultimodalOptions(
            enabled=multimodal,
            images=multimodal_images,
            charts=multimodal_charts,
            slides=multimodal_slides,
            formulas=multimodal_formulas,
            mindmaps=multimodal_mindmaps,
            report=multimodal_report,
        ),
        contract_options=ContractOptions(contract_version, check_contract, False),
        governance_options=GovernanceOptions(governance, previous_package),
        retrieval_index_options=RetrievalIndexOptions(retrieval_index, evidence_query),
        evidence_gate_options=EvidenceGateOptions(evidence_gate, evidence_query),
        demo_report=demo_report,
    )

    typer.echo(f"Built knowledge package at {output}")
    typer.echo(f"Sources: {manifest.source_count} | Chunks: {manifest.chunk_count} | Warnings: {len(manifest.warnings)}")


@app.command()
def govern(
    package: Path = typer.Option(..., "--package", exists=True, file_okay=False, dir_okay=True, readable=True),
    output: Path = typer.Option(..., "--output", "-o"),
    old_package: Path | None = typer.Option(None, "--old-package", exists=True, file_okay=False, dir_okay=True),
) -> None:
    """Generate knowledge governance reports for an existing package."""
    report = run_governance(package, output, old_package)
    typer.echo(f"Built governance reports at {output}")
    typer.echo(f"Status: {report['status']} | Warnings: {len(report['warnings'])}")


@app.command("build-retrieval-index")
def build_retrieval_index_command(
    package: Path = typer.Option(..., "--package", exists=True, file_okay=False, dir_okay=True, readable=True),
    output: Path = typer.Option(..., "--output", "-o"),
    query: str = typer.Option("Summarize this knowledge package.", "--query"),
) -> None:
    """Build a local high-precision retrieval index for an existing package."""
    manifest = build_retrieval_outputs(package, output, query)
    typer.echo(f"Built retrieval index at {output}")
    typer.echo(f"Records: {manifest['total_records']}")


@app.command("evidence-gate")
def evidence_gate_command(
    package: Path = typer.Option(..., "--package", exists=True, file_okay=False, dir_okay=True, readable=True),
    query: str = typer.Option(..., "--query"),
    output: Path = typer.Option(..., "--output", "-o"),
    llm: bool = typer.Option(False, "--llm"),
    llm_provider: str = typer.Option("mock", "--llm-provider"),
    llm_model: str = typer.Option("mock-model", "--llm-model"),
    llm_base_url: str | None = typer.Option(None, "--llm-base-url"),
    llm_api_key_env: str | None = typer.Option(None, "--llm-api-key-env"),
    llm_evidence_validation: bool = typer.Option(False, "--llm-evidence-validation"),
    llm_boundary_check: bool = typer.Option(False, "--llm-boundary-check"),
    llm_hallucination_check: bool = typer.Option(False, "--llm-hallucination-check"),
    llm_call_log: bool = typer.Option(True, "--llm-call-log/--no-llm-call-log"),
) -> None:
    """Run the local evidence gate against an existing package."""
    result = run_evidence_gate(package, output, query)
    if llm:
        _write_llm_evidence_outputs(
            package,
            output,
            query,
            llm_provider,
            llm_model,
            llm_base_url,
            llm_api_key_env,
            llm_evidence_validation,
            llm_boundary_check,
            llm_hallucination_check,
            llm_call_log,
        )
    typer.echo(f"Built evidence gate report at {output}")
    typer.echo(f"Decision: {result.decision}")


@app.command("generate-skill")
def generate_skill_command(
    package: Path = typer.Option(..., "--package", exists=True, file_okay=False, dir_okay=True, readable=True),
    output: Path = typer.Option(..., "--output", "-o"),
    skill_name: str = typer.Option("Demo Knowledge Skill", "--skill-name"),
    skill_type: str = typer.Option("generic", "--skill-type"),
    skill_template: str = typer.Option("default", "--skill-template"),
    enhanced_skill_template: bool = typer.Option(False, "--enhanced-skill-template"),
    llm: bool = typer.Option(False, "--llm"),
    llm_provider: str = typer.Option("mock", "--llm-provider"),
    llm_model: str = typer.Option("mock-model", "--llm-model"),
    llm_base_url: str | None = typer.Option(None, "--llm-base-url"),
    llm_api_key_env: str | None = typer.Option(None, "--llm-api-key-env"),
    llm_skill_generation: bool = typer.Option(False, "--llm-skill-generation"),
) -> None:
    """Generate a Skill Package from a knowledge package."""
    _ = skill_template
    settings = _provider_settings(llm_provider, llm_model, llm_base_url, llm_api_key_env)
    if llm and llm_skill_generation:
        _, report = generate_llm_skill_package(package, output, skill_name, skill_type, settings, True)
        typer.echo(f"Built Skill Package at {output}")
        typer.echo(f"Generated by: {report.generated_by}")
        return
    result = generate_skill_package(package, output, skill_name, skill_type)
    if enhanced_skill_template:
        render_enhanced_skill_template(output, skill_type)
    typer.echo(f"Built Skill Package at {output}")
    typer.echo(f"Skill: {result.skill_name}")


@app.command("validate-skill")
def validate_skill_command(
    skill: Path = typer.Option(..., "--skill", exists=True, file_okay=False, dir_okay=True, readable=True),
    package: Path = typer.Option(..., "--package", exists=True, file_okay=False, dir_okay=True, readable=True),
    output: Path = typer.Option(..., "--output", "-o"),
) -> None:
    """Validate a generated Skill Package."""
    result = validate_skill_package(skill, package, output)
    typer.echo(f"Built Skill Validation at {output}")
    typer.echo(f"Status: {result.status} | Release ready: {result.release_ready}")


@app.command("generate-agent")
def generate_agent_command(
    package: Path = typer.Option(..., "--package", exists=True, file_okay=False, dir_okay=True, readable=True),
    skill: Path = typer.Option(..., "--skill", exists=True, file_okay=False, dir_okay=True, readable=True),
    output: Path = typer.Option(..., "--output", "-o"),
    agent_name: str = typer.Option("Demo Knowledge Agent", "--agent-name"),
    agent_type: str = typer.Option("generic", "--agent-type"),
    llm: bool = typer.Option(False, "--llm"),
    llm_provider: str = typer.Option("mock", "--llm-provider"),
    llm_model: str = typer.Option("mock-model", "--llm-model"),
    llm_base_url: str | None = typer.Option(None, "--llm-base-url"),
    llm_api_key_env: str | None = typer.Option(None, "--llm-api-key-env"),
    llm_agent_generation: bool = typer.Option(False, "--llm-agent-generation"),
    agent_compat: bool = typer.Option(False, "--agent-compat"),
) -> None:
    """Generate an Agent Package from a knowledge package and Skill Package."""
    settings = _provider_settings(llm_provider, llm_model, llm_base_url, llm_api_key_env)
    if llm and llm_agent_generation:
        _, report = generate_llm_agent_package(package, skill, output, agent_name, agent_type, settings, True)
        typer.echo(f"Built Agent Package at {output}")
        typer.echo(f"Generated by: {report.generated_by}")
        return
    result = generate_agent_package(package, skill, output, agent_name, agent_type)
    if agent_compat:
        export_agent_compat(output, agent_name)
    typer.echo(f"Built Agent Package at {output}")
    typer.echo(f"Agent: {result['agent_name']}")


@app.command("workspace-init")
def workspace_init_command(workspace: Path = typer.Option(..., "--workspace")) -> None:
    manifest = init_portable_workspace(workspace)
    typer.echo(f"Initialized workspace at {workspace}")
    typer.echo(f"Workspace ID: {manifest.workspace_id}")


@app.command("workspace-register")
def workspace_register_command(
    workspace: Path = typer.Option(..., "--workspace"),
    path: Path = typer.Option(..., "--path", exists=True, readable=True),
    type: str = typer.Option(..., "--type"),
    copy: bool = typer.Option(False, "--copy"),
    tags: str = typer.Option("", "--tags"),
) -> None:
    record = import_workspace_asset(workspace, path, type, copy, _split_tags(tags))
    typer.echo(f"Registered {type} asset in {workspace}")
    typer.echo(str(record.get("package_id") or record.get("skill_id") or record.get("agent_id")))


@app.command("workspace-list")
def workspace_list_command(workspace: Path = typer.Option(..., "--workspace", exists=True, file_okay=False, dir_okay=True)) -> None:
    typer.echo(list_workspace_assets(workspace))


@app.command("workspace-search")
def workspace_search_command(
    workspace: Path = typer.Option(..., "--workspace", exists=True, file_okay=False, dir_okay=True),
    query: str = typer.Option(..., "--query"),
) -> None:
    typer.echo(search_workspace(workspace, query))


@app.command("workspace-health")
def workspace_health_command(workspace: Path = typer.Option(..., "--workspace", exists=True, file_okay=False, dir_okay=True)) -> None:
    result, _ = check_workspace_health(workspace)
    typer.echo(f"Workspace health: {result['status']}")


@app.command("workspace-export")
def workspace_export_command(
    workspace: Path = typer.Option(..., "--workspace", exists=True, file_okay=False, dir_okay=True),
    output: Path = typer.Option(..., "--output", "-o"),
) -> None:
    manifest = export_workspace(workspace, output)
    typer.echo(f"Exported workspace to {output}")
    typer.echo(f"Files: {len(manifest['exported_files'])}")


@app.command("workspace-import")
def workspace_import_command(
    workspace: Path = typer.Option(..., "--workspace"),
    package: Path = typer.Option(..., "--package", exists=True, readable=True),
    type: str = typer.Option("knowledge", "--type"),
    copy: bool = typer.Option(False, "--copy"),
    tags: str = typer.Option("", "--tags"),
) -> None:
    record = import_workspace_asset(workspace, package, type, copy, _split_tags(tags))
    typer.echo(f"Imported {type} asset")
    typer.echo(str(record.get("package_id") or record.get("skill_id") or record.get("agent_id")))


@app.command("workspace-refresh")
def workspace_refresh_command(
    workspace: Path = typer.Option(..., "--workspace"),
    output: Path = typer.Option(..., "--output"),
) -> None:
    """Build a static workspace refresh plan and impact report."""
    make_workspace_refresh(workspace, output)
    typer.echo(f"Wrote workspace refresh outputs to {output}")


provider_app = typer.Typer(help="Manage workspace provider registry.")
prompt_profile_app = typer.Typer(help="Manage workspace prompt profile registry.")
app.add_typer(provider_app, name="workspace-provider")
app.add_typer(prompt_profile_app, name="prompt-profile")


@provider_app.command("add")
def workspace_provider_add(
    workspace: Path = typer.Option(..., "--workspace"),
    provider_id: str = typer.Option(..., "--provider-id"),
    provider_type: str = typer.Option("mock", "--provider-type"),
    model: str = typer.Option("mock-model", "--model"),
    api_key_env: str | None = typer.Option(None, "--api-key-env"),
) -> None:
    record = add_provider(workspace, provider_id, provider_type, model, api_key_env)
    typer.echo(f"Added provider: {record['provider_id']}")


@provider_app.command("list")
def workspace_provider_list(workspace: Path = typer.Option(..., "--workspace", exists=True, file_okay=False, dir_okay=True)) -> None:
    typer.echo(list_providers(workspace))


@provider_app.command("check")
def workspace_provider_check(
    workspace: Path = typer.Option(..., "--workspace", exists=True, file_okay=False, dir_okay=True),
    provider_id: str = typer.Option(..., "--provider-id"),
) -> None:
    registry = list_providers(workspace)
    record = next((item for item in registry.get("providers", []) if item.get("provider_id") == provider_id), None)
    typer.echo(record or {"error": "provider_not_found"})


@app.command("provider-readiness")
def provider_readiness_command(
    workspace: Path = typer.Option(..., "--workspace"),
    output: Path = typer.Option(..., "--output"),
) -> None:
    """Write offline provider readiness results without network calls."""
    make_provider_readiness(workspace, output)
    typer.echo(f"Wrote provider readiness outputs to {output}")


@prompt_profile_app.command("add")
def prompt_profile_add(
    workspace: Path = typer.Option(..., "--workspace"),
    profile_id: str = typer.Option(..., "--profile-id"),
    profile_type: str = typer.Option(..., "--profile-type"),
    rules: Path = typer.Option(..., "--rules"),
) -> None:
    record = add_prompt_profile(workspace, profile_id, profile_type, rules)
    typer.echo(f"Added prompt profile: {record['profile_id']}")


@prompt_profile_app.command("list")
def prompt_profile_list(workspace: Path = typer.Option(..., "--workspace", exists=True, file_okay=False, dir_okay=True)) -> None:
    typer.echo(list_prompt_profiles(workspace))


@app.command("prompt-profile-versioning")
def prompt_profile_versioning_command(
    workspace: Path = typer.Option(..., "--workspace"),
    output: Path = typer.Option(..., "--output"),
) -> None:
    """Write local prompt profile version and hash reports."""
    make_prompt_profile_versions(workspace, output)
    typer.echo(f"Wrote prompt profile versioning outputs to {output}")


@app.command()
def batch(
    input: Path = typer.Option(..., "--input", "-i", exists=True, file_okay=False, dir_okay=True, readable=True),
    output: Path = typer.Option(..., "--output", "-o"),
    domain: str = typer.Option("general", "--domain"),
    mode: str = typer.Option("reference", "--mode"),
    max_chars: int = typer.Option(1200, "--max-chars"),
    overlap_chars: int = typer.Option(120, "--overlap-chars"),
    merge_same_sequence: bool = typer.Option(False, "--merge-same-sequence"),
    llm: bool = typer.Option(False, "--llm"),
    llm_provider: str = typer.Option("fake", "--llm-provider"),
    llm_model: str = typer.Option("fake-model", "--llm-model"),
    llm_cache: bool = typer.Option(True, "--llm-cache/--no-llm-cache"),
    llm_strict: bool = typer.Option(False, "--llm-strict"),
    prompt_profile: Path | None = typer.Option(None, "--prompt-profile"),
    llm_quality_report: bool = typer.Option(False, "--llm-quality-report"),
    rag_export: bool = typer.Option(False, "--rag-export"),
    rag_profile: str = typer.Option("basic", "--rag-profile"),
    rag_include_llm: bool = typer.Option(False, "--rag-include-llm"),
    embedding: bool = typer.Option(False, "--embedding"),
    embedding_provider: str = typer.Option("fake", "--embedding-provider"),
    embedding_model: str = typer.Option("fake-embedding-model", "--embedding-model"),
    vector_export: bool = typer.Option(False, "--vector-export"),
    vector_store: str = typer.Option("local_json", "--vector-store"),
    validate_package: bool = typer.Option(False, "--validate-package"),
    downstream_export: bool = typer.Option(False, "--downstream-export"),
    incremental: bool = typer.Option(False, "--incremental"),
    previous_package: Path | None = typer.Option(None, "--previous-package", exists=True, file_okay=False, dir_okay=True),
    lifecycle: bool = typer.Option(False, "--lifecycle"),
    update_mode: str = typer.Option("full", "--update-mode"),
    missing_source_policy: str = typer.Option("mark_stale", "--missing-source-policy"),
    retry_manifest: Path | None = typer.Option(None, "--retry-manifest", exists=True, file_okay=True, dir_okay=False),
    chunk_profile: str = typer.Option("default", "--chunk-profile"),
    knowledge_graph_export: bool = typer.Option(False, "--knowledge-graph-export"),
    retrieval_eval_export: bool = typer.Option(False, "--retrieval-eval-export"),
    risk_labels: bool = typer.Option(False, "--risk-labels"),
    quality_gate: bool = typer.Option(False, "--quality-gate"),
    quality_gate_strict: bool = typer.Option(False, "--quality-gate-strict"),
    run_manifest: bool = typer.Option(False, "--run-manifest"),
    input_coverage_report: bool = typer.Option(False, "--input-coverage-report"),
    parser_hardening_report: bool = typer.Option(False, "--parser-hardening-report"),
    quality_score: bool = typer.Option(False, "--quality-score"),
    review_workflow: bool = typer.Option(False, "--review-workflow"),
    retrieval_eval: bool = typer.Option(False, "--retrieval-eval"),
    evidence_benchmark: bool = typer.Option(False, "--evidence-benchmark"),
    llm_quality_assist: bool = typer.Option(False, "--llm-quality-assist"),
    continue_on_error: bool = typer.Option(True, "--continue-on-error/--no-continue-on-error"),
    fail_fast: bool = typer.Option(False, "--fail-fast"),
    max_files: int | None = typer.Option(None, "--max-files"),
    max_chunks: int | None = typer.Option(None, "--max-chunks"),
    agent_template: bool = typer.Option(False, "--agent-template"),
    agent_type: str = typer.Option("generic_agent", "--agent-type"),
    agent_name: str | None = typer.Option(None, "--agent-name"),
    agent_language: str = typer.Option("zh-CN", "--agent-language"),
    demo_report: bool = typer.Option(False, "--demo-report"),
    progress: bool = typer.Option(False, "--progress"),
    progress_jsonl: bool = typer.Option(False, "--progress-jsonl"),
    progress_log: Path | None = typer.Option(None, "--progress-log"),
    verbose: bool = typer.Option(False, "--verbose"),
    profile: str = typer.Option("production", "--profile"),
    ocr_mode: str = typer.Option("auto", "--ocr-mode"),
    max_ocr_pages: int | None = typer.Option(None, "--max-ocr-pages"),
    ocr_workers: int = typer.Option(1, "--ocr-workers"),
    ocr_cache: bool = typer.Option(False, "--ocr-cache"),
    resume: bool = typer.Option(False, "--resume"),
    multimodal: bool = typer.Option(False, "--multimodal"),
    multimodal_images: bool = typer.Option(True, "--multimodal-images/--no-multimodal-images"),
    multimodal_charts: bool = typer.Option(True, "--multimodal-charts/--no-multimodal-charts"),
    multimodal_slides: bool = typer.Option(True, "--multimodal-slides/--no-multimodal-slides"),
    multimodal_formulas: bool = typer.Option(True, "--multimodal-formulas/--no-multimodal-formulas"),
    multimodal_mindmaps: bool = typer.Option(True, "--multimodal-mindmaps/--no-multimodal-mindmaps"),
    multimodal_report: bool = typer.Option(True, "--multimodal-report/--no-multimodal-report"),
    contract_version: str | None = typer.Option(None, "--contract-version"),
    check_contract: bool = typer.Option(False, "--check-contract"),
) -> None:
    """Build one knowledge package per numbered source file."""
    output.mkdir(parents=True, exist_ok=True)
    numbered_sources = [path for path in sorted(input.iterdir()) if path.is_file() and _parse_numbered_stem(path)]
    if max_files is not None:
        numbered_sources = numbered_sources[:max_files]
    llm_options = _make_llm_options(
        llm,
        llm_provider,
        llm_model,
        llm_cache,
        llm_strict,
        prompt_profile,
        llm_quality_report,
    )
    rag_options = RAGOptions(rag_export, rag_profile, rag_include_llm)
    agent_options = AgentOptions(
        enabled=agent_template,
        agent_type=agent_type,
        agent_name=agent_name,
        language=agent_language,
    )
    embedding_options = _make_embedding_options(embedding, embedding_provider, embedding_model, rag_export)
    vector_options = _make_vector_options(vector_export, vector_store, embedding)
    validation_options = ValidationOptions(validate_package)
    downstream_options = DownstreamOptions(downstream_export)
    v11_options = V11Options(
        versioning=incremental,
        incremental=incremental,
        previous_package=previous_package,
        chunk_profile=chunk_profile,
        knowledge_graph=knowledge_graph_export,
        retrieval_eval=retrieval_eval_export,
        risk_labels=risk_labels,
    )
    hardening_options = HardeningOptions(quality_gate or quality_gate_strict, quality_gate_strict, run_manifest)
    v21_options = V21Options(
        input_coverage_report,
        parser_hardening_report,
        quality_score,
        review_workflow,
        retrieval_eval,
        evidence_benchmark,
        llm_quality_assist,
    )
    lifecycle_options = LifecycleOptions(
        enabled=lifecycle or update_mode != "full" or retry_manifest is not None,
        update_mode=update_mode,
        previous_package=previous_package,
        missing_source_policy=missing_source_policy,
        quality_gate=quality_gate or quality_gate_strict,
        retry_manifest=retry_manifest,
    )
    performance_options = _make_performance_options(
        progress,
        progress_jsonl,
        progress_log,
        verbose,
        profile,
        ocr_mode,
        "chi_sim+eng",
        120,
        max_ocr_pages,
        None,
        ocr_workers,
        1.5,
        ocr_cache,
        None,
        resume,
        True,
        False,
    )
    multimodal_options = MultimodalOptions(
        enabled=multimodal,
        images=multimodal_images,
        charts=multimodal_charts,
        slides=multimodal_slides,
        formulas=multimodal_formulas,
        mindmaps=multimodal_mindmaps,
        report=multimodal_report,
    )
    contract_options = ContractOptions(contract_version, check_contract, False)
    batch_reporter = make_progress_reporter(
        progress=performance_options.progress,
        progress_jsonl=performance_options.progress_jsonl,
        progress_log=performance_options.progress_log,
        verbose=performance_options.verbose,
    )
    if batch_reporter:
        batch_reporter.configure_default_log(output)
        batch_reporter.emit("batch_started", "started", f"Batch started with {len(numbered_sources)} items", total_files=len(numbered_sources), output_path=str(output))
    items = (
        _build_batch_groups(
            numbered_sources,
            output,
            domain,
            mode,
            max_chars,
            overlap_chars,
            llm_options,
            rag_options,
            embedding_options,
            vector_options,
            validation_options,
            downstream_options,
            v11_options,
            lifecycle_options,
            hardening_options,
            v21_options,
            performance_options,
            batch_reporter,
            multimodal_options,
            contract_options,
            max_chunks,
            continue_on_error,
            fail_fast,
            agent_options,
            demo_report,
        )
        if merge_same_sequence
        else _build_batch_items(
            numbered_sources,
            output,
            domain,
            mode,
            max_chars,
            overlap_chars,
            llm_options,
            rag_options,
            embedding_options,
            vector_options,
            validation_options,
            downstream_options,
            v11_options,
            lifecycle_options,
            hardening_options,
            v21_options,
            performance_options,
            batch_reporter,
            multimodal_options,
            contract_options,
            max_chunks,
            continue_on_error,
            fail_fast,
            agent_options,
            demo_report,
        )
    )
    succeeded = sum(1 for item in items if item["status"] == "success")
    failed = sum(1 for item in items if item["status"] == "failed")
    batch_manifest = {
        "batch_version": "0.2.1",
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "input_dir": str(input).replace("\\", "/"),
        "output_dir": str(output).replace("\\", "/"),
        "merge_same_sequence": merge_same_sequence,
        "total_files": len(numbered_sources),
        "succeeded": succeeded,
        "failed": failed,
        "items": items,
        "continue_on_error": continue_on_error,
        "fail_fast": fail_fast,
    }
    if merge_same_sequence:
        batch_manifest["total_groups"] = len(items)
    if batch_reporter:
        batch_reporter.emit("batch_done", "success", f"Batch done: {succeeded} succeeded, {failed} failed", total_files=len(numbered_sources), output_path=str(output))

    write_json(output / "batch_manifest.json", batch_manifest)
    _write_batch_report(output / "batch_report.md", batch_manifest)
    _write_v23_batch_outputs(
        items=items,
        input_root=input,
        output_root=output,
        profile="production",
        retry_enabled=True,
        resume_enabled=False,
    )
    batch_summary, batch_run_report, failed_items, retry_manifest = make_batch_hardening_outputs(batch_manifest)
    write_json(output / "batch_run_summary.json", batch_summary)
    (output / "batch_run_report.md").write_text(batch_run_report, encoding="utf-8")
    write_jsonl(output / "failed_items.jsonl", failed_items)
    write_json(output / "retry_manifest.json", retry_manifest)

    typer.echo(f"Built batch knowledge packages at {output}")
    typer.echo(f"Total: {len(items)} | Succeeded: {succeeded} | Failed: {failed}")


@app.command("batch-run")
def batch_run(
    input: Path = typer.Option(..., "--input", "-i", exists=True, file_okay=False, dir_okay=True, readable=True),
    output: Path = typer.Option(..., "--output", "-o"),
    domain: str = typer.Option("general", "--domain"),
    mode: str = typer.Option("reference", "--mode"),
    profile: str = typer.Option("production", "--profile"),
    worker_pool: bool = typer.Option(False, "--worker-pool"),
    max_workers: int = typer.Option(4, "--max-workers"),
    memory_guard: bool = typer.Option(False, "--memory-guard"),
    max_file_size_mb: int = typer.Option(500, "--max-file-size-mb"),
    timeout_seconds: int = typer.Option(600, "--timeout-seconds"),
    retry_failed: bool = typer.Option(False, "--retry-failed"),
    resume_batch: bool = typer.Option(False, "--resume-batch"),
    merge_same_sequence: bool = typer.Option(False, "--merge-same-sequence"),
) -> None:
    """Run an industrial batch job with v2.3 job manifests and governance summaries."""
    output.mkdir(parents=True, exist_ok=True)
    numbered_sources = [
        path
        for path in sorted(input.iterdir())
        if path.is_file() and _parse_numbered_stem(path) and _within_file_size_guard(path, memory_guard, max_file_size_mb)
    ]
    items = (
        _build_batch_groups(numbered_sources, output, domain, mode, 1200, 120)
        if merge_same_sequence
        else _build_batch_items(numbered_sources, output, domain, mode, 1200, 120)
    )
    batch_manifest = {
        "batch_version": "2.3",
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "input_dir": str(input).replace("\\", "/"),
        "output_dir": str(output).replace("\\", "/"),
        "merge_same_sequence": merge_same_sequence,
        "worker_pool": worker_pool,
        "max_workers": max_workers,
        "memory_guard": memory_guard,
        "timeout_seconds": timeout_seconds,
        "total_files": len(numbered_sources),
        "succeeded": sum(1 for item in items if item["status"] == "success"),
        "failed": sum(1 for item in items if item["status"] == "failed"),
        "items": items,
    }
    if merge_same_sequence:
        batch_manifest["total_groups"] = len(items)
    write_json(output / "batch_manifest.json", batch_manifest)
    _write_batch_report(output / "batch_report.md", batch_manifest)
    _write_v23_batch_outputs(
        items=items,
        input_root=input,
        output_root=output,
        profile=profile,
        retry_enabled=retry_failed,
        resume_enabled=resume_batch,
    )
    typer.echo(f"Batch job completed at {output}")


@app.command("batch-retry")
def batch_retry(
    batch_job: Path = typer.Option(..., "--batch-job", exists=True, file_okay=True, dir_okay=False, readable=True),
    retry_only_failed: bool = typer.Option(False, "--retry-only-failed"),
) -> None:
    """Record a retry pass for failed v2.3 batch job items."""
    statuses, _ = retry_failed_items(batch_job, retry_only_failed)
    typer.echo(f"Updated retry status for {len(statuses)} items")


@app.command("package-lineage")
def package_lineage(
    workspace: Path = typer.Option(..., "--workspace"),
    output: Path = typer.Option(..., "--output"),
) -> None:
    """Generate package version graph and lineage reports."""
    make_package_lineage(workspace, output)
    typer.echo(f"Wrote package lineage outputs to {output}")


@app.command("curate-package")
def curate_package(
    package: Path = typer.Option(..., "--package", exists=True, file_okay=False, dir_okay=True, readable=True),
    review_decisions: Path = typer.Option(..., "--review-decisions"),
    output: Path = typer.Option(..., "--output"),
) -> None:
    """Build a curated package from review decisions."""
    build_curated_package(package, review_decisions, output)
    typer.echo(f"Wrote curated package to {output}")


@app.command("update-impact")
def update_impact(
    workspace: Path = typer.Option(..., "--workspace"),
    package: Path = typer.Option(..., "--package", exists=True, file_okay=False, dir_okay=True, readable=True),
    output: Path = typer.Option(..., "--output"),
) -> None:
    """Analyze package update impact across skills and agents."""
    analyze_update_impact(workspace, package, output)
    typer.echo(f"Wrote update impact outputs to {output}")


@app.command("export-platform")
def export_platform(
    skill: Path = typer.Option(..., "--skill", exists=True, file_okay=False, dir_okay=True, readable=True),
    agent: Path | None = typer.Option(None, "--agent", exists=True, file_okay=False, dir_okay=True, readable=True),
    output: Path = typer.Option(..., "--output"),
    platform: str = typer.Option("generic", "--platform"),
) -> None:
    """Export local platform distribution files without uploading or running platforms."""
    manifests = export_platform_package(skill, agent, output, platform)
    typer.echo(f"Wrote platform distribution for {len(manifests)} platform(s) to {output}")


@app.command("platform-upload-check")
def platform_upload_check(
    export: Path = typer.Option(..., "--export", exists=True, file_okay=False, dir_okay=True, readable=True),
    output: Path = typer.Option(..., "--output"),
    platform: str | None = typer.Option(None, "--platform"),
) -> None:
    """Check local platform export files without uploading."""
    result = check_platform_upload(export, output, platform)
    typer.echo(f"Platform upload check: {result.status}")


@app.command("mock-publish")
def mock_publish(
    export: Path = typer.Option(..., "--export", exists=True, file_okay=False, dir_okay=True, readable=True),
    platform: str = typer.Option(..., "--platform"),
    output: Path = typer.Option(..., "--output"),
) -> None:
    """Write a mock publish result without calling external platform APIs."""
    result = mock_publish_package(export, platform, output)
    typer.echo(f"Mock publish: {result.status}")


@app.command("quality-gate")
def quality_gate_command(
    workspace: Path = typer.Option(..., "--workspace", exists=True, file_okay=False, dir_okay=True, readable=True),
    output: Path = typer.Option(..., "--output"),
    release_threshold: int = typer.Option(80, "--release-threshold"),
) -> None:
    """Run v2.5 release quality gate checks without external calls."""
    result = run_quality_gate(workspace, output, release_threshold)
    typer.echo(f"Quality gate: {result.status} | Release ready: {result.release_ready}")


@app.command("release-blockers")
def release_blockers_command(
    workspace: Path = typer.Option(..., "--workspace", exists=True, file_okay=False, dir_okay=True, readable=True),
    output: Path = typer.Option(..., "--output"),
) -> None:
    """Detect v2.5 release blockers from local files and boundary claims."""
    result = detect_release_blockers(workspace, output)
    typer.echo(f"Release blockers: {result.status} | Critical: {result.critical_count}")


@app.command("regression-check")
def regression_check_command(
    workspace: Path = typer.Option(..., "--workspace", exists=True, file_okay=False, dir_okay=True, readable=True),
    output: Path = typer.Option(..., "--output"),
) -> None:
    """Check v1.6-v2.4 regression coverage using local modules, schemas, commands, and tests."""
    result = run_regression_check(workspace, output)
    typer.echo(f"Regression check: {result.status} | Cases: {result.case_count}")


@app.command("validate-golden-samples")
def validate_golden_samples_command(
    workspace: Path = typer.Option(Path("examples/golden_samples"), "--workspace", file_okay=False, dir_okay=True, readable=True),
    output: Path = typer.Option(..., "--output"),
) -> None:
    """Validate local v2.5 golden sample placeholders."""
    result = validate_golden_samples(workspace, output)
    typer.echo(f"Golden samples: {result.status} | Samples: {result.sample_count}")


@app.command("certify-export")
def certify_export_command(
    export: Path = typer.Option(..., "--export", exists=True, file_okay=False, dir_okay=True, readable=True),
    output: Path = typer.Option(..., "--output"),
    platform: str = typer.Option("all", "--platform"),
) -> None:
    """Certify local platform export packages without uploading or running platforms."""
    result = certify_platform_export(export, output, platform)
    typer.echo(f"Export certification: {result.status} | Certified: {result.certified}")


@app.command("compatibility-matrix")
def compatibility_matrix_command(
    workspace: Path = typer.Option(..., "--workspace", exists=True, file_okay=False, dir_okay=True, readable=True),
    output: Path = typer.Option(..., "--output"),
) -> None:
    """Write a v2.5 compatibility matrix for local packages and platform exports."""
    result = make_compatibility_matrix(workspace, output)
    typer.echo(f"Compatibility matrix: {result['status']}")


@app.command("llm-quality-gate-assist")
def llm_quality_gate_assist_command(
    workspace: Path = typer.Option(..., "--workspace", exists=True, file_okay=False, dir_okay=True, readable=True),
    output: Path = typer.Option(..., "--output"),
    provider: str = typer.Option("mock", "--provider"),
) -> None:
    """Write mock-first LLM release gate suggestions without network calls."""
    result = run_llm_quality_gate_assist(workspace, output, provider)
    typer.echo(f"LLM quality gate assist: {result['status']} | Provider: {provider}")


@app.command("release-readiness")
def release_readiness_command(
    workspace: Path = typer.Option(..., "--workspace", exists=True, file_okay=False, dir_okay=True, readable=True),
    output: Path = typer.Option(..., "--output"),
) -> None:
    """Summarize v2.5 quality gate, blockers, regression, certification, and matrix results."""
    result = evaluate_release_readiness(workspace, output)
    typer.echo(f"Release readiness: {result.status} | Release ready: {result.release_ready}")


@app.command()
def run(
    config: Path = typer.Option(..., "--config", "-c", exists=True, file_okay=True, dir_okay=False, readable=True),
) -> None:
    """Run build or batch from a YAML config file."""
    config_data = load_config(config)
    result = _run_config(config_data)
    typer.echo(result.message)


@app.command()
def pipeline(
    config: Path = typer.Option(..., "--config", "-c", exists=True, file_okay=True, dir_okay=False, readable=True),
    progress: bool = typer.Option(False, "--progress"),
    progress_jsonl: bool = typer.Option(False, "--progress-jsonl"),
    progress_log: Path | None = typer.Option(None, "--progress-log"),
    profile: str = typer.Option("production", "--profile"),
    ocr_mode: str = typer.Option("auto", "--ocr-mode"),
    max_ocr_pages: int | None = typer.Option(None, "--max-ocr-pages"),
    ocr_workers: int = typer.Option(1, "--ocr-workers"),
    ocr_cache: bool = typer.Option(False, "--ocr-cache"),
    resume: bool = typer.Option(False, "--resume"),
    multimodal: bool = typer.Option(False, "--multimodal"),
    contract_version: str | None = typer.Option(None, "--contract-version"),
    check_contract: bool = typer.Option(False, "--check-contract"),
) -> None:
    """Run a config-driven pipeline and write pipeline reports."""
    config_data = load_config(config)
    _apply_performance_overrides(
        config_data,
        progress=progress,
        progress_jsonl=progress_jsonl,
        progress_log=progress_log,
        profile=profile,
        ocr_mode=ocr_mode,
        max_ocr_pages=max_ocr_pages,
        ocr_workers=ocr_workers,
        ocr_cache=ocr_cache,
        resume=resume,
    )
    if multimodal:
        config_data.multimodal.enabled = True
    if contract_version is not None:
        config_data.contract.version = contract_version
    if check_contract:
        config_data.contract.check = True
    result = _run_config(config_data)
    pipeline_manifest, pipeline_report = make_pipeline_report(config_file=config, config=result.config, output=result.output)
    write_json(result.output / "pipeline_manifest.json", pipeline_manifest.model_dump(mode="json"))
    (result.output / "pipeline_report.md").write_text(pipeline_report, encoding="utf-8")
    typer.echo(result.message)
    typer.echo(f"Built pipeline report at {result.output}")


@app.command("doctor")
def doctor(output: Path = typer.Option(..., "--output", "-o")) -> None:
    """Check local installability and optional environment readiness."""
    report, markdown = run_doctor(output)
    write_json(output / "doctor_result.json", report)
    write_json(output / "doctor_report.json", report)
    (output / "doctor_report.md").write_text(markdown, encoding="utf-8")
    typer.echo(f"Doctor status: {report['status']}")


@app.command("check-contract")
def check_contract(
    package: Path = typer.Option(..., "--package", exists=True, file_okay=False, dir_okay=True, readable=True),
    contract_version: str = typer.Option("v2", "--contract-version"),
    strict: bool = typer.Option(False, "--strict"),
    output: Path | None = typer.Option(None, "--output", "-o"),
) -> None:
    """Check a local knowledge package against the package contract."""
    if contract_version != "v2":
        raise ValueError(f"Unsupported contract version: {contract_version}")
    target = output or package
    target.mkdir(parents=True, exist_ok=True)
    result = check_package_contract(package, strict=strict)
    write_json(target / "contract_check_result.json", result.model_dump(mode="json"))
    (target / "contract_check_report.md").write_text(make_contract_report(result), encoding="utf-8")
    typer.echo(f"Contract check status: {result.status}")


@app.command("lifecycle-check")
def lifecycle_check(
    input: Path = typer.Option(..., "--input", "-i", exists=True, file_okay=True, dir_okay=True, readable=True),
    package: Path = typer.Option(..., "--package", exists=True, file_okay=False, dir_okay=True, readable=True),
    output: Path = typer.Option(..., "--output", "-o"),
) -> None:
    """Compare current sources with a package source registry."""
    output.mkdir(parents=True, exist_ok=True)
    source_files = _collect_sources(input)
    current_registry = make_source_registry(input, source_files)
    previous_registry = load_source_registry(package)
    report, changed, missing, new, _unchanged = detect_source_changes(previous_registry, current_registry)
    write_json(output / "source_registry.json", current_registry.model_dump(mode="json"))
    (output / "source_change_report.md").write_text(render_source_change_report(report), encoding="utf-8")
    write_jsonl(output / "changed_sources.jsonl", changed)
    write_jsonl(output / "missing_sources.jsonl", missing)
    write_jsonl(output / "new_sources.jsonl", new)
    typer.echo(f"Built lifecycle check at {output}")


@app.command()
def diff(
    old: Path = typer.Option(..., "--old", exists=True, file_okay=False, dir_okay=True, readable=True),
    new: Path = typer.Option(..., "--new", exists=True, file_okay=False, dir_okay=True, readable=True),
    output: Path = typer.Option(..., "--output", "-o"),
) -> None:
    """Compare two local knowledge packages."""
    output.mkdir(parents=True, exist_ok=True)
    version, report, changed, removed, new_chunks = diff_packages(old, new)
    write_json(output / "package_version.json", version)
    (output / "package_diff_report.md").write_text(report, encoding="utf-8")
    write_jsonl(output / "changed_chunks.jsonl", changed)
    write_jsonl(output / "removed_chunks.jsonl", removed)
    write_jsonl(output / "new_chunks.jsonl", new_chunks)
    typer.echo(f"Built package diff at {output}")


@app.command()
def retrieve(
    package: Path | None = typer.Option(None, "--package", exists=True, file_okay=False, dir_okay=True, readable=True),
    store: Path | None = typer.Option(None, "--store", exists=True, file_okay=True, dir_okay=False, readable=True),
    query: str = typer.Option(..., "--query"),
    top_k: int = typer.Option(5, "--top-k"),
    book_id: str | None = typer.Option(None, "--book-id"),
    publisher_id: str | None = typer.Option(None, "--publisher-id"),
    agent_type: str | None = typer.Option(None, "--agent-type"),
    output: Path | None = typer.Option(None, "--output", "-o"),
) -> None:
    """Retrieve local package or store records with citation traces."""
    if not package and not store:
        raise ValueError("--package or --store is required")
    output = output or (package if package else Path("."))
    output.mkdir(parents=True, exist_ok=True)
    scope = parse_scope(book_id=book_id, publisher_id=publisher_id, agent_type=agent_type)
    records, trace, citation_trace = (
        retrieve_from_store(store, query, top_k, scope)
        if store
        else retrieve_from_package(package, query, top_k, scope)
    )
    write_json(output / "retrieval_result.json", {"query": query, "records": [record.model_dump(mode="json") for record in records]})
    write_json(output / "retrieval_trace.json", trace)
    write_json(output / "citation_trace.json", citation_trace)
    typer.echo(f"Built retrieval result at {output}")


@app.command()
def ask(
    package: Path | None = typer.Option(None, "--package", exists=True, file_okay=False, dir_okay=True, readable=True),
    store: Path | None = typer.Option(None, "--store", exists=True, file_okay=True, dir_okay=False, readable=True),
    query: str = typer.Option(..., "--query"),
    top_k: int = typer.Option(5, "--top-k"),
    provider: str = typer.Option("fake", "--provider"),
    model: str = typer.Option("fake-model", "--model"),
    citation_required: bool = typer.Option(False, "--citation-required"),
    scope: str | None = typer.Option(None, "--scope"),
    output: Path | None = typer.Option(None, "--output", "-o"),
) -> None:
    """Ask a local knowledge package or store with a minimal RAG runtime."""
    if not package and not store:
        raise ValueError("--package or --store is required")
    output = output or (package if package else Path("."))
    output.mkdir(parents=True, exist_ok=True)
    if store:
        records, trace, citation_trace = retrieve_from_store(store, query, top_k, parse_scope(scope))
        answer, report = answer_from_records(query, records, top_k, citation_required)
        (output / "answer.md").write_text(answer, encoding="utf-8")
        write_json(output / "answer_report.json", report.model_dump(mode="json"))
        write_json(output / "retrieval_trace.json", trace)
        write_json(output / "citation_trace.json", citation_trace)
        typer.echo(f"Built answer at {output / 'answer.md'}")
        return
    if citation_required:
        records, trace, citation_trace = retrieve_from_package(package, query, top_k, parse_scope(scope))
        answer, report = answer_from_records(query, records, top_k, citation_required)
        (output / "answer.md").write_text(answer, encoding="utf-8")
        write_json(output / "answer_report.json", report.model_dump(mode="json"))
        write_json(output / "retrieval_trace.json", trace)
        write_json(output / "citation_trace.json", citation_trace)
        typer.echo(f"Built answer at {output / 'answer.md'}")
        return
    answer, report, trace = ask_package(package, query, top_k, provider, model)
    (output / "answer.md").write_text(answer, encoding="utf-8")
    write_json(output / "answer_report.json", report.model_dump(mode="json"))
    write_json(output / "retrieval_trace.json", trace)
    typer.echo(f"Built answer at {output / 'answer.md'}")


@app.command()
def web() -> None:
    """Run the optional Streamlit Web UI."""
    from heitang_kb_forge.web.app import render_app

    render_app()


@workspace_app.command("init")
def workspace_init(workspace: Path = typer.Option(..., "--workspace")) -> None:
    index, registry, report = init_workspace(workspace)
    write_json(workspace / "workspace_index.json", index)
    write_json(workspace / "package_registry.json", registry)
    (workspace / "package_status_report.md").write_text(report, encoding="utf-8")
    typer.echo(f"Initialized workspace at {workspace}")


@workspace_app.command("register")
def workspace_register(
    workspace: Path = typer.Option(..., "--workspace"),
    package: Path = typer.Option(..., "--package", exists=True, file_okay=False, dir_okay=True, readable=True),
) -> None:
    registry, report = register_package(workspace, package)
    index = {"workspace_version": "1.2.0", "package_count": len(registry["packages"])}
    write_json(workspace / "workspace_index.json", index)
    write_json(workspace / "package_registry.json", registry)
    (workspace / "package_status_report.md").write_text(report, encoding="utf-8")
    typer.echo(f"Registered package {package}")


@workspace_app.command("status")
def workspace_status_command(workspace: Path = typer.Option(..., "--workspace", exists=True, file_okay=False, dir_okay=True)) -> None:
    registry, report = workspace_status(workspace)
    write_json(workspace / "package_registry.json", registry)
    (workspace / "package_status_report.md").write_text(report, encoding="utf-8")
    typer.echo(f"Workspace packages: {len(registry['packages'])}")


@store_app.command("init")
def store_init(db: Path = typer.Option(Path("kb_forge_workspace.db"), "--db")) -> None:
    manifest = init_store(db)
    typer.echo(f"Initialized store at {manifest['db_path']}")


@store_app.command("import-package")
def store_import_package(
    db: Path = typer.Option(Path("kb_forge_workspace.db"), "--db"),
    package: Path = typer.Option(..., "--package", exists=True, file_okay=False, dir_okay=True),
) -> None:
    result = import_package(db, package)
    typer.echo(f"Imported package {result['package_id']}")


@store_app.command("sync-workspace")
def store_sync_workspace(
    db: Path = typer.Option(Path("kb_forge_workspace.db"), "--db"),
    workspace: Path = typer.Option(..., "--workspace", exists=True, file_okay=False, dir_okay=True),
) -> None:
    imported = sync_workspace(db, workspace)
    typer.echo(f"Imported packages: {len(imported)}")


@store_app.command("list-packages")
def store_list_packages(db: Path = typer.Option(Path("kb_forge_workspace.db"), "--db")) -> None:
    packages = list_packages(db)
    for package in packages:
        typer.echo(f"{package.package_id}\t{package.package_name}\t{package.domain or '-'}\t{package.quality_score}")


@store_app.command("query-packages")
def store_query_packages(
    db: Path = typer.Option(Path("kb_forge_workspace.db"), "--db"),
    domain: str | None = typer.Option(None, "--domain"),
    agent_type: str | None = typer.Option(None, "--agent-type"),
    min_quality_score: int | None = typer.Option(None, "--min-quality-score"),
    output: Path | None = typer.Option(None, "--output", "-o"),
) -> None:
    result = query_packages(db, domain=domain, agent_type=agent_type, min_quality_score=min_quality_score)
    if output:
        write_json(output / "store_query_result.json", result.model_dump(mode="json"))
    typer.echo(f"Matched packages: {result.total}")


@store_app.command("package-status")
def store_package_status(
    db: Path = typer.Option(Path("kb_forge_workspace.db"), "--db"),
    package_id: str = typer.Option(..., "--package-id"),
    output: Path | None = typer.Option(None, "--output", "-o"),
) -> None:
    status = package_status(db, package_id)
    if output:
        write_json(output / "store_query_result.json", status)
    typer.echo(f"Package {package_id}: {status['indexed_chunk_count']} chunks")


@store_app.command("export-index")
def store_export_index(
    db: Path = typer.Option(Path("kb_forge_workspace.db"), "--db"),
    output: Path = typer.Option(..., "--output", "-o"),
) -> None:
    output.mkdir(parents=True, exist_ok=True)
    manifest, packages, sources, chunks, report = export_store_index(db)
    write_json(output / "store_manifest.json", manifest)
    write_jsonl(output / "store_package_index.jsonl", packages)
    write_jsonl(output / "store_source_index.jsonl", sources)
    write_jsonl(output / "store_chunk_index.jsonl", chunks)
    (output / "store_status_report.md").write_text(report, encoding="utf-8")
    typer.echo(f"Exported store index at {output}")


@tools_app.command("export")
def tools_export(output: Path = typer.Option(..., "--output", "-o")) -> None:
    output.mkdir(parents=True, exist_ok=True)
    registry_yaml, manifest, schema, policy = make_tool_exports()
    (output / "tool_registry.yaml").write_text(registry_yaml, encoding="utf-8")
    write_json(output / "tool_manifest.json", manifest)
    write_json(output / "agent_tool_schema.json", schema)
    (output / "tool_safety_policy.md").write_text(policy, encoding="utf-8")
    typer.echo(f"Exported tool registry at {output}")


@tools_app.command("list")
def tools_list() -> None:
    for tool in list_agent_tools():
        typer.echo(tool.name)


@tools_app.command("describe")
def tools_describe(name: str = typer.Option(..., "--name")) -> None:
    tool = get_agent_tool(name)
    typer.echo(tool.model_dump_json(indent=2))


@tools_app.command("invoke")
def tools_invoke(
    name: str = typer.Option(..., "--name"),
    input: Path = typer.Option(..., "--input", exists=True, file_okay=True, dir_okay=False),
    output: Path = typer.Option(..., "--output", "-o"),
) -> None:
    output.mkdir(parents=True, exist_ok=True)
    try:
        result, trace = invoke_tool(name, input)
        write_json(output / "tool_result.json", result)
        write_json(output / "tool_execution_trace.json", trace)
    except Exception as exc:
        error = {"tool": name, "status": "failed", "error": str(exc)}
        write_json(output / "tool_error_report.json", error)
        raise
    typer.echo(f"Invoked tool {name} at {output}")


@mcp_app.command("export-config")
def mcp_export_config(output: Path = typer.Option(..., "--output", "-o")) -> None:
    output.mkdir(parents=True, exist_ok=True)
    config_yaml, tools_manifest = make_mcp_config()
    (output / "mcp_server_config.yaml").write_text(config_yaml, encoding="utf-8")
    write_json(output / "mcp_tools_manifest.json", tools_manifest)
    typer.echo(f"Exported MCP config at {output}")


@app.command("refresh-check")
def refresh_check(
    workspace: Path = typer.Option(..., "--workspace", exists=True, file_okay=False, dir_okay=True),
    output: Path | None = typer.Option(None, "--output", "-o"),
    stale_days: int = typer.Option(30, "--stale-days"),
) -> None:
    output = output or workspace
    output.mkdir(parents=True, exist_ok=True)
    stale, plan, report = make_refresh_plan(workspace, stale_days)
    write_jsonl(output / "stale_sources.jsonl", stale)
    write_json(output / "refresh_plan.json", plan)
    (output / "source_freshness_report.md").write_text(report, encoding="utf-8")
    typer.echo(f"Built refresh plan at {output}")


@app.command("review-create")
def review_create(
    package: Path = typer.Option(..., "--package", exists=True, file_okay=False, dir_okay=True),
    output: Path = typer.Option(..., "--output", "-o"),
) -> None:
    output.mkdir(parents=True, exist_ok=True)
    queue, report = create_review_queue(package)
    write_jsonl(output / "review_queue.jsonl", queue)
    write_jsonl(output / "review_decisions.jsonl", empty_decision_template(queue))
    (output / "curation_report.md").write_text(report, encoding="utf-8")
    typer.echo(f"Built review queue at {output}")


@app.command("review-apply")
def review_apply(
    package: Path = typer.Option(..., "--package", exists=True, file_okay=False, dir_okay=True),
    decisions: Path = typer.Option(..., "--decisions", exists=True, file_okay=True, dir_okay=False),
    output: Path = typer.Option(..., "--output", "-o"),
) -> None:
    output.mkdir(parents=True, exist_ok=True)
    curated, report = apply_review_decisions(package, decisions)
    write_jsonl(output / "curated_chunks.jsonl", curated)
    (output / "curation_report.md").write_text(report, encoding="utf-8")
    typer.echo(f"Applied review decisions at {output}")


@app.command("eval-record")
def eval_record(
    package: Path = typer.Option(..., "--package", exists=True, file_okay=False, dir_okay=True),
    eval_results: Path | None = typer.Option(None, "--eval-results", file_okay=True, dir_okay=False),
    output: Path = typer.Option(..., "--output", "-o"),
) -> None:
    output.mkdir(parents=True, exist_ok=True)
    retrieval_results, answer_results, citation_report, trend_report = make_eval_dashboard(package, eval_results)
    write_json(output / "retrieval_eval_results.json", retrieval_results)
    write_json(output / "answer_eval_results.json", answer_results)
    (output / "citation_hit_report.md").write_text(citation_report, encoding="utf-8")
    (output / "quality_trend_report.md").write_text(trend_report, encoding="utf-8")
    typer.echo(f"Built eval dashboard data at {output}")


@app.command("publish")
def publish(
    package: Path = typer.Option(..., "--package", exists=True, file_okay=False, dir_okay=True),
    profile: str = typer.Option("generic_rag", "--profile"),
    output: Path = typer.Option(..., "--output", "-o"),
) -> None:
    output.mkdir(parents=True, exist_ok=True)
    profile_yaml, manifest = make_publish_package(package, profile, output)
    (output / "export_profile.yaml").write_text(profile_yaml, encoding="utf-8")
    write_json(output / "publish_manifest.json", manifest)
    typer.echo(f"Built publish package at {output}")


@app.command("planning-readiness")
def planning_readiness(
    package: Path = typer.Option(..., "--package", exists=True, file_okay=False, dir_okay=True),
    output: Path = typer.Option(..., "--output", "-o"),
) -> None:
    output.mkdir(parents=True, exist_ok=True)
    blueprint, tool_map, eval_cases, report = make_planning_readiness(package)
    (output / "agent_planning_blueprint.yaml").write_text(blueprint, encoding="utf-8")
    write_json(output / "tool_requirement_map.json", tool_map)
    write_jsonl(output / "planning_eval_cases.jsonl", eval_cases)
    (output / "planning_risk_report.md").write_text(report, encoding="utf-8")
    typer.echo(f"Built planning readiness pack at {output}")


@app.command("studio-run")
def studio_run(
    input: Path = typer.Option(..., "--input", exists=True, file_okay=True, dir_okay=True, readable=True),
    workspace: Path = typer.Option(..., "--workspace"),
    project_name: str = typer.Option("demo_project", "--project-name"),
    profile: str = typer.Option("stable", "--profile"),
) -> None:
    """Run a stable local end-to-end Studio workflow."""
    knowledge_package = workspace / "knowledge_packages" / project_name
    _build_package(input, knowledge_package, "general", profile, 1200, 120)
    finalize_studio_workspace(workspace, project_name, knowledge_package)
    write_studio_v22_outputs(workspace)
    typer.echo(f"Studio run completed at {workspace}")


@app.command("stable-check")
def stable_check(workspace: Path = typer.Option(..., "--workspace", exists=True, file_okay=False, dir_okay=True)) -> None:
    """Check stable workspace contracts."""
    result, _ = run_stable_check(workspace)
    typer.echo(f"Stable check status: {result.status}")


@app.command("provider-health")
def provider_health(
    workspace: Path = typer.Option(..., "--workspace", exists=True, file_okay=False, dir_okay=True),
    allow_network: bool = typer.Option(False, "--allow-network"),
) -> None:
    """Check configured provider registry without network by default."""
    result, _ = check_provider_health(workspace, allow_network)
    typer.echo(f"Provider health status: {result['status']}")


@app.command("reliability-score")
def reliability_score(
    workspace: Path = typer.Option(..., "--workspace", exists=True, file_okay=False, dir_okay=True),
    release_threshold: int = typer.Option(80, "--release-threshold"),
) -> None:
    """Generate a release reliability score for a local workspace."""
    result, _ = make_reliability_score(workspace, release_threshold)
    typer.echo(f"Reliability score: {result.overall_score}")


@app.command("release-package")
def release_package(
    workspace: Path = typer.Option(..., "--workspace", exists=True, file_okay=False, dir_okay=True),
    output: Path = typer.Option(..., "--output", "-o"),
    include_demo_outputs: bool = typer.Option(True, "--include-demo-outputs/--no-include-demo-outputs"),
) -> None:
    """Create a local release package snapshot from a workspace."""
    manifest = make_release_package(workspace, output, include_demo_outputs)
    typer.echo(f"Built release package at {output}")
    typer.echo(f"Files: {len(manifest['files'])}")


@app.command("quality-score")
def quality_score_command(
    package: Path = typer.Option(..., "--package", exists=True, file_okay=False, dir_okay=True),
    output: Path = typer.Option(..., "--output", "-o"),
) -> None:
    """Generate v2.1 knowledge quality score outputs."""
    report = make_v21_quality_outputs(package, output)
    typer.echo(f"Knowledge quality status: {report['status']}")


@app.command("review-workflow")
def review_workflow_command(
    package: Path = typer.Option(..., "--package", exists=True, file_okay=False, dir_okay=True),
    output: Path = typer.Option(..., "--output", "-o"),
) -> None:
    """Generate v2.1 review workflow and curated chunk outputs."""
    make_v21_quality_outputs(package, output)
    typer.echo(f"Built review workflow outputs at {output}")


@app.command("retrieval-eval")
def retrieval_eval_command(
    package: Path = typer.Option(..., "--package", exists=True, file_okay=False, dir_okay=True),
    output: Path = typer.Option(..., "--output", "-o"),
) -> None:
    """Generate v2.1 retrieval evaluation outputs."""
    make_v21_quality_outputs(package, output)
    typer.echo(f"Built retrieval evaluation outputs at {output}")


@app.command("evidence-benchmark")
def evidence_benchmark_command(
    package: Path = typer.Option(..., "--package", exists=True, file_okay=False, dir_okay=True),
    output: Path = typer.Option(..., "--output", "-o"),
) -> None:
    """Generate v2.1 evidence benchmark outputs."""
    make_v21_quality_outputs(package, output)
    typer.echo(f"Built evidence benchmark outputs at {output}")


@app.command("import-skill")
def import_skill_command(
    input: Path = typer.Option(..., "--input", exists=True, readable=True),
    output: Path = typer.Option(..., "--output", "-o"),
) -> None:
    """Import a master Skill package for structural learning."""
    inventory, _ = import_master_skill(input, output)
    typer.echo(f"Imported master Skill: {inventory.skill_name}")


@app.command("analyze-skill")
def analyze_skill_command(
    skill: Path = typer.Option(..., "--skill", exists=True, readable=True),
    output: Path = typer.Option(..., "--output", "-o"),
) -> None:
    """Analyze a master Skill structure, workflow, style, and boundaries."""
    decomposition, _ = analyze_master_skill(skill, output)
    typer.echo(f"Analyzed Skill: {decomposition.skill_name}")


@app.command("generate-derived-skill")
def generate_derived_skill_command(
    master_skill: Path = typer.Option(..., "--master-skill", exists=True, file_okay=False, dir_okay=True),
    knowledge_package: Path = typer.Option(..., "--knowledge-package", exists=True, file_okay=False, dir_okay=True),
    output: Path = typer.Option(..., "--output", "-o"),
    style_profile: Path | None = typer.Option(None, "--style-profile", exists=True, file_okay=True, dir_okay=False),
) -> None:
    """Generate a derived Skill from learned structure and the user's own package."""
    result = generate_derived_skill(master_skill, knowledge_package, output, style_profile)
    typer.echo(f"Generated derived Skill at {result['output']}")


@app.command("skill-safety-check")
def skill_safety_check_command(
    skill: Path = typer.Option(..., "--skill", exists=True, readable=True),
    output: Path = typer.Option(..., "--output", "-o"),
) -> None:
    """Check a Skill package for high-risk local patterns."""
    result, _ = run_skill_safety_check(skill, output)
    typer.echo(f"Skill safety status: {result['status']}")


@app.command("skill-similarity-check")
def skill_similarity_check_command(
    master_skill: Path = typer.Option(..., "--master-skill", exists=True, readable=True),
    derived_skill: Path = typer.Option(..., "--derived-skill", exists=True, readable=True),
    output: Path = typer.Option(..., "--output", "-o"),
) -> None:
    """Check derived Skill similarity against a master Skill analysis/package."""
    result, _ = run_skill_similarity_check(master_skill, derived_skill, output)
    typer.echo(f"Skill similarity status: {result['status']}")


def _run_config(config_data: ForgeConfig) -> ConfigRunResult:
    llm_options = _make_llm_options(
        config_data.llm.enabled,
        config_data.llm.provider,
        config_data.llm.model,
        config_data.llm.cache,
        config_data.llm.strict,
        config_data.llm.prompt_profile,
        config_data.llm.quality_report,
    )
    rag_options = RAGOptions(
        config_data.rag.enabled,
        config_data.rag.profile,
        config_data.rag.include_llm,
    )
    embedding_options = _make_embedding_options(
        config_data.embedding.enabled,
        config_data.embedding.provider,
        config_data.embedding.model,
        config_data.rag.enabled,
    )
    vector_options = _make_vector_options(
        config_data.vector.enabled,
        config_data.vector.store,
        config_data.embedding.enabled,
    )
    validation_options = ValidationOptions(config_data.validation.enabled)
    downstream_options = DownstreamOptions(config_data.downstream.enabled)
    v11_options = V11Options(
        versioning=config_data.versioning.enabled,
        incremental=config_data.incremental.enabled,
        previous_package=config_data.incremental.previous_package,
        chunk_profile=config_data.chunk.profile,
        knowledge_graph=config_data.knowledge_graph.enabled,
        retrieval_eval=config_data.retrieval_eval.enabled,
        risk_labels=config_data.risk_labels.enabled,
        runtime=config_data.runtime.enabled,
        runtime_top_k=config_data.runtime.top_k,
        runtime_provider=config_data.runtime.provider,
        runtime_model=config_data.runtime.model,
    )
    lifecycle_options = LifecycleOptions(
        enabled=config_data.lifecycle.enabled,
        update_mode=config_data.lifecycle.update_mode,
        previous_package=config_data.lifecycle.previous_package or config_data.incremental.previous_package,
        missing_source_policy=config_data.lifecycle.missing_source_policy,
        quality_gate=config_data.lifecycle.quality_gate,
        retry_manifest=config_data.lifecycle.retry_manifest,
    )
    performance_options = _make_performance_options(
        config_data.performance.progress,
        config_data.performance.progress_jsonl,
        config_data.performance.progress_log,
        False,
        config_data.performance.profile,
        config_data.performance.ocr_mode,
        config_data.performance.ocr_lang,
        config_data.performance.ocr_timeout_per_page,
        config_data.performance.max_ocr_pages,
        config_data.performance.ocr_pages,
        config_data.performance.ocr_workers,
        config_data.performance.ocr_scale,
        config_data.performance.ocr_cache,
        config_data.performance.ocr_cache_dir,
        config_data.performance.resume,
        config_data.performance.skip_empty_pages,
        config_data.performance.skip_low_text_pages,
    )
    agent_options = AgentOptions(
        enabled=config_data.agent.enabled,
        agent_type=config_data.agent.type,
        agent_name=config_data.agent.name,
        language=config_data.agent.language,
    )
    multimodal_options = MultimodalOptions(
        enabled=config_data.multimodal.enabled,
        images=config_data.multimodal.images,
        charts=config_data.multimodal.charts,
        slides=config_data.multimodal.slides,
        formulas=config_data.multimodal.formulas,
        mindmaps=config_data.multimodal.mindmaps,
        diagrams=config_data.multimodal.diagrams,
        report=config_data.multimodal.report,
        require_evidence_refs=config_data.multimodal.require_evidence_refs,
        review_low_confidence=config_data.multimodal.review_low_confidence,
    )
    contract_options = ContractOptions(config_data.contract.version, config_data.contract.check, config_data.contract.strict)
    governance_options = GovernanceOptions(config_data.governance.enabled, config_data.governance.previous_package)
    retrieval_index_options = RetrievalIndexOptions(config_data.retrieval.enabled, config_data.retrieval.query)
    evidence_gate_options = EvidenceGateOptions(config_data.evidence_gate.enabled, config_data.evidence_gate.query)
    v21_options = V21Options(
        input_coverage=config_data.input_hardening.enabled,
        parser_hardening=config_data.input_hardening.enabled,
        quality_score=config_data.quality.enabled,
        review_workflow=config_data.review.workflow or config_data.review.enabled,
        retrieval_eval=config_data.retrieval_eval.enabled,
        evidence_benchmark=config_data.evidence_benchmark.enabled,
        llm_quality_assist=config_data.llm_quality_assist.enabled,
    )

    if config_data.task == "build":
        manifest = _build_package(
            config_data.input,
            config_data.output,
            config_data.domain,
            config_data.mode,
            config_data.max_chars,
            config_data.overlap_chars,
            llm_options=llm_options,
            rag_options=rag_options,
            embedding_options=embedding_options,
            vector_options=vector_options,
            validation_options=validation_options,
            downstream_options=downstream_options,
            v11_options=v11_options,
            lifecycle_options=lifecycle_options,
            performance_options=performance_options,
            multimodal_options=multimodal_options,
            contract_options=contract_options,
            agent_options=agent_options,
            governance_options=governance_options,
            retrieval_index_options=retrieval_index_options,
            evidence_gate_options=evidence_gate_options,
            v21_options=v21_options,
            demo_report=config_data.demo.enabled,
        )
        _run_v12_config_outputs(config_data, config_data.output)
        if config_data.evidence_gate.enabled and config_data.llm.enabled:
            _write_llm_evidence_outputs(
                config_data.output,
                config_data.output,
                config_data.evidence_gate.query,
                config_data.llm.provider,
                config_data.llm.model,
                config_data.llm.base_url,
                config_data.llm.api_key_env,
                config_data.llm.evidence_validation,
                config_data.llm.boundary_check,
                config_data.llm.hallucination_check,
                config_data.llm.call_log,
            )
        _run_v18_config_outputs(config_data, config_data.output)
        _run_v19_config_outputs(config_data, config_data.output)
        _run_v20_config_outputs(config_data, config_data.output)
        _run_v22_config_outputs(config_data, config_data.output)
        _run_v23_config_outputs(config_data, config_data.output)
        _run_v24_config_outputs(config_data, config_data.output)
        _run_v25_config_outputs(config_data, config_data.output)
        return ConfigRunResult(
            config=config_data,
            output=config_data.output,
            message=(
                f"Built knowledge package at {config_data.output}\n"
                f"Sources: {manifest.source_count} | Chunks: {manifest.chunk_count} | Warnings: {len(manifest.warnings)}"
            ),
        )

    output = config_data.output
    output.mkdir(parents=True, exist_ok=True)
    numbered_sources = [
        path for path in sorted(config_data.input.iterdir()) if path.is_file() and _parse_numbered_stem(path)
    ]
    items = (
        _build_batch_groups(
            numbered_sources,
            output,
            config_data.domain,
            config_data.mode,
            config_data.max_chars,
            config_data.overlap_chars,
            llm_options,
            rag_options,
            embedding_options,
            vector_options,
            validation_options,
            downstream_options,
            v11_options,
            lifecycle_options,
            hardening_options=None,
            v21_options=v21_options,
            performance_options=performance_options,
            batch_reporter=None,
            multimodal_options=multimodal_options,
            contract_options=contract_options,
            agent_options=agent_options,
            demo_report=config_data.demo.enabled,
        )
        if config_data.batch.merge_same_sequence
        else _build_batch_items(
            numbered_sources,
            output,
            config_data.domain,
            config_data.mode,
            config_data.max_chars,
            config_data.overlap_chars,
            llm_options,
            rag_options,
            embedding_options,
            vector_options,
            validation_options,
            downstream_options,
            v11_options,
            lifecycle_options,
            hardening_options=None,
            v21_options=v21_options,
            performance_options=performance_options,
            batch_reporter=None,
            multimodal_options=multimodal_options,
            contract_options=contract_options,
            agent_options=agent_options,
            demo_report=config_data.demo.enabled,
        )
    )
    succeeded = sum(1 for item in items if item["status"] == "success")
    failed = sum(1 for item in items if item["status"] == "failed")
    batch_manifest = {
        "batch_version": "0.2.1",
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "input_dir": str(config_data.input).replace("\\", "/"),
        "output_dir": str(output).replace("\\", "/"),
        "merge_same_sequence": config_data.batch.merge_same_sequence,
        "total_files": len(numbered_sources),
        "succeeded": succeeded,
        "failed": failed,
        "items": items,
    }
    if config_data.batch.merge_same_sequence:
        batch_manifest["total_groups"] = len(items)

    write_json(output / "batch_manifest.json", batch_manifest)
    _write_batch_report(output / "batch_report.md", batch_manifest)
    _write_v23_batch_outputs(
        items=items,
        input_root=config_data.input,
        output_root=output,
        profile=config_data.batch.profile,
        retry_enabled=config_data.batch.retry_failed,
        resume_enabled=config_data.batch.resume_batch,
    )
    _run_v12_config_outputs(config_data, output)
    _run_v18_config_outputs(config_data, output)
    _run_v19_config_outputs(config_data, output)
    _run_v20_config_outputs(config_data, output)
    _run_v22_config_outputs(config_data, output)
    _run_v23_config_outputs(config_data, output)
    _run_v24_config_outputs(config_data, output)
    _run_v25_config_outputs(config_data, output)

    return ConfigRunResult(
        config=config_data,
        output=output,
        message=f"Built batch knowledge packages at {output}\nTotal: {len(items)} | Succeeded: {succeeded} | Failed: {failed}",
    )


def _write_llm_evidence_outputs(
    package: Path,
    output: Path,
    query: str,
    provider_name: str,
    model: str,
    base_url: str | None,
    api_key_env: str | None,
    evidence_validation: bool,
    boundary_check: bool,
    hallucination_check: bool,
    call_log: bool,
) -> None:
    api_key = os.environ.get(api_key_env) if api_key_env else None
    settings = ProviderSettings(provider_name, model, base_url, api_key)
    records = build_retrieval_index(package)
    evidence_text = "\n\n".join(record.text for record in records[:5])
    log_path = output / "llm_call_log.jsonl"
    if evidence_validation:
        result = validate_evidence_with_llm(query, evidence_text, settings)
        write_json(output / "llm_evidence_validation.json", result.model_dump(mode="json"))
        (output / "llm_evidence_validation_report.md").write_text(render_llm_evidence_report(result), encoding="utf-8")
        if call_log:
            write_call_log(log_path, {"task": "evidence_validation", "provider": provider_name, "model": model, "api_key_present": bool(api_key), "status": result.status})
    if boundary_check:
        result = judge_boundary_with_llm(query, evidence_text, settings)
        write_json(output / "llm_boundary_judgment.json", result.model_dump(mode="json"))
        if call_log:
            write_call_log(log_path, {"task": "boundary_check", "provider": provider_name, "model": model, "api_key_present": bool(api_key), "status": result.status})
    if hallucination_check:
        result = check_hallucination_with_llm(query, evidence_text, settings)
        write_json(output / "llm_hallucination_check.json", result.model_dump(mode="json"))
        if call_log:
            write_call_log(log_path, {"task": "hallucination_check", "provider": provider_name, "model": model, "api_key_present": bool(api_key), "status": result.status})


def _provider_settings(provider: str, model: str, base_url: str | None, api_key_env: str | None) -> ProviderSettings:
    return ProviderSettings(provider, model, base_url, os.environ.get(api_key_env) if api_key_env else None)


def _split_tags(tags: str) -> list[str]:
    return [tag.strip() for tag in tags.split(",") if tag.strip()]


def _apply_performance_overrides(
    config_data: ForgeConfig,
    *,
    progress: bool,
    progress_jsonl: bool,
    progress_log: Path | None,
    profile: str,
    ocr_mode: str,
    max_ocr_pages: int | None,
    ocr_workers: int,
    ocr_cache: bool,
    resume: bool,
) -> None:
    if progress:
        config_data.performance.progress = True
    if progress_jsonl:
        config_data.performance.progress_jsonl = True
    if progress_log is not None:
        config_data.performance.progress_log = progress_log
    if profile != "production":
        config_data.performance.profile = profile
    if ocr_mode != "auto":
        config_data.performance.ocr_mode = ocr_mode
    if max_ocr_pages is not None:
        config_data.performance.max_ocr_pages = max_ocr_pages
    if ocr_workers != 1:
        config_data.performance.ocr_workers = ocr_workers
    if ocr_cache:
        config_data.performance.ocr_cache = True
    if resume:
        config_data.performance.resume = True


def _run_v12_config_outputs(config_data: ForgeConfig, output: Path) -> None:
    if config_data.workspace.enabled:
        workspace = config_data.workspace.path or (output / "workspace")
        index, registry, report = init_workspace(workspace)
        write_json(workspace / "workspace_index.json", index)
        registry, report = register_package(workspace, output)
        write_json(workspace / "package_registry.json", registry)
        (workspace / "package_status_report.md").write_text(report, encoding="utf-8")
    if config_data.refresh.enabled:
        workspace = config_data.workspace.path or output
        stale, plan, report = make_refresh_plan(workspace, config_data.refresh.stale_days)
        write_jsonl(output / "stale_sources.jsonl", stale)
        write_json(output / "refresh_plan.json", plan)
        (output / "source_freshness_report.md").write_text(report, encoding="utf-8")
    if config_data.review.enabled:
        queue, report = create_review_queue(output)
        write_jsonl(output / "review_queue.jsonl", queue)
        write_jsonl(output / "review_decisions.jsonl", empty_decision_template(queue))
        (output / "curation_report.md").write_text(report, encoding="utf-8")
    if config_data.evaluation_dashboard.enabled:
        retrieval_results, answer_results, citation_report, trend_report = make_eval_dashboard(output)
        write_json(output / "retrieval_eval_results.json", retrieval_results)
        write_json(output / "answer_eval_results.json", answer_results)
        (output / "citation_hit_report.md").write_text(citation_report, encoding="utf-8")
        (output / "quality_trend_report.md").write_text(trend_report, encoding="utf-8")
    if config_data.publish.enabled:
        profile_yaml, manifest = make_publish_package(output, config_data.publish.profile, output)
        (output / "export_profile.yaml").write_text(profile_yaml, encoding="utf-8")
        write_json(output / "publish_manifest.json", manifest)
    if config_data.planning_readiness.enabled:
        blueprint, tool_map, eval_cases, report = make_planning_readiness(output)
        (output / "agent_planning_blueprint.yaml").write_text(blueprint, encoding="utf-8")
        write_json(output / "tool_requirement_map.json", tool_map)
        write_jsonl(output / "planning_eval_cases.jsonl", eval_cases)
        (output / "planning_risk_report.md").write_text(report, encoding="utf-8")
    if config_data.store.enabled:
        init_store(config_data.store.db_path)
        if config_data.store.import_package:
            if (output / "manifest.json").exists():
                import_package(config_data.store.db_path, output)
            else:
                sync_workspace(config_data.store.db_path, output)
        if config_data.store.export_index:
            manifest, packages, sources, chunks, report = export_store_index(config_data.store.db_path)
            write_json(output / "store_manifest.json", manifest)
            write_jsonl(output / "store_package_index.jsonl", packages)
            write_jsonl(output / "store_source_index.jsonl", sources)
            write_jsonl(output / "store_chunk_index.jsonl", chunks)
            (output / "store_status_report.md").write_text(report, encoding="utf-8")
    if config_data.agent_rag.enabled:
        rag_package = config_data.agent_rag.package or output
        rag_store = config_data.agent_rag.store or (config_data.store.db_path if config_data.store.enabled else None)
        scope = config_data.agent_rag.scope
        records, trace, citation_trace = (
            retrieve_from_store(rag_store, config_data.agent_rag.query, config_data.agent_rag.top_k, scope)
            if rag_store and rag_store.exists()
            else retrieve_from_package(rag_package, config_data.agent_rag.query, config_data.agent_rag.top_k, scope)
        )
        answer, report = answer_from_records(
            config_data.agent_rag.query,
            records,
            config_data.agent_rag.top_k,
            config_data.agent_rag.citation_required,
        )
        write_json(output / "retrieval_result.json", {"query": config_data.agent_rag.query, "records": [record.model_dump(mode="json") for record in records]})
        write_json(output / "retrieval_trace.json", trace)
        write_json(output / "citation_trace.json", citation_trace)
        (output / "answer.md").write_text(answer, encoding="utf-8")
        write_json(output / "answer_report.json", report.model_dump(mode="json"))
        (output / "agent_rag_config.yaml").write_text(
            f"query: {config_data.agent_rag.query}\ntop_k: {config_data.agent_rag.top_k}\ncitation_required: {str(config_data.agent_rag.citation_required).lower()}\n",
            encoding="utf-8",
        )


def _run_v18_config_outputs(config_data: ForgeConfig, output: Path) -> None:
    skill_output = output / "skill_package"
    if config_data.skill.enabled:
        settings = _provider_settings(
            config_data.llm.provider,
            config_data.llm.model or "mock-model",
            config_data.llm.base_url,
            config_data.llm.api_key_env,
        )
        if config_data.skill.llm_generation and config_data.llm.enabled:
            generate_llm_skill_package(
                output,
                skill_output,
                config_data.skill.name,
                config_data.skill.type,
                settings,
                True,
                config_data.llm.call_log,
            )
        else:
            generate_skill_package(output, skill_output, config_data.skill.name, config_data.skill.type)
        if config_data.skill.enhanced_template:
            render_enhanced_skill_template(skill_output, config_data.skill.type)
        if config_data.skill.validate_skill:
            validate_skill_package(skill_output, output, output / "skill_validation")
    if config_data.agent_package.enabled:
        if not skill_output.exists():
            generate_skill_package(output, skill_output, config_data.skill.name, config_data.skill.type)
        agent_output = output / "agent_package"
        settings = _provider_settings(
            config_data.llm.provider,
            config_data.llm.model or "mock-model",
            config_data.llm.base_url,
            config_data.llm.api_key_env,
        )
        if config_data.agent_package.llm_generation and config_data.llm.enabled:
            generate_llm_agent_package(
                output,
                skill_output,
                agent_output,
                config_data.agent_package.name,
                config_data.agent_package.type,
                settings,
                True,
                config_data.llm.call_log,
            )
        else:
            generate_agent_package(output, skill_output, agent_output, config_data.agent_package.name, config_data.agent_package.type)
        if config_data.agent_package.compat:
            export_agent_compat(agent_output, config_data.agent_package.name)


def _run_v19_config_outputs(config_data: ForgeConfig, output: Path) -> None:
    if not config_data.workspace.enabled:
        return
    workspace = config_data.workspace.path or (output / "workspace")
    init_portable_workspace(workspace)
    if config_data.workspace.register_outputs:
        register_workspace_asset(workspace, output, "knowledge")
        skill_output = output / "skill_package"
        agent_output = output / "agent_package"
        if skill_output.exists():
            register_workspace_asset(workspace, skill_output, "skill")
        if agent_output.exists():
            register_workspace_asset(workspace, agent_output, "agent")
    if config_data.provider_registry.enabled:
        providers = config_data.provider_registry.providers or [
            {"provider_id": config_data.provider_registry.default_provider, "provider_type": "mock", "default_model": "mock-model", "enabled": True}
        ]
        for provider in providers:
            add_provider(
                workspace,
                provider.get("provider_id", "mock_default"),
                provider.get("provider_type", "mock"),
                provider.get("default_model") or provider.get("model", "mock-model"),
                provider.get("api_key_env"),
            )
    if config_data.prompt_profiles.enabled:
        for profile in config_data.prompt_profiles.profiles:
            add_prompt_profile(
                workspace,
                profile.get("profile_id", "default_profile"),
                profile.get("profile_type", "custom"),
                Path(profile.get("rules_path", "")),
            )
    if config_data.llm_audit.enabled and config_data.llm_audit.import_call_logs:
        records = []
        for log_path in output.rglob("llm_call_log.jsonl"):
            records.extend(import_llm_call_logs(workspace, log_path))
        (workspace / "reports" / "llm_audit_report.md").write_text(render_llm_audit_report(records), encoding="utf-8")
    if config_data.workspace.health_check:
        check_workspace_health(workspace)


def _run_v20_config_outputs(config_data: ForgeConfig, output: Path) -> None:
    workspace = config_data.studio.workspace or config_data.workspace.path or (output / "workspace")
    if config_data.studio.enabled:
        finalize_studio_workspace(workspace, config_data.studio.project_name, output)
        write_studio_v22_outputs(workspace)
    if any(
        [
            config_data.stable_check.enabled,
            config_data.provider_health.enabled,
            config_data.reliability.enabled,
            config_data.release_package.enabled,
        ]
    ):
        init_portable_workspace(workspace)
    if config_data.stable_check.enabled:
        run_stable_check(workspace)
    if config_data.provider_health.enabled:
        check_provider_health(workspace, config_data.provider_health.allow_network)
    if config_data.reliability.enabled:
        make_reliability_score(workspace, config_data.reliability.release_threshold)
    if config_data.release_package.enabled:
        make_release_package(workspace, output / "release_package", config_data.release_package.include_demo_outputs)


def _run_v22_config_outputs(config_data: ForgeConfig, output: Path) -> None:
    workspace = config_data.workspace.path or config_data.studio.workspace or (output / "workspace")
    if config_data.workspace_refresh.enabled:
        refresh_workspace = config_data.workspace_refresh.workspace or workspace
        refresh_output = config_data.workspace_refresh.output or (output / "workspace_refresh")
        make_workspace_refresh(refresh_workspace, refresh_output)
    if config_data.provider_readiness.enabled:
        readiness_workspace = config_data.provider_readiness.workspace or workspace
        readiness_output = config_data.provider_readiness.output or (output / "provider_readiness")
        make_provider_readiness(readiness_workspace, readiness_output)
    if config_data.prompt_profile_versioning.enabled:
        profile_workspace = config_data.prompt_profile_versioning.workspace or workspace
        profile_output = config_data.prompt_profile_versioning.output or (output / "prompt_profile_versions")
        make_prompt_profile_versions(profile_workspace, profile_output)


def _run_v23_config_outputs(config_data: ForgeConfig, output: Path) -> None:
    if config_data.package_lineage.enabled:
        workspace = config_data.package_lineage.workspace or config_data.workspace.path or output
        lineage_output = config_data.package_lineage.output or output
        make_package_lineage(workspace, lineage_output)
    if config_data.curation.enabled or config_data.curation.build_curated_package:
        package = config_data.curation.package or output
        decisions = config_data.curation.review_decisions or (package / "review_decisions.jsonl")
        curated_output = config_data.curation.output or (output / "curated_package")
        build_curated_package(package, decisions, curated_output)
    if config_data.update_impact.enabled:
        workspace = config_data.update_impact.workspace or config_data.workspace.path or output
        package = config_data.update_impact.package or (output / "curated_package" if (output / "curated_package").exists() else output)
        impact_output = config_data.update_impact.output or output
        analyze_update_impact(workspace, package, impact_output)


def _run_v24_config_outputs(config_data: ForgeConfig, output: Path) -> None:
    if not config_data.platform_distribution.enabled:
        return
    skill = config_data.platform_distribution.skill or (output / "skill_package")
    agent = config_data.platform_distribution.agent or (output / "agent_package")
    agent_path = agent if agent.exists() else None
    platform_output = config_data.platform_distribution.output or (output / "platform_distribution")
    export_platform_package(skill, agent_path, platform_output, config_data.platform_distribution.platform)


def _run_v25_config_outputs(config_data: ForgeConfig, output: Path) -> None:
    workspace = config_data.workspace.path or output
    if config_data.quality_gate.enabled:
        run_quality_gate(workspace, config_data.quality_gate.output or output, config_data.quality_gate.release_threshold)
    if config_data.release_blockers.enabled:
        detect_release_blockers(workspace, config_data.release_blockers.output or output)
    if config_data.regression.enabled:
        run_regression_check(workspace, config_data.regression.output or output)
    if config_data.golden_samples.enabled and config_data.golden_samples.validate_samples:
        validate_golden_samples(config_data.golden_samples.samples_root, config_data.golden_samples.output or output)
    if config_data.export_certification.enabled:
        export_root = config_data.export_certification.export or config_data.platform_distribution.output or (output / "platform_distribution")
        platform = "all" if len(config_data.export_certification.platforms) != 1 else config_data.export_certification.platforms[0]
        certify_platform_export(export_root, config_data.export_certification.output or output, platform)
    if config_data.compatibility_matrix.enabled:
        make_compatibility_matrix(workspace, config_data.compatibility_matrix.output or output)
    if config_data.llm_quality_gate_assist.enabled:
        run_llm_quality_gate_assist(workspace, config_data.llm_quality_gate_assist.output or output, config_data.llm_quality_gate_assist.provider)
    if config_data.release_readiness.enabled:
        evaluate_release_readiness(workspace, config_data.release_readiness.output or output)


def _make_llm_options(
    enabled: bool,
    provider: str,
    model: str,
    cache: bool,
    strict: bool,
    prompt_profile_path: Path | None,
    llm_quality_report: bool,
) -> LLMOptions:
    if prompt_profile_path and not enabled:
        raise ValueError("--prompt-profile requires --llm")
    if llm_quality_report and not enabled:
        raise ValueError("--llm-quality-report requires --llm")
    prompt_profile = None
    prompt_profile_hash = None
    if prompt_profile_path:
        prompt_profile, prompt_profile_hash = load_prompt_profile(prompt_profile_path)
    return LLMOptions(
        enabled=enabled,
        provider=provider,
        model=model,
        cache=cache,
        strict=strict,
        prompt_profile_path=prompt_profile_path,
        prompt_profile=prompt_profile,
        prompt_profile_hash=prompt_profile_hash,
        quality_report=llm_quality_report,
    )


def _make_embedding_options(enabled: bool, provider: str, model: str, rag_export_enabled: bool) -> EmbeddingOptions:
    if enabled and not rag_export_enabled:
        raise ValueError("--embedding requires --rag-export")
    return EmbeddingOptions(enabled=enabled, provider=provider, model=model)


def _make_vector_options(enabled: bool, store: str, embedding_enabled: bool) -> VectorOptions:
    if enabled and not embedding_enabled:
        raise ValueError("--vector-export requires --embedding")
    return VectorOptions(enabled=enabled, store=store)


def _make_performance_options(
    progress: bool,
    progress_jsonl: bool,
    progress_log: Path | None,
    verbose: bool,
    profile: str,
    ocr_mode: str,
    ocr_lang: str,
    ocr_timeout_per_page: int,
    max_ocr_pages: int | None,
    ocr_pages: str | None,
    ocr_workers: int,
    ocr_scale: float,
    ocr_cache: bool,
    ocr_cache_dir: Path | None,
    resume: bool,
    skip_empty_pages: bool,
    skip_low_text_pages: bool,
) -> PerformanceOptions:
    if profile == "fast" and max_ocr_pages is None:
        max_ocr_pages = 10
    enabled = any(
        [
            progress,
            progress_jsonl,
            progress_log is not None,
            verbose,
            profile != "production",
            ocr_mode != "auto",
            ocr_lang != "chi_sim+eng",
            ocr_timeout_per_page != 120,
            max_ocr_pages is not None,
            ocr_pages is not None,
            ocr_workers != 1,
            ocr_scale != 1.5,
            ocr_cache,
            ocr_cache_dir is not None,
            resume,
            not skip_empty_pages,
            skip_low_text_pages,
        ]
    )
    return PerformanceOptions(
        enabled=enabled,
        progress=progress,
        progress_jsonl=progress_jsonl,
        progress_log=progress_log,
        verbose=verbose,
        profile=profile,
        ocr_mode=ocr_mode,
        ocr_lang=ocr_lang,
        ocr_timeout_per_page=ocr_timeout_per_page,
        max_ocr_pages=max_ocr_pages,
        ocr_pages=ocr_pages,
        ocr_workers=max(1, ocr_workers),
        ocr_scale=ocr_scale,
        ocr_cache=ocr_cache,
        ocr_cache_dir=ocr_cache_dir,
        resume=resume,
        skip_empty_pages=skip_empty_pages,
        skip_low_text_pages=skip_low_text_pages,
    )


def _build_batch_items(
    numbered_sources: list[Path],
    output: Path,
    domain: str,
    mode: str,
    max_chars: int,
    overlap_chars: int,
    llm_options: LLMOptions | None = None,
    rag_options: RAGOptions | None = None,
    embedding_options: EmbeddingOptions | None = None,
    vector_options: VectorOptions | None = None,
    validation_options: ValidationOptions | None = None,
    downstream_options: DownstreamOptions | None = None,
    v11_options: V11Options | None = None,
    lifecycle_options: LifecycleOptions | None = None,
    hardening_options: HardeningOptions | None = None,
    v21_options: V21Options | None = None,
    performance_options: PerformanceOptions | None = None,
    batch_reporter: ProgressReporter | None = None,
    multimodal_options: MultimodalOptions | None = None,
    contract_options: ContractOptions | None = None,
    max_chunks: int | None = None,
    continue_on_error: bool = True,
    fail_fast: bool = False,
    agent_options: AgentOptions | None = None,
    demo_report: bool = False,
) -> list[dict]:
    items: list[dict] = []
    total_chunks = 0

    for source in numbered_sources:
        item_index = len(items) + 1
        sequence_id, name = _parse_numbered_stem(source) or ("", "")
        item_output = output / f"{sequence_id}_{_safe_output_name(name)}"
        if batch_reporter:
            batch_reporter.emit("batch_item_started", "running", f"Batch item {item_index}/{len(numbered_sources)} started", current_file=str(source), current_file_index=item_index, total_files=len(numbered_sources), output_path=str(item_output))
        item = {
            "sequence_id": sequence_id,
            "name": name,
            "source_path": str(source).replace("\\", "/"),
            "output_path": str(item_output).replace("\\", "/"),
            "status": "failed",
            "error": None,
            "chunk_count": 0,
            "files": [],
        }

        try:
            if source.suffix.lower() not in PARSERS:
                raise ValueError(f"Unsupported file extension: {source.suffix}")
            if item_output.exists():
                raise FileExistsError(f"Output directory already exists: {item_output}")

            manifest = _build_package(
                source,
                item_output,
                domain,
                mode,
                max_chars,
                overlap_chars,
                llm_options=llm_options,
                rag_options=rag_options,
                embedding_options=embedding_options,
                vector_options=vector_options,
                validation_options=validation_options,
                downstream_options=downstream_options,
                v11_options=v11_options,
                lifecycle_options=lifecycle_options,
                hardening_options=hardening_options,
                v21_options=v21_options,
                performance_options=performance_options,
                multimodal_options=multimodal_options,
                contract_options=contract_options,
                agent_options=agent_options,
                demo_report=demo_report,
            )
            item["status"] = "success"
            item["chunk_count"] = manifest.chunk_count
            item["files"] = manifest.files
            total_chunks += manifest.chunk_count
            if batch_reporter:
                batch_reporter.emit("batch_item_success", "success", f"Batch item {item_index}/{len(numbered_sources)} succeeded", current_file=str(source), current_file_index=item_index, total_files=len(numbered_sources), output_path=str(item_output))
        except Exception as exc:
            item["error"] = str(exc)
            if batch_reporter:
                batch_reporter.emit("batch_item_failed", "failed", f"Batch item {item_index}/{len(numbered_sources)} failed", current_file=str(source), current_file_index=item_index, total_files=len(numbered_sources), output_path=str(item_output), error=str(exc))

        items.append(item)
        if item["status"] == "failed" and (fail_fast or not continue_on_error):
            break
        if max_chunks is not None and total_chunks >= max_chunks:
            break

    return items


def _build_batch_groups(
    numbered_sources: list[Path],
    output: Path,
    domain: str,
    mode: str,
    max_chars: int,
    overlap_chars: int,
    llm_options: LLMOptions | None = None,
    rag_options: RAGOptions | None = None,
    embedding_options: EmbeddingOptions | None = None,
    vector_options: VectorOptions | None = None,
    validation_options: ValidationOptions | None = None,
    downstream_options: DownstreamOptions | None = None,
    v11_options: V11Options | None = None,
    lifecycle_options: LifecycleOptions | None = None,
    hardening_options: HardeningOptions | None = None,
    v21_options: V21Options | None = None,
    performance_options: PerformanceOptions | None = None,
    batch_reporter: ProgressReporter | None = None,
    multimodal_options: MultimodalOptions | None = None,
    contract_options: ContractOptions | None = None,
    max_chunks: int | None = None,
    continue_on_error: bool = True,
    fail_fast: bool = False,
    agent_options: AgentOptions | None = None,
    demo_report: bool = False,
) -> list[dict]:
    groups: dict[str, list[Path]] = {}
    for source in numbered_sources:
        sequence_id, _ = _parse_numbered_stem(source) or ("", "")
        groups.setdefault(sequence_id, []).append(source)

    items: list[dict] = []
    total_chunks = 0
    for sequence_id, sources in sorted(groups.items()):
        item_index = len(items) + 1
        sources = sorted(sources, key=lambda path: path.name)
        _, group_name = _parse_numbered_stem(sources[0]) or (sequence_id, "")
        item_output = output / sequence_id
        item = {
            "sequence_id": sequence_id,
            "group_name": group_name,
            "source_paths": [str(source).replace("\\", "/") for source in sources],
            "output_path": str(item_output).replace("\\", "/"),
            "status": "failed",
            "error": None,
            "chunk_count": 0,
            "source_count": len(sources),
            "files": [],
        }
        if batch_reporter:
            batch_reporter.emit("batch_item_started", "running", f"Batch group {item_index}/{len(groups)} started", current_file=", ".join(str(source) for source in sources), current_file_index=item_index, total_files=len(groups), output_path=str(item_output))

        try:
            unsupported = [source for source in sources if source.suffix.lower() not in PARSERS]
            if unsupported:
                extensions = ", ".join(sorted({source.suffix for source in unsupported}))
                raise ValueError(f"Unsupported file extension in group: {extensions}")
            if item_output.exists():
                raise FileExistsError(f"Output directory already exists: {item_output}")

            manifest = _build_package(
                sources[0].parent,
                item_output,
                domain,
                mode,
                max_chars,
                overlap_chars,
                source_files=sources,
                llm_options=llm_options,
                rag_options=rag_options,
                embedding_options=embedding_options,
                vector_options=vector_options,
                validation_options=validation_options,
                downstream_options=downstream_options,
                v11_options=v11_options,
                lifecycle_options=lifecycle_options,
                hardening_options=hardening_options,
                v21_options=v21_options,
                performance_options=performance_options,
                multimodal_options=multimodal_options,
                contract_options=contract_options,
                agent_options=agent_options,
                demo_report=demo_report,
            )
            item["status"] = "success"
            item["chunk_count"] = manifest.chunk_count
            item["source_count"] = manifest.source_count
            item["files"] = manifest.files
            total_chunks += manifest.chunk_count
            if batch_reporter:
                batch_reporter.emit("batch_item_success", "success", f"Batch group {item_index}/{len(groups)} succeeded", current_file=", ".join(str(source) for source in sources), current_file_index=item_index, total_files=len(groups), output_path=str(item_output))
        except Exception as exc:
            item["error"] = str(exc)
            if batch_reporter:
                batch_reporter.emit("batch_item_failed", "failed", f"Batch group {item_index}/{len(groups)} failed", current_file=", ".join(str(source) for source in sources), current_file_index=item_index, total_files=len(groups), output_path=str(item_output), error=str(exc))

        items.append(item)
        if item["status"] == "failed" and (fail_fast or not continue_on_error):
            break
        if max_chunks is not None and total_chunks >= max_chunks:
            break

    return items


def _build_package(
    input: Path,
    output: Path,
    domain: str,
    mode: str,
    max_chars: int,
    overlap_chars: int,
    source_files: list[Path] | None = None,
    llm_options: LLMOptions | None = None,
    rag_options: RAGOptions | None = None,
    embedding_options: EmbeddingOptions | None = None,
    vector_options: VectorOptions | None = None,
    validation_options: ValidationOptions | None = None,
    downstream_options: DownstreamOptions | None = None,
    v11_options: V11Options | None = None,
    lifecycle_options: LifecycleOptions | None = None,
    hardening_options: HardeningOptions | None = None,
    v21_options: V21Options | None = None,
    performance_options: PerformanceOptions | None = None,
    multimodal_options: MultimodalOptions | None = None,
    contract_options: ContractOptions | None = None,
    agent_options: AgentOptions | None = None,
    governance_options: GovernanceOptions | None = None,
    retrieval_index_options: RetrievalIndexOptions | None = None,
    evidence_gate_options: EvidenceGateOptions | None = None,
    demo_report: bool = False,
) -> Manifest:
    output.mkdir(parents=True, exist_ok=True)
    source_files = source_files if source_files is not None else _collect_sources(input)
    v11_options = v11_options or V11Options()
    lifecycle_options = lifecycle_options or LifecycleOptions()
    hardening_options = hardening_options or HardeningOptions()
    v21_options = v21_options or V21Options()
    performance_options = performance_options or PerformanceOptions()
    progress_reporter = make_progress_reporter(
        progress=performance_options.progress,
        progress_jsonl=performance_options.progress_jsonl,
        progress_log=performance_options.progress_log,
        verbose=performance_options.verbose,
    )
    if progress_reporter:
        progress_reporter.configure_default_log(output)
    if progress_reporter:
        progress_reporter.emit("scan_sources", "success", f"Found {len(source_files)} source files", total_files=len(source_files), output_path=str(output))
    pdf_options = (
        PDFParseOptions(
            profile=performance_options.profile,
            ocr_mode=performance_options.ocr_mode,
            ocr_lang=performance_options.ocr_lang,
            timeout_per_page=performance_options.ocr_timeout_per_page,
            max_pages=performance_options.max_ocr_pages,
            selected_pages=performance_options.ocr_pages,
            workers=performance_options.ocr_workers,
            scale=performance_options.ocr_scale,
            cache_enabled=performance_options.ocr_cache,
            cache_dir=performance_options.ocr_cache_dir,
            resume=performance_options.resume,
            skip_empty_pages=performance_options.skip_empty_pages,
            skip_low_text_pages=performance_options.skip_low_text_pages,
            output_dir=output,
        )
        if performance_options.enabled
        else None
    )
    run_id = new_run_id() if hardening_options.run_manifest else None
    build_started_at = now_iso()
    profile = get_chunk_profile(v11_options.chunk_profile)
    if v11_options.chunk_profile != "default":
        max_chars = profile.max_chars
        overlap_chars = profile.overlap_chars
    all_chunks: list[Chunk] = []
    warnings: list[str] = []

    for source_index, source in enumerate(source_files, start=1):
        parser = PARSERS.get(source.suffix.lower())
        if parser is None:
            continue
        if progress_reporter:
            progress_reporter.emit("parse_source", "running", f"Parsing source: {source.name}", current_file=str(source), current_file_index=source_index, total_files=len(source_files), metadata={"parser_type": source.suffix.lower().lstrip(".")})
        try:
            raw = (
                parse_pdf(source, progress_callback=progress_reporter.callback() if progress_reporter else None, options=pdf_options)
                if source.suffix.lower() == ".pdf"
                else parser(source)
            )
        except NotImplementedError as exc:
            warnings.append(str(exc))
            continue
        except Exception as exc:
            if multimodal_options and multimodal_options.enabled and source.suffix.lower() in IMAGE_SUFFIXES:
                warnings.append(f"Image OCR failed; preserved as multimodal asset: {source}")
                if progress_reporter:
                    progress_reporter.emit("parse_source", "warning", f"Image preserved as multimodal asset: {source.name}", current_file=str(source), current_file_index=source_index, total_files=len(source_files), warning=str(exc))
                continue
            if progress_reporter:
                progress_reporter.emit("failed", "failed", f"Source parsing failed: {source.name}", current_file=str(source), current_file_index=source_index, total_files=len(source_files), error=str(exc))
            raise
        if progress_reporter:
            progress_reporter.emit("clean_text", "running", f"Cleaning text: {source.name}", current_file=str(source), current_file_index=source_index, total_files=len(source_files))
        cleaned = clean_text(raw)
        if not cleaned:
            warnings.append(f"Source produced no text: {source}")
            if progress_reporter:
                progress_reporter.emit("parse_source", "warning", f"Source produced no text: {source.name}", current_file=str(source), current_file_index=source_index, total_files=len(source_files), warning="empty_text")
            continue
        source_chunks = chunk_text(
            cleaned,
            source_path=source,
            source_type=source.suffix.lower().lstrip("."),
            domain=domain,
            mode=mode,
            max_chars=max_chars,
            overlap_chars=overlap_chars,
        )
        all_chunks.extend(source_chunks)
        if progress_reporter:
            progress_reporter.emit("chunk_text", "success", f"Chunked source: {len(source_chunks)} chunks", current_file=str(source), current_file_index=source_index, total_files=len(source_files), metadata={"chunk_count": len(source_chunks)})

    warnings.extend(validate_chunks(all_chunks))
    cards = make_cards(all_chunks)
    qa_pairs = make_qa_pairs(all_chunks)
    glossary = make_glossary(all_chunks)
    if progress_reporter:
        progress_reporter.emit("build_assets", "success", "Built offline knowledge assets", metadata={"card_count": len(cards), "qa_count": len(qa_pairs), "glossary_count": len(glossary)})
    quality_report = make_quality_report(len(source_files), all_chunks, cards, qa_pairs, glossary)
    if progress_reporter:
        progress_reporter.emit("quality_report", "success", "Built quality report", metadata={"quality_score": quality_report.get("quality_score"), "quality_level": quality_report.get("quality_level")})
    llm_options = llm_options or LLMOptions()
    llm_result = extract_llm_assets(all_chunks, llm_options) if llm_options.enabled else None
    llm_quality_result = (
        make_llm_quality_report(llm_result.outputs, llm_options)
        if llm_options.enabled and llm_options.quality_report and llm_result
        else None
    )
    rag_options = rag_options or RAGOptions()
    rag_warnings: list[str] = []
    if rag_options.enabled and rag_options.include_llm and not llm_options.enabled:
        rag_warnings.append("RAG include LLM requested but LLM is not enabled")
    rag_result = (
        make_rag_export(
            chunks=all_chunks,
            cards=cards,
            qa_pairs=qa_pairs,
            glossary=glossary,
            quality_report=quality_report,
            options=rag_options,
            llm_outputs=llm_result.outputs if llm_result and rag_options.include_llm else None,
        )
        if rag_options.enabled
        else None
    )
    if rag_result:
        rag_result.warnings.extend(rag_warnings)
        if progress_reporter:
            progress_reporter.emit("rag_export", "success", "Built RAG export", output_path=str(output / "rag_manifest.json"))
    embedding_options = embedding_options or EmbeddingOptions()
    embedding_records = []
    embedding_manifest = None
    if embedding_options.enabled and rag_result:
        embedding_records, embedding_manifest = make_embeddings(
            rag_result.embedding_inputs,
            embedding_options.provider,
            embedding_options.model,
        )
    vector_options = vector_options or VectorOptions()
    vector_records = []
    vector_manifest = None
    if vector_options.enabled:
        vector_records, vector_manifest = make_vector_export(embedding_records, vector_options.store)
    downstream_options = downstream_options or DownstreamOptions()
    downstream_result = (
        make_downstream_exports(all_chunks, cards, qa_pairs, glossary, quality_report)
        if downstream_options.enabled
        else None
    )
    kg_result = make_knowledge_graph(cards, glossary, llm_result.outputs if llm_result else None) if v11_options.knowledge_graph else None
    eval_result = (
        make_retrieval_eval_set(qa_pairs, cards, glossary, llm_result.outputs if llm_result else None)
        if v11_options.retrieval_eval
        else None
    )
    agent_options = agent_options or AgentOptions()
    agent_result = (
        make_agent_template(
            output=output,
            domain=domain,
            mode=mode,
            source_count=len(source_files),
            chunk_count=len(all_chunks),
            quality_report=quality_report,
            cards=cards,
            qa_pairs=qa_pairs,
            glossary=glossary,
            rag_enabled=rag_options.enabled,
            llm_assets_enabled=llm_options.enabled,
            options=agent_options,
        )
        if agent_options.enabled
        else None
    )
    demo_result = (
        make_demo_report(
            package_path=output,
            domain=domain,
            mode=mode,
            source_count=len(source_files),
            chunks=all_chunks,
            cards=cards,
            qa_pairs=qa_pairs,
            glossary=glossary,
            quality_report=quality_report,
            rag_export_enabled=rag_options.enabled,
            agent_template_enabled=agent_options.enabled,
            eval_cases=agent_result.eval_cases if agent_result else None,
        )
        if demo_report
        else None
    )
    multimodal_options = multimodal_options or MultimodalOptions()
    multimodal_result = build_multimodal_assets(input, source_files, multimodal_options)
    contract_options = contract_options or ContractOptions()
    governance_options = governance_options or GovernanceOptions()
    retrieval_index_options = retrieval_index_options or RetrievalIndexOptions()
    evidence_gate_options = evidence_gate_options or EvidenceGateOptions()

    files = [
        "chunks.jsonl",
        "cards.jsonl",
        "qa_pairs.jsonl",
        "glossary.jsonl",
        "manifest.json",
        "ingest_report.md",
        "quality_report.json",
    ]
    if llm_options.enabled:
        files.extend(OUTPUT_FILES.values())
    if llm_options.enabled and llm_options.quality_report:
        files.extend(LLM_QUALITY_OUTPUT_FILES)
    if rag_options.enabled:
        files.extend(RAG_OUTPUT_FILES)
    if embedding_options.enabled:
        files.extend(EMBEDDING_OUTPUT_FILES)
    if vector_options.enabled:
        files.extend(VECTOR_OUTPUT_FILES)
    if downstream_options.enabled:
        files.extend(DOWNSTREAM_OUTPUT_FILES)
    if agent_options.enabled:
        files.extend(AGENT_OUTPUT_FILES)
    if demo_report:
        files.extend(DEMO_OUTPUT_FILES)
    if multimodal_options.enabled:
        files.extend(multimodal_result.output_files)
    validation_options = validation_options or ValidationOptions()
    if validation_options.enabled:
        files.extend(VALIDATION_OUTPUT_FILES)
    if v11_options.versioning or v11_options.incremental:
        files.append("package_version.json")
    if v11_options.incremental:
        files.extend(INCREMENTAL_OUTPUT_FILES)
    if v11_options.knowledge_graph:
        files.extend(KNOWLEDGE_GRAPH_OUTPUT_FILES)
    if v11_options.retrieval_eval:
        files.extend(RETRIEVAL_EVAL_OUTPUT_FILES)
    if v11_options.risk_labels:
        files.extend(RISK_OUTPUT_FILES)
    if v11_options.runtime:
        files.extend(RUNTIME_OUTPUT_FILES)
    if lifecycle_options.enabled:
        files.extend(LIFECYCLE_OUTPUT_FILES)
    if performance_options.enabled:
        files.extend(
            [
                "pdf_preflight_report.json",
                "pdf_page_classification.jsonl",
                "ocr_cache_manifest.json",
                "ocr_failed_pages.jsonl",
                "ocr_resume_report.md",
                "large_file_performance_report.md",
            ]
        )
    if progress_reporter and progress_reporter.log_path and progress_reporter.log_path.parent == output:
        files.append(progress_reporter.log_path.name)
    if hardening_options.quality_gate:
        files.extend(VALIDATION_OUTPUT_FILES)
        files.extend(QUALITY_GATE_OUTPUT_FILES)
    if hardening_options.run_manifest:
        files.extend(HARDENING_TRACE_FILES)
    if any(
        [
            v21_options.input_coverage,
            v21_options.parser_hardening,
            v21_options.quality_score,
            v21_options.review_workflow,
            v21_options.retrieval_eval,
            v21_options.evidence_benchmark,
            v21_options.llm_quality_assist,
        ]
    ):
        files.extend(V21_OUTPUT_FILES)
    if contract_options.version == "v2" or contract_options.check:
        files.extend(["evidence_map.json", "source_inventory.json", "quality_report.md"])
    if contract_options.check:
        files.extend(["contract_check_result.json", "contract_check_report.md"])
    if governance_options.enabled:
        files.extend(GOVERNANCE_OUTPUT_FILES)
    if retrieval_index_options.enabled:
        files.extend(RETRIEVAL_OUTPUT_FILES)
    if evidence_gate_options.enabled:
        files.extend(EVIDENCE_GATE_OUTPUT_FILES)
    files = _dedupe_files(files)
    manifest = Manifest(
        domain=domain,
        mode=mode,
        source_count=len(source_files),
        chunk_count=len(all_chunks),
        card_count=len(cards),
        qa_pair_count=len(qa_pairs),
        glossary_count=len(glossary),
        files=files,
        quality_report_file="quality_report.json",
        warnings=warnings + (llm_result.warnings if llm_result else []) + (rag_result.warnings if rag_result else rag_warnings),
    )

    write_jsonl(output / "chunks.jsonl", all_chunks)
    write_jsonl(output / "cards.jsonl", cards)
    write_jsonl(output / "qa_pairs.jsonl", qa_pairs)
    write_jsonl(output / "glossary.jsonl", glossary)
    if llm_options.enabled and llm_result:
        for extraction_type, file_name in OUTPUT_FILES.items():
            write_jsonl(output / file_name, llm_result.outputs[extraction_type])
    if llm_quality_result:
        write_json(output / "llm_quality_report.json", llm_quality_result.report.model_dump(mode="json"))
        (output / "llm_quality_summary.md").write_text(llm_quality_result.summary, encoding="utf-8")
    if rag_options.enabled and rag_result:
        write_jsonl(output / "embedding_input.jsonl", rag_result.embedding_inputs)
        write_jsonl(output / "retrieval_metadata.jsonl", rag_result.retrieval_metadata)
        write_json(output / "citation_map.json", rag_result.citation_map)
        write_json(output / "rag_manifest.json", rag_result.rag_manifest)
    if embedding_options.enabled:
        write_jsonl(output / "embeddings.jsonl", embedding_records)
        write_json(output / "embedding_manifest.json", embedding_manifest)
    if vector_options.enabled:
        write_jsonl(output / "vector_store_records.jsonl", vector_records)
        write_json(output / "vector_store_manifest.json", vector_manifest)
    if downstream_options.enabled and downstream_result:
        write_jsonl(output / "langchain_documents.jsonl", downstream_result["langchain_documents"])
        write_jsonl(output / "llamaindex_documents.jsonl", downstream_result["llamaindex_documents"])
        write_json(output / "generic_rag_package.json", downstream_result["generic_rag_package"])
        write_json(output / "openai_files_manifest.json", downstream_result["openai_files_manifest"])
    if kg_result:
        entities, relations, kg_manifest = kg_result
        write_jsonl(output / "entities.jsonl", entities)
        write_jsonl(output / "relations.jsonl", relations)
        write_json(output / "knowledge_graph_manifest.json", kg_manifest)
    if eval_result:
        retrieval_records, golden_qa, citation_eval = eval_result
        write_jsonl(output / "retrieval_eval_set.jsonl", retrieval_records)
        write_jsonl(output / "golden_qa.jsonl", golden_qa)
        write_jsonl(output / "citation_eval_set.jsonl", citation_eval)
        if progress_reporter:
            progress_reporter.emit("retrieval_eval", "success", "Built retrieval eval export", output_path=str(output))
    if agent_options.enabled and agent_result:
        (output / "agent_profile.yaml").write_text(agent_result.agent_profile, encoding="utf-8")
        (output / "system_prompt.md").write_text(agent_result.system_prompt, encoding="utf-8")
        (output / "retrieval_config.yaml").write_text(agent_result.retrieval_config, encoding="utf-8")
        (output / "tools.yaml").write_text(agent_result.tools, encoding="utf-8")
        write_jsonl(output / "eval_cases.jsonl", agent_result.eval_cases)
        if progress_reporter:
            progress_reporter.emit("agent_template", "success", "Built Agent Template", output_path=str(output / "agent_profile.yaml"))
    if demo_report and demo_result:
        (output / "demo_report.md").write_text(demo_result.demo_report, encoding="utf-8")
        write_json(output / "demo_manifest.json", demo_result.demo_manifest.model_dump(mode="json"))
        write_json(output / "eval_summary.json", demo_result.eval_summary.model_dump(mode="json"))
    if multimodal_options.enabled:
        write_jsonl(output / "multimodal_assets.jsonl", multimodal_result.assets)
        write_json(output / "multimodal_evidence_map.json", multimodal_result.evidence_map)
        (output / "multimodal_report.md").write_text(multimodal_result.report, encoding="utf-8")
        if multimodal_result.slide_chunks:
            write_jsonl(output / "slide_chunks.jsonl", multimodal_result.slide_chunks)
    write_json(output / "quality_report.json", quality_report)
    if performance_options.enabled:
        active_pdf_options = pdf_options or PDFParseOptions()
        write_json(output / "pdf_preflight_report.json", {"pdf_preflight_version": "1.6.2", "reports": active_pdf_options.preflight_reports})
        write_jsonl(output / "pdf_page_classification.jsonl", active_pdf_options.page_classifications)
        write_jsonl(output / "ocr_failed_pages.jsonl", active_pdf_options.failed_pages)
        write_json(output / "ocr_cache_manifest.json", {"ocr_cache_manifest_version": "1.6.2", "cache_hits": active_pdf_options.cache_hits, "cache_writes": active_pdf_options.cache_writes})
        (output / "ocr_resume_report.md").write_text(make_resume_report(active_pdf_options.failed_pages, active_pdf_options.cache_hits), encoding="utf-8")
        (output / "large_file_performance_report.md").write_text(make_performance_report(active_pdf_options.performance_records), encoding="utf-8")
        if progress_reporter:
            progress_reporter.emit("performance_report", "success", "Built large file performance report", output_path=str(output / "large_file_performance_report.md"))
    manifest_payload = manifest.model_dump(mode="json")
    manifest_payload["chunk_profile"] = v11_options.chunk_profile
    contract_enabled = contract_options.version == "v2" or contract_options.check
    if contract_enabled:
        manifest_payload.update(
            {
                "contract_version": "2.0",
                "package_id": f"pkg_{output.name or 'knowledge_package'}",
                "created_at": manifest_payload.get("generated_at"),
                "table_count": 0,
                "asset_count": len(multimodal_result.assets),
                "multimodal_asset_count": len(multimodal_result.assets),
                "parser_versions": {"contract": "v2", "multimodal": "v1.6"},
                "quality_status": quality_report.get("quality_level", "warning"),
                "review_status": "required" if multimodal_result.review_required_count else "none",
                "progress_status": "completed" if progress_reporter and progress_reporter.log_path else "not_enabled",
                "ocr_status": "completed" if performance_options.enabled else "not_enabled",
                "multimodal_status": "completed" if multimodal_options.enabled else "not_enabled",
                "rag_status": "completed" if rag_result else "not_enabled",
                "agent_template_status": "completed" if agent_result else "not_enabled",
            }
        )
    llm_summary = None
    llm_quality_summary = None
    if llm_options.enabled and llm_result:
        llm_summary = {
            "enabled": True,
            "provider": llm_options.provider,
            "model": llm_options.model,
            "prompt_profile": llm_options.prompt_profile.profile_name if llm_options.prompt_profile else None,
            "output_files": llm_result.output_files,
            "warnings_count": len(llm_result.warnings),
        }
        manifest_payload.update(
            {
                "llm_enabled": True,
                "llm_provider": llm_options.provider,
                "llm_model": llm_options.model,
                "llm_output_files": llm_result.output_files,
            }
        )
        if llm_options.prompt_profile:
            manifest_payload.update(
                {
                    "llm_prompt_profile": llm_options.prompt_profile.profile_name,
                    "llm_prompt_profile_file": str(llm_options.prompt_profile_path).replace("\\", "/"),
                }
            )
        if llm_quality_result:
            llm_quality_summary = {
                "enabled": True,
                "llm_quality_score": llm_quality_result.report.llm_quality_score,
                "llm_quality_level": llm_quality_result.report.llm_quality_level,
                "warnings_count": len(llm_quality_result.report.warnings),
                "output_files": llm_quality_result.output_files,
            }
            manifest_payload.update(
                {
                    "llm_quality_report_enabled": True,
                    "llm_quality_report_file": "llm_quality_report.json",
                    "llm_quality_summary_file": "llm_quality_summary.md",
                }
            )
    rag_summary = None
    embedding_summary = None
    vector_summary = None
    if rag_options.enabled and rag_result:
        rag_summary = {
            "enabled": True,
            "profile": rag_options.profile,
            "include_llm": rag_options.include_llm,
            "output_files": rag_result.output_files,
            "total_records": rag_result.rag_manifest["total_records"],
            "asset_type_counts": rag_result.rag_manifest["asset_type_counts"],
        }
        manifest_payload.update(
            {
                "rag_export_enabled": True,
                "rag_profile": rag_options.profile,
                "rag_export_files": rag_result.output_files,
            }
        )
    if embedding_options.enabled and embedding_manifest:
        embedding_summary = {
            "enabled": True,
            "provider": embedding_options.provider,
            "model": embedding_options.model,
            "output_files": EMBEDDING_OUTPUT_FILES,
            "total_records": embedding_manifest["total_records"],
            "warnings_count": len(embedding_manifest["warnings"]),
        }
        manifest_payload.update(
            {
                "embedding_enabled": True,
                "embedding_provider": embedding_options.provider,
                "embedding_model": embedding_options.model,
                "embedding_files": EMBEDDING_OUTPUT_FILES,
            }
        )
    if vector_options.enabled and vector_manifest:
        vector_summary = {
            "enabled": True,
            "store": vector_options.store,
            "output_files": VECTOR_OUTPUT_FILES,
            "total_records": vector_manifest["total_records"],
            "warnings_count": len(vector_manifest["warnings"]),
        }
        manifest_payload.update(
            {
                "vector_export_enabled": True,
                "vector_store": vector_options.store,
                "vector_export_files": VECTOR_OUTPUT_FILES,
            }
        )
    downstream_summary = None
    if downstream_options.enabled and downstream_result:
        downstream_summary = {
            "downstream_export_enabled": True,
            "downstream_export_files": DOWNSTREAM_OUTPUT_FILES,
        }
        manifest_payload.update(downstream_summary)
    if kg_result:
        manifest_payload.update({"knowledge_graph_export_enabled": True, "knowledge_graph_files": KNOWLEDGE_GRAPH_OUTPUT_FILES})
    if eval_result:
        manifest_payload.update({"retrieval_eval_export_enabled": True, "retrieval_eval_files": RETRIEVAL_EVAL_OUTPUT_FILES})
    agent_summary = None
    if agent_options.enabled and agent_result:
        agent_name = agent_options.agent_name or f"{output.name or 'knowledge'}_agent"
        agent_summary = {
            "enabled": True,
            "agent_type": agent_options.agent_type,
            "agent_name": agent_name,
            "language": agent_options.language,
            "output_files": agent_result.output_files,
        }
        manifest_payload.update(
            {
                "agent_template_enabled": True,
                "agent_type": agent_options.agent_type,
                "agent_template_files": agent_result.output_files,
            }
        )
    demo_summary = None
    if demo_report and demo_result:
        demo_summary = {
            "enabled": True,
            "final_status": demo_result.demo_manifest.final_status,
            "quality_score": demo_result.demo_manifest.quality_score,
            "quality_level": demo_result.demo_manifest.quality_level,
            "warnings_count": len(demo_result.demo_manifest.warnings),
            "output_files": demo_result.output_files,
        }
        manifest_payload.update(
            {
                "demo_report_enabled": True,
                "demo_report_files": demo_result.output_files,
            }
        )
    if contract_enabled:
        write_json(output / "evidence_map.json", _make_evidence_map(all_chunks))
        write_json(output / "source_inventory.json", _make_source_inventory(source_files))
        (output / "quality_report.md").write_text(_render_quality_report_md(quality_report), encoding="utf-8")
    if any(
        [
            v21_options.input_coverage,
            v21_options.parser_hardening,
            v21_options.quality_score,
            v21_options.review_workflow,
            v21_options.retrieval_eval,
            v21_options.evidence_benchmark,
            v21_options.llm_quality_assist,
        ]
    ):
        make_v21_quality_outputs(output, output, llm_quality_assist=v21_options.llm_quality_assist)
    write_json(output / "manifest.json", manifest_payload)
    write_report(
        output / "ingest_report.md",
        manifest,
        quality_report,
        llm_summary,
        rag_summary,
        agent_summary,
        demo_summary,
        llm_quality_summary,
        embedding_summary,
        vector_summary,
    )
    if governance_options.enabled:
        run_governance(output, output, governance_options.previous_package)
        manifest_payload.update({"governance_enabled": True, "governance_files": GOVERNANCE_OUTPUT_FILES})
        write_json(output / "manifest.json", manifest_payload)
    if retrieval_index_options.enabled:
        build_retrieval_outputs(output, output, retrieval_index_options.query)
        manifest_payload.update({"retrieval_index_enabled": True, "retrieval_index_files": RETRIEVAL_OUTPUT_FILES})
        write_json(output / "manifest.json", manifest_payload)
    if evidence_gate_options.enabled:
        run_evidence_gate(output, output, evidence_gate_options.query)
        manifest_payload.update({"evidence_gate_enabled": True, "evidence_gate_files": EVIDENCE_GATE_OUTPUT_FILES})
        write_json(output / "manifest.json", manifest_payload)
    if contract_options.check:
        contract_result = check_package_contract(output, strict=contract_options.strict)
        write_json(output / "contract_check_result.json", contract_result.model_dump(mode="json"))
        (output / "contract_check_report.md").write_text(make_contract_report(contract_result), encoding="utf-8")
    lifecycle_summary = None
    if lifecycle_options.enabled:
        lifecycle_summary = _write_lifecycle_outputs(output, input, source_files, lifecycle_options)
        manifest_payload.update(
            {
                "lifecycle_enabled": True,
                "lifecycle_files": LIFECYCLE_OUTPUT_FILES,
                "update_mode": lifecycle_options.update_mode,
                "missing_source_policy": lifecycle_options.missing_source_policy,
                "source_registry_file": "source_registry.json",
                "update_quality_gate_status": lifecycle_summary["update_quality_gate_status"],
            }
        )
        write_json(output / "manifest.json", manifest_payload)
    validation_required = validation_options.enabled or hardening_options.quality_gate
    if validation_required:
        validation_report, readiness_report = validate_package(output)
        write_json(output / "package_validation_report.json", validation_report.model_dump(mode="json"))
        (output / "package_readiness_report.md").write_text(readiness_report, encoding="utf-8")
    validation_payload = None
    if (output / "package_validation_report.json").exists():
        import json

        validation_payload = json.loads((output / "package_validation_report.json").read_text(encoding="utf-8"))
    if v11_options.risk_labels:
        risk_labels, risk_report = make_risk_labels(all_chunks, cards, qa_pairs, glossary, llm_result.outputs if llm_result else None, validation_payload)
        write_jsonl(output / "risk_labels.jsonl", risk_labels)
        (output / "source_reliability_report.md").write_text(risk_report, encoding="utf-8")
    if v11_options.versioning or v11_options.incremental:
        write_json(output / "package_version.json", make_package_version(output).model_dump(mode="json"))
    if v11_options.incremental:
        incremental_manifest, incremental_report = make_incremental_report(output, v11_options.previous_package)
        write_json(output / "incremental_manifest.json", incremental_manifest)
        (output / "incremental_report.md").write_text(incremental_report, encoding="utf-8")
    if v11_options.runtime:
        answer, answer_report, retrieval_trace = ask_package(
            output,
            "Summarize this knowledge package.",
            v11_options.runtime_top_k,
            v11_options.runtime_provider,
            v11_options.runtime_model,
        )
        (output / "answer.md").write_text(answer, encoding="utf-8")
        write_json(output / "answer_report.json", answer_report.model_dump(mode="json"))
        write_json(output / "retrieval_trace.json", retrieval_trace)
    quality_gate_report = None
    if hardening_options.quality_gate:
        quality_gate_report, quality_gate_summary, package_acceptance_report = evaluate_quality_gate(output)
        write_json(output / "quality_gate_report.json", quality_gate_report)
        (output / "quality_gate_summary.md").write_text(quality_gate_summary, encoding="utf-8")
        (output / "package_acceptance_report.md").write_text(package_acceptance_report, encoding="utf-8")
        manifest_payload.update(
            {
                "quality_gate_enabled": True,
                "quality_gate_status": quality_gate_report["status"],
                "quality_gate_files": QUALITY_GATE_OUTPUT_FILES,
            }
        )
        write_json(output / "manifest.json", manifest_payload)
    if hardening_options.run_manifest and run_id:
        status = "failed" if quality_gate_report and quality_gate_report["status"] == "fail" else "success"
        finished_at = now_iso()
        stage = stage_record(
            run_id,
            "package_build",
            status,
            build_started_at,
            finished_at,
            input_files=[str(path).replace("\\", "/") for path in source_files],
            output_files=files,
            warnings=manifest.warnings,
            error="quality_gate_failed" if status == "failed" else None,
        )
        if progress_reporter:
            stage["progress_summary"] = {
                "event_count": len(progress_reporter.events),
                "progress_log": str(progress_reporter.log_path).replace("\\", "/") if progress_reporter.log_path else None,
            }
        write_json(output / "run_manifest.json", make_run_manifest(run_id, "build", str(input).replace("\\", "/"), str(output).replace("\\", "/"), status, manifest.warnings))
        write_jsonl(output / "stage_trace.jsonl", [stage])
        write_json(output / "error_report.json", {"error_report_version": "1.2.1", "run_id": run_id, "errors": []})
    if hardening_options.quality_gate_strict and quality_gate_report and quality_gate_report["status"] == "fail":
        raise RuntimeError("Quality gate failed")

    if progress_reporter:
        progress_reporter.emit(
            "done",
            "success",
            "Build complete",
            total_files=len(source_files),
            output_path=str(output),
            metadata={"source_count": len(source_files), "chunk_count": len(all_chunks), "warning_count": len(manifest.warnings)},
        )

    return manifest


def _collect_sources(input_path: Path) -> list[Path]:
    if input_path.is_file():
        return [input_path] if input_path.suffix.lower() in PARSERS else []
    return sorted(path for path in input_path.rglob("*") if path.is_file() and path.suffix.lower() in PARSERS)


def _make_evidence_map(chunks: list[Chunk]) -> dict:
    return {
        "evidence_version": "2.0",
        "chunks": {
            chunk.chunk_id: {
                "evidence_id": f"ev_{chunk.chunk_id}",
                "source_file": chunk.source_path,
                "source_id": chunk.source_path,
                "page_number": None,
                "slide_number": chunk.metadata.get("slide_number") if chunk.metadata else None,
                "paragraph_index": None,
                "table_id": None,
                "asset_id": None,
                "bbox": None,
                "evidence_type": chunk.source_type if chunk.source_type in {"table", "image", "chart", "slide", "formula", "mindmap"} else "text",
                "extraction_method": "parser",
            }
            for chunk in chunks
        },
    }


def _make_source_inventory(source_files: list[Path]) -> dict:
    return {
        "source_inventory_version": "2.0",
        "source_count": len(source_files),
        "sources": [
            {
                "source_id": str(path).replace("\\", "/"),
                "source_file": str(path).replace("\\", "/"),
                "source_type": path.suffix.lower().lstrip("."),
            }
            for path in source_files
        ],
    }


def _render_quality_report_md(quality_report: dict) -> str:
    rows = "\n".join(f"- {key}: {value}" for key, value in quality_report.items())
    return f"# Quality Report\n\n{rows}\n"


def _write_lifecycle_outputs(
    output: Path,
    input_path: Path,
    source_files: list[Path],
    options: LifecycleOptions,
) -> dict[str, str]:
    current_registry = make_source_registry(input_path, source_files)
    previous_registry = load_source_registry(options.previous_package)
    change_report, changed, missing, new, unchanged = detect_source_changes(previous_registry, current_registry)
    incremental = make_incremental_outputs(
        output=output,
        previous_package=options.previous_package,
        changed_sources=changed,
        missing_sources=missing,
        new_sources=new,
        unchanged_sources=unchanged,
        update_mode=options.update_mode,
        missing_source_policy=options.missing_source_policy,
    )
    update_gate, regression_report = make_update_quality_gate(output, options.previous_package)
    retry_manifest_payload = dict(incremental["retry_manifest"])
    if options.retry_manifest:
        retry_manifest_payload["retry_source_manifest"] = str(options.retry_manifest).replace("\\", "/")

    write_json(output / "source_registry.json", current_registry.model_dump(mode="json"))
    (output / "source_change_report.md").write_text(render_source_change_report(change_report), encoding="utf-8")
    write_jsonl(output / "changed_sources.jsonl", changed)
    write_jsonl(output / "missing_sources.jsonl", missing)
    write_jsonl(output / "new_sources.jsonl", new)
    (output / "incremental_update_report.md").write_text(incremental["incremental_report"], encoding="utf-8")
    write_jsonl(output / "reused_chunks.jsonl", incremental["reused_chunks"])
    write_jsonl(output / "rebuilt_chunks.jsonl", incremental["rebuilt_chunks"])
    write_jsonl(output / "removed_chunks.jsonl", incremental["removed_chunks"])
    write_jsonl(output / "stale_chunks.jsonl", incremental["stale_chunks"])
    (output / "removed_source_impact_report.md").write_text(incremental["removed_source_impact_report"], encoding="utf-8")
    write_json(output / "update_quality_gate_report.json", update_gate)
    (output / "quality_regression_report.md").write_text(regression_report, encoding="utf-8")
    write_jsonl(output / "failed_sources.jsonl", incremental["failed_sources"])
    write_json(output / "retry_manifest.json", retry_manifest_payload)
    (output / "retry_report.md").write_text(incremental["retry_report"], encoding="utf-8")
    return {"update_quality_gate_status": update_gate["status"]}


def _dedupe_files(files: list[str]) -> list[str]:
    return list(dict.fromkeys(files))


def _parse_numbered_stem(path: Path) -> tuple[str, str] | None:
    match = re.match(r"^(\d+)_(.+)$", path.stem)
    if not match:
        return None
    return match.group(1), match.group(2)


def _safe_output_name(name: str) -> str:
    safe = re.sub(r'[<>:"/\\|?*\x00-\x1f]', "_", name).strip(" .")
    return safe or "untitled"


def _write_batch_report(path: Path, batch_manifest: dict) -> None:
    merge_same_sequence = batch_manifest.get("merge_same_sequence", False)
    if merge_same_sequence:
        successful_rows = [
            f"| {item['sequence_id']} | {item['group_name']} | {item['output_path']} | {item['source_count']} | {item['chunk_count']} |"
            for item in batch_manifest["items"]
            if item["status"] == "success"
        ]
        failed_rows = [
            f"| {item['sequence_id']} | {item['group_name']} | {', '.join(item['source_paths'])} | {item['error']} |"
            for item in batch_manifest["items"]
            if item["status"] == "failed"
        ]
        source_sections = [
            f"### {item['sequence_id']} {item['group_name']}\n\n"
            + "\n".join(f"- {source_path}" for source_path in item["source_paths"])
            for item in batch_manifest["items"]
        ]
        successful_header = "| Sequence | Group Name | Output Path | Sources | Chunks |"
        successful_separator = "| --- | --- | --- | --- | --- |"
        failed_header = "| Sequence | Group Name | Source Paths | Error |"
        failed_separator = "| --- | --- | --- | --- |"
        empty_successful = "| - | - | - | - | - |"
    else:
        successful_rows = [
            f"| {item['sequence_id']} | {item['name']} | {item['output_path']} | {item['chunk_count']} |"
            for item in batch_manifest["items"]
            if item["status"] == "success"
        ]
        failed_rows = [
            f"| {item['sequence_id']} | {item['name']} | {item['source_path']} | {item['error']} |"
            for item in batch_manifest["items"]
            if item["status"] == "failed"
        ]
        source_sections = []
        successful_header = "| Sequence | Name | Output Path | Chunks |"
        successful_separator = "| --- | --- | --- | --- |"
        failed_header = "| Sequence | Name | Source Path | Error |"
        failed_separator = "| --- | --- | --- | --- |"
        empty_successful = "| - | - | - | - |"

    content = f"""# HeiTang KB Forge Batch Report

## Batch Summary

- Input directory: {batch_manifest['input_dir']}
- Output directory: {batch_manifest['output_dir']}
- Merge same sequence: {batch_manifest.get('merge_same_sequence', False)}
- Total files: {batch_manifest['total_files']}
{f"- Total groups: {batch_manifest['total_groups']}" if 'total_groups' in batch_manifest else ""}
- Succeeded: {batch_manifest['succeeded']}
- Failed: {batch_manifest['failed']}

## Successful Items

{successful_header}
{successful_separator}
{chr(10).join(successful_rows) if successful_rows else empty_successful}

## Group Source Files

{chr(10).join(source_sections) if source_sections else "- Not using same-sequence merge mode."}

## Failed Items

{failed_header}
{failed_separator}
{chr(10).join(failed_rows) if failed_rows else "| - | - | - | - |"}

## Standard Package Output

Each successful item directory contains:

- chunks.jsonl
- cards.jsonl
- qa_pairs.jsonl
- glossary.jsonl
- manifest.json
- ingest_report.md
- quality_report.json
"""
    path.write_text(content, encoding="utf-8")


def _write_v23_batch_outputs(
    *,
    items: list[dict],
    input_root: Path,
    output_root: Path,
    profile: str,
    retry_enabled: bool,
    resume_enabled: bool,
) -> None:
    manifest, statuses = build_job_outputs(
        items=items,
        input_root=input_root,
        output_root=output_root,
        profile=profile,
        retry_enabled=retry_enabled,
        resume_enabled=resume_enabled,
    )
    write_job_outputs(output_root, manifest, statuses)
    write_batch_summaries(output_root, manifest, statuses)


def _within_file_size_guard(path: Path, memory_guard: bool, max_file_size_mb: int) -> bool:
    if not memory_guard:
        return True
    return path.stat().st_size <= max_file_size_mb * 1024 * 1024


if __name__ == "__main__":
    app()
