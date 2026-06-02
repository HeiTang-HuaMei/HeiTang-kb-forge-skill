from pathlib import Path

from kb_forge.schemas.manifest_schema import Manifest


def write_report(path: Path, manifest: Manifest) -> None:
    warning_lines = "\n".join(f"- {item}" for item in manifest.warnings) or "- None"
    content = f"""# KB Forge Ingest Report

## Summary

- Domain: {manifest.domain}
- Mode: {manifest.mode}
- Sources: {manifest.source_count}
- Chunks: {manifest.chunk_count}
- Cards: {manifest.card_count}
- QA pairs: {manifest.qa_pair_count}
- Glossary terms: {manifest.glossary_count}

## Output Files

{chr(10).join(f"- {name}" for name in manifest.files)}

## Warnings

{warning_lines}
"""
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")
