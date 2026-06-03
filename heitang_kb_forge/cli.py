from pathlib import Path
from datetime import datetime, timezone
from dataclasses import dataclass
import re

import typer

from heitang_kb_forge.agent.generator import make_agent_template
from heitang_kb_forge.agent.templates import AGENT_OUTPUT_FILES
from heitang_kb_forge.config.loader import load_config
from heitang_kb_forge.eval.demo import DEMO_OUTPUT_FILES, make_demo_report
from heitang_kb_forge.exporters.jsonl_exporter import write_json, write_jsonl
from heitang_kb_forge.exporters.report_exporter import write_report
from heitang_kb_forge.llm.extractor import LLMOptions, OUTPUT_FILES, extract_llm_assets
from heitang_kb_forge.parsers.docx_parser import parse_docx
from heitang_kb_forge.parsers.image_parser import parse_image
from heitang_kb_forge.parsers.markdown_parser import parse_markdown
from heitang_kb_forge.parsers.pdf_parser import parse_pdf
from heitang_kb_forge.parsers.table_parser import parse_csv, parse_tsv, parse_xlsx
from heitang_kb_forge.parsers.text_parser import parse_text
from heitang_kb_forge.processors.chunker import chunk_text
from heitang_kb_forge.processors.cleaner import clean_text
from heitang_kb_forge.processors.extractor import make_cards, make_glossary, make_qa_pairs
from heitang_kb_forge.processors.quality import make_quality_report
from heitang_kb_forge.processors.validator import validate_chunks
from heitang_kb_forge.pipeline.reporter import make_pipeline_report
from heitang_kb_forge.rag.exporter import RAGOptions, RAG_OUTPUT_FILES, make_rag_export
from heitang_kb_forge.schemas.config_schema import ForgeConfig
from heitang_kb_forge.schemas.chunk_schema import Chunk
from heitang_kb_forge.schemas.agent_schema import AgentOptions
from heitang_kb_forge.schemas.manifest_schema import Manifest

app = typer.Typer(help="Build local standardized knowledge base packages.")

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
    rag_export: bool = typer.Option(False, "--rag-export"),
    rag_profile: str = typer.Option("basic", "--rag-profile"),
    rag_include_llm: bool = typer.Option(False, "--rag-include-llm"),
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
        llm_options=LLMOptions(llm, llm_provider, llm_model, llm_cache, llm_strict),
        rag_options=RAGOptions(rag_export, rag_profile, rag_include_llm),
        agent_options=AgentOptions(
            enabled=agent_template,
            agent_type=agent_type,
            agent_name=agent_name,
            language=agent_language,
        ),
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
    rag_export: bool = typer.Option(False, "--rag-export"),
    rag_profile: str = typer.Option("basic", "--rag-profile"),
    rag_include_llm: bool = typer.Option(False, "--rag-include-llm"),
    agent_template: bool = typer.Option(False, "--agent-template"),
    agent_type: str = typer.Option("generic_agent", "--agent-type"),
    agent_name: str | None = typer.Option(None, "--agent-name"),
    agent_language: str = typer.Option("zh-CN", "--agent-language"),
    demo_report: bool = typer.Option(False, "--demo-report"),
) -> None:
    """Build one knowledge package per numbered source file."""
    output.mkdir(parents=True, exist_ok=True)
    numbered_sources = [path for path in sorted(input.iterdir()) if path.is_file() and _parse_numbered_stem(path)]
    llm_options = LLMOptions(llm, llm_provider, llm_model, llm_cache, llm_strict)
    rag_options = RAGOptions(rag_export, rag_profile, rag_include_llm)
    agent_options = AgentOptions(
        enabled=agent_template,
        agent_type=agent_type,
        agent_name=agent_name,
        language=agent_language,
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
    }
    if merge_same_sequence:
        batch_manifest["total_groups"] = len(items)

    write_json(output / "batch_manifest.json", batch_manifest)
    _write_batch_report(output / "batch_report.md", batch_manifest)

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


def _run_config(config_data: ForgeConfig) -> ConfigRunResult:
    llm_options = LLMOptions(
        config_data.llm.enabled,
        config_data.llm.provider,
        config_data.llm.model,
        config_data.llm.cache,
        config_data.llm.strict,
    )
    rag_options = RAGOptions(
        config_data.rag.enabled,
        config_data.rag.profile,
        config_data.rag.include_llm,
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
            agent_options=agent_options,
            demo_report=config_data.demo.enabled,
        )
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
            agent_options,
            config_data.demo.enabled,
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
            agent_options,
            config_data.demo.enabled,
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

    return ConfigRunResult(
        config=config_data,
        output=output,
        message=f"Built batch knowledge packages at {output}\nTotal: {len(items)} | Succeeded: {succeeded} | Failed: {failed}",
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
    agent_options: AgentOptions | None = None,
    demo_report: bool = False,
) -> list[dict]:
    items: list[dict] = []

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
                agent_options=agent_options,
                demo_report=demo_report,
            )
            item["status"] = "success"
            item["chunk_count"] = manifest.chunk_count
            item["files"] = manifest.files
        except Exception as exc:
            item["error"] = str(exc)

        items.append(item)

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
    agent_options: AgentOptions | None = None,
    demo_report: bool = False,
) -> list[dict]:
    groups: dict[str, list[Path]] = {}
    for source in numbered_sources:
        sequence_id, _ = _parse_numbered_stem(source) or ("", "")
        groups.setdefault(sequence_id, []).append(source)

    items: list[dict] = []
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
                agent_options=agent_options,
                demo_report=demo_report,
            )
            item["status"] = "success"
            item["chunk_count"] = manifest.chunk_count
            item["source_count"] = manifest.source_count
            item["files"] = manifest.files
        except Exception as exc:
            item["error"] = str(exc)

        items.append(item)

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
    agent_options: AgentOptions | None = None,
    demo_report: bool = False,
) -> Manifest:
    output.mkdir(parents=True, exist_ok=True)
    source_files = source_files if source_files is not None else _collect_sources(input)
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
    if rag_options.enabled:
        files.extend(RAG_OUTPUT_FILES)
    if agent_options.enabled:
        files.extend(AGENT_OUTPUT_FILES)
    if demo_report:
        files.extend(DEMO_OUTPUT_FILES)
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
    if rag_options.enabled and rag_result:
        write_jsonl(output / "embedding_input.jsonl", rag_result.embedding_inputs)
        write_jsonl(output / "retrieval_metadata.jsonl", rag_result.retrieval_metadata)
        write_json(output / "citation_map.json", rag_result.citation_map)
        write_json(output / "rag_manifest.json", rag_result.rag_manifest)
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
    llm_summary = None
    if llm_options.enabled and llm_result:
        llm_summary = {
            "enabled": True,
            "provider": llm_options.provider,
            "model": llm_options.model,
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
    rag_summary = None
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
    write_report(output / "ingest_report.md", manifest, quality_report, llm_summary, rag_summary, agent_summary, demo_summary)

    return manifest


def _collect_sources(input_path: Path) -> list[Path]:
    if input_path.is_file():
        return [input_path] if input_path.suffix.lower() in PARSERS else []
    return sorted(path for path in input_path.rglob("*") if path.is_file() and path.suffix.lower() in PARSERS)


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
