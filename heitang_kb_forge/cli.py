from pathlib import Path

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
    output.mkdir(parents=True, exist_ok=True)
    source_files = _collect_sources(input)
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

    files = ["chunks.jsonl", "cards.jsonl", "qa_pairs.jsonl", "glossary.jsonl", "manifest.json", "ingest_report.md"]
    manifest = Manifest(
        domain=domain,
        mode=mode,
        source_count=len(source_files),
        chunk_count=len(all_chunks),
        card_count=len(cards),
        qa_pair_count=len(qa_pairs),
        glossary_count=len(glossary),
        files=files,
        warnings=warnings,
    )

    write_jsonl(output / "chunks.jsonl", all_chunks)
    write_jsonl(output / "cards.jsonl", cards)
    write_jsonl(output / "qa_pairs.jsonl", qa_pairs)
    write_jsonl(output / "glossary.jsonl", glossary)
    write_json(output / "manifest.json", manifest)
    write_report(output / "ingest_report.md", manifest)

    typer.echo(f"Built knowledge package at {output}")
    typer.echo(f"Sources: {len(source_files)} | Chunks: {len(all_chunks)} | Warnings: {len(warnings)}")


def _collect_sources(input_path: Path) -> list[Path]:
    if input_path.is_file():
        return [input_path] if input_path.suffix.lower() in PARSERS else []
    return sorted(path for path in input_path.rglob("*") if path.is_file() and path.suffix.lower() in PARSERS)


if __name__ == "__main__":
    app()
