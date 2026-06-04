from pathlib import Path
from datetime import datetime, timezone
from dataclasses import dataclass
import re

import typer

from heitang_kb_forge.agent.generator import make_agent_template
from heitang_kb_forge.agent.templates import AGENT_OUTPUT_FILES
from heitang_kb_forge.agent_rag.answerer import answer_from_records
from heitang_kb_forge.agent_rag.retriever import retrieve_from_package, retrieve_from_store
from heitang_kb_forge.agent_rag.scope import parse_scope
from heitang_kb_forge.agent_tools.exporter import make_tool_exports
from heitang_kb_forge.agent_tools.invoker import invoke_tool
from heitang_kb_forge.agent_tools.registry import get_agent_tool, list_agent_tools
from heitang_kb_forge.config.loader import load_config
from heitang_kb_forge.downstream.exporter import DOWNSTREAM_OUTPUT_FILES, make_downstream_exports
from heitang_kb_forge.embedding.exporter import EMBEDDING_OUTPUT_FILES, make_embeddings
from heitang_kb_forge.eval.demo import DEMO_OUTPUT_FILES, make_demo_report
from heitang_kb_forge.evalset.exporter import RETRIEVAL_EVAL_OUTPUT_FILES, make_retrieval_eval_set
from heitang_kb_forge.exporters.jsonl_exporter import write_json, write_jsonl
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
from heitang_kb_forge.llm.prompt_profile import load_prompt_profile
from heitang_kb_forge.llm.quality import LLM_QUALITY_OUTPUT_FILES, make_llm_quality_report
from heitang_kb_forge.parsers.docx_parser import parse_docx
from heitang_kb_forge.parsers.image_parser import parse_image
from heitang_kb_forge.parsers.markdown_parser import parse_markdown
from heitang_kb_forge.parsers.pdf_parser import parse_pdf
from heitang_kb_forge.parsers.table_parser import parse_csv, parse_tsv, parse_xlsx
from heitang_kb_forge.parsers.text_parser import parse_text
from heitang_kb_forge.processors.chunker import chunk_text
from heitang_kb_forge.processors.chunk_profiles import get_chunk_profile
from heitang_kb_forge.processors.cleaner import clean_text
from heitang_kb_forge.processors.extractor import make_cards, make_glossary, make_qa_pairs
from heitang_kb_forge.processors.quality import make_quality_report
from heitang_kb_forge.processors.validator import validate_chunks
from heitang_kb_forge.pipeline.reporter import make_pipeline_report
from heitang_kb_forge.quality_gate.gate import QUALITY_GATE_OUTPUT_FILES, evaluate_quality_gate
from heitang_kb_forge.rag.exporter import RAGOptions, RAG_OUTPUT_FILES, make_rag_export
from heitang_kb_forge.refresh.checker import make_refresh_plan
from heitang_kb_forge.risk.labeler import RISK_OUTPUT_FILES, make_risk_labels
from heitang_kb_forge.runtime.agent_runtime import RUNTIME_OUTPUT_FILES, ask_package
from heitang_kb_forge.review.curation import apply_review_decisions, create_review_queue, empty_decision_template
from heitang_kb_forge.publish.profiles import make_publish_package
from heitang_kb_forge.planning.readiness import make_planning_readiness
from heitang_kb_forge.validation.package_validator import VALIDATION_OUTPUT_FILES, validate_package
from heitang_kb_forge.vector.exporter import VECTOR_OUTPUT_FILES, make_vector_export
from heitang_kb_forge.versioning.diff import DIFF_OUTPUT_FILES, diff_packages
from heitang_kb_forge.versioning.package_version import make_package_version
from heitang_kb_forge.workspace.registry import init_workspace, register_package, workspace_status
from heitang_kb_forge.schemas.config_schema import ForgeConfig
from heitang_kb_forge.schemas.chunk_schema import Chunk
from heitang_kb_forge.schemas.agent_schema import AgentOptions
from heitang_kb_forge.schemas.manifest_schema import Manifest
from heitang_kb_forge.mcp.config import make_mcp_config
from heitang_kb_forge.store.db import init_store
from heitang_kb_forge.store.exporter import STORE_OUTPUT_FILES, export_store_index
from heitang_kb_forge.store.importer import import_package, sync_workspace
from heitang_kb_forge.store.query import list_packages, package_status, query_packages

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
    ".pdf": parse_pdf,
    ".docx": parse_docx,
    ".csv": parse_csv,
    ".tsv": parse_tsv,
    ".xlsx": parse_xlsx,
    ".png": parse_image,
    ".jpg": parse_image,
    ".jpeg": parse_image,
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
    agent_template: bool = typer.Option(False, "--agent-template"),
    agent_type: str = typer.Option("generic_agent", "--agent-type"),
    agent_name: str | None = typer.Option(None, "--agent-name"),
    agent_language: str = typer.Option("zh-CN", "--agent-language"),
    demo_report: bool = typer.Option(False, "--demo-report"),
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
        demo_report=demo_report,
    )

    typer.echo(f"Built knowledge package at {output}")
    typer.echo(f"Sources: {manifest.source_count} | Chunks: {manifest.chunk_count} | Warnings: {len(manifest.warnings)}")


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
    continue_on_error: bool = typer.Option(True, "--continue-on-error/--no-continue-on-error"),
    fail_fast: bool = typer.Option(False, "--fail-fast"),
    max_files: int | None = typer.Option(None, "--max-files"),
    max_chunks: int | None = typer.Option(None, "--max-chunks"),
    agent_template: bool = typer.Option(False, "--agent-template"),
    agent_type: str = typer.Option("generic_agent", "--agent-type"),
    agent_name: str | None = typer.Option(None, "--agent-name"),
    agent_language: str = typer.Option("zh-CN", "--agent-language"),
    demo_report: bool = typer.Option(False, "--demo-report"),
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
    lifecycle_options = LifecycleOptions(
        enabled=lifecycle or update_mode != "full" or retry_manifest is not None,
        update_mode=update_mode,
        previous_package=previous_package,
        missing_source_policy=missing_source_policy,
        quality_gate=quality_gate or quality_gate_strict,
        retry_manifest=retry_manifest,
    )
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

    write_json(output / "batch_manifest.json", batch_manifest)
    _write_batch_report(output / "batch_report.md", batch_manifest)
    batch_summary, batch_run_report, failed_items, retry_manifest = make_batch_hardening_outputs(batch_manifest)
    write_json(output / "batch_run_summary.json", batch_summary)
    (output / "batch_run_report.md").write_text(batch_run_report, encoding="utf-8")
    write_jsonl(output / "failed_items.jsonl", failed_items)
    write_json(output / "retry_manifest.json", retry_manifest)

    typer.echo(f"Built batch knowledge packages at {output}")
    typer.echo(f"Total: {len(items)} | Succeeded: {succeeded} | Failed: {failed}")


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
) -> None:
    """Run a config-driven pipeline and write pipeline reports."""
    config_data = load_config(config)
    result = _run_config(config_data)
    pipeline_manifest, pipeline_report = make_pipeline_report(config_file=config, config=result.config, output=result.output)
    write_json(result.output / "pipeline_manifest.json", pipeline_manifest.model_dump(mode="json"))
    (result.output / "pipeline_report.md").write_text(pipeline_report, encoding="utf-8")
    typer.echo(result.message)
    typer.echo(f"Built pipeline report at {result.output}")


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
    agent_options = AgentOptions(
        enabled=config_data.agent.enabled,
        agent_type=config_data.agent.type,
        agent_name=config_data.agent.name,
        language=config_data.agent.language,
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
            agent_options=agent_options,
            demo_report=config_data.demo.enabled,
        )
        _run_v12_config_outputs(config_data, config_data.output)
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
    _run_v12_config_outputs(config_data, output)

    return ConfigRunResult(
        config=config_data,
        output=output,
        message=f"Built batch knowledge packages at {output}\nTotal: {len(items)} | Succeeded: {succeeded} | Failed: {failed}",
    )


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
    max_chunks: int | None = None,
    continue_on_error: bool = True,
    fail_fast: bool = False,
    agent_options: AgentOptions | None = None,
    demo_report: bool = False,
) -> list[dict]:
    items: list[dict] = []
    total_chunks = 0

    for source in numbered_sources:
        sequence_id, name = _parse_numbered_stem(source) or ("", "")
        item_output = output / f"{sequence_id}_{_safe_output_name(name)}"
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
                agent_options=agent_options,
                demo_report=demo_report,
            )
            item["status"] = "success"
            item["chunk_count"] = manifest.chunk_count
            item["files"] = manifest.files
            total_chunks += manifest.chunk_count
        except Exception as exc:
            item["error"] = str(exc)

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
                agent_options=agent_options,
                demo_report=demo_report,
            )
            item["status"] = "success"
            item["chunk_count"] = manifest.chunk_count
            item["source_count"] = manifest.source_count
            item["files"] = manifest.files
            total_chunks += manifest.chunk_count
        except Exception as exc:
            item["error"] = str(exc)

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
    agent_options: AgentOptions | None = None,
    demo_report: bool = False,
) -> Manifest:
    output.mkdir(parents=True, exist_ok=True)
    source_files = source_files if source_files is not None else _collect_sources(input)
    v11_options = v11_options or V11Options()
    lifecycle_options = lifecycle_options or LifecycleOptions()
    hardening_options = hardening_options or HardeningOptions()
    run_id = new_run_id() if hardening_options.run_manifest else None
    build_started_at = now_iso()
    profile = get_chunk_profile(v11_options.chunk_profile)
    if v11_options.chunk_profile != "default":
        max_chars = profile.max_chars
        overlap_chars = profile.overlap_chars
    all_chunks: list[Chunk] = []
    warnings: list[str] = []

    for source in source_files:
        parser = PARSERS.get(source.suffix.lower())
        if parser is None:
            continue
        try:
            raw = parser(source)
        except NotImplementedError as exc:
            warnings.append(str(exc))
            continue
        cleaned = clean_text(raw)
        if not cleaned:
            warnings.append(f"Source produced no text: {source}")
            continue
        all_chunks.extend(
            chunk_text(
                cleaned,
                source_path=source,
                source_type=source.suffix.lower().lstrip("."),
                domain=domain,
                mode=mode,
                max_chars=max_chars,
                overlap_chars=overlap_chars,
            )
        )

    warnings.extend(validate_chunks(all_chunks))
    cards = make_cards(all_chunks)
    qa_pairs = make_qa_pairs(all_chunks)
    glossary = make_glossary(all_chunks)
    quality_report = make_quality_report(len(source_files), all_chunks, cards, qa_pairs, glossary)
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
    if hardening_options.quality_gate:
        files.extend(VALIDATION_OUTPUT_FILES)
        files.extend(QUALITY_GATE_OUTPUT_FILES)
    if hardening_options.run_manifest:
        files.extend(HARDENING_TRACE_FILES)
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
    if agent_options.enabled and agent_result:
        (output / "agent_profile.yaml").write_text(agent_result.agent_profile, encoding="utf-8")
        (output / "system_prompt.md").write_text(agent_result.system_prompt, encoding="utf-8")
        (output / "retrieval_config.yaml").write_text(agent_result.retrieval_config, encoding="utf-8")
        (output / "tools.yaml").write_text(agent_result.tools, encoding="utf-8")
        write_jsonl(output / "eval_cases.jsonl", agent_result.eval_cases)
    if demo_report and demo_result:
        (output / "demo_report.md").write_text(demo_result.demo_report, encoding="utf-8")
        write_json(output / "demo_manifest.json", demo_result.demo_manifest.model_dump(mode="json"))
        write_json(output / "eval_summary.json", demo_result.eval_summary.model_dump(mode="json"))
    write_json(output / "quality_report.json", quality_report)
    manifest_payload = manifest.model_dump(mode="json")
    manifest_payload["chunk_profile"] = v11_options.chunk_profile
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
        write_json(output / "run_manifest.json", make_run_manifest(run_id, "build", str(input).replace("\\", "/"), str(output).replace("\\", "/"), status, manifest.warnings))
        write_jsonl(output / "stage_trace.jsonl", [stage])
        write_json(output / "error_report.json", {"error_report_version": "1.2.1", "run_id": run_id, "errors": []})
    if hardening_options.quality_gate_strict and quality_gate_report and quality_gate_report["status"] == "fail":
        raise RuntimeError("Quality gate failed")

    return manifest


def _collect_sources(input_path: Path) -> list[Path]:
    if input_path.is_file():
        return [input_path] if input_path.suffix.lower() in PARSERS else []
    return sorted(path for path in input_path.rglob("*") if path.is_file() and path.suffix.lower() in PARSERS)


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


if __name__ == "__main__":
    app()
