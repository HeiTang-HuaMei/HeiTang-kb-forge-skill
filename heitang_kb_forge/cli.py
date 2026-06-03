from pathlib import Path
from datetime import datetime, timezone
import re

import typer

from heitang_kb_forge.exporters.jsonl_exporter import write_json, write_jsonl
from heitang_kb_forge.exporters.report_exporter import write_report
from heitang_kb_forge.parsers.docx_parser import parse_docx
from heitang_kb_forge.parsers.markdown_parser import parse_markdown
from heitang_kb_forge.parsers.pdf_parser import parse_pdf
from heitang_kb_forge.parsers.text_parser import parse_text
from heitang_kb_forge.processors.chunker import chunk_text
from heitang_kb_forge.processors.cleaner import clean_text
from heitang_kb_forge.processors.extractor import make_cards, make_glossary, make_qa_pairs
from heitang_kb_forge.processors.quality import make_quality_report
from heitang_kb_forge.processors.validator import validate_chunks
from heitang_kb_forge.schemas.chunk_schema import Chunk
from heitang_kb_forge.schemas.manifest_schema import Manifest

app = typer.Typer(help="Build local standardized knowledge base packages.")

PARSERS = {
    ".md": parse_markdown,
    ".markdown": parse_markdown,
    ".txt": parse_text,
    ".pdf": parse_pdf,
    ".docx": parse_docx,
}


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
) -> None:
    """Parse source files and write a V0 knowledge base package."""
    manifest = _build_package(input, output, domain, mode, max_chars, overlap_chars)

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
) -> None:
    """Build one knowledge package per numbered source file."""
    output.mkdir(parents=True, exist_ok=True)
    numbered_sources = [path for path in sorted(input.iterdir()) if path.is_file() and _parse_numbered_stem(path)]
    items = (
        _build_batch_groups(numbered_sources, output, domain, mode, max_chars, overlap_chars)
        if merge_same_sequence
        else _build_batch_items(numbered_sources, output, domain, mode, max_chars, overlap_chars)
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


def _build_batch_items(
    numbered_sources: list[Path],
    output: Path,
    domain: str,
    mode: str,
    max_chars: int,
    overlap_chars: int,
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

            manifest = _build_package(source, item_output, domain, mode, max_chars, overlap_chars)
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

    files = [
        "chunks.jsonl",
        "cards.jsonl",
        "qa_pairs.jsonl",
        "glossary.jsonl",
        "manifest.json",
        "ingest_report.md",
        "quality_report.json",
    ]
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
        warnings=warnings,
    )

    write_jsonl(output / "chunks.jsonl", all_chunks)
    write_jsonl(output / "cards.jsonl", cards)
    write_jsonl(output / "qa_pairs.jsonl", qa_pairs)
    write_jsonl(output / "glossary.jsonl", glossary)
    write_json(output / "quality_report.json", quality_report)
    write_json(output / "manifest.json", manifest)
    write_report(output / "ingest_report.md", manifest, quality_report)

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
