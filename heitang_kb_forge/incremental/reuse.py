from pathlib import Path
import shutil

from heitang_kb_forge.versioning.package_version import make_package_version

INCREMENTAL_OUTPUT_FILES = ["incremental_manifest.json", "incremental_report.md"]


def make_incremental_report(output: Path, previous_package: Path | None) -> tuple[dict, str]:
    warnings: list[str] = []
    reused_files: list[str] = []
    rebuilt_files: list[str] = []
    previous_hash = None
    current = make_package_version(output)
    if previous_package and previous_package.exists() and (previous_package / "chunks.jsonl").exists():
        previous = make_package_version(previous_package)
        previous_hash = previous.package_hash
        if previous.package_hash == current.package_hash:
            for name in ["llm_cards.jsonl", "llm_qa_pairs.jsonl", "llm_glossary.jsonl", "embeddings.jsonl", "vector_store_records.jsonl"]:
                source = previous_package / name
                target = output / name
                if source.exists() and not target.exists():
                    shutil.copy2(source, target)
                    reused_files.append(name)
        else:
            warnings.append("Previous package hash differs; rebuilt current package.")
    else:
        warnings.append("Previous package missing or incomplete; rebuilt current package.")
    if not reused_files:
        rebuilt_files = ["chunks.jsonl", "cards.jsonl", "qa_pairs.jsonl", "glossary.jsonl"]
    manifest = {
        "incremental_version": "1.1.0",
        "previous_package": str(previous_package).replace("\\", "/") if previous_package else None,
        "previous_package_hash": previous_hash,
        "current_package_hash": current.package_hash,
        "reused_files": reused_files,
        "rebuilt_files": rebuilt_files,
        "warnings": warnings,
    }
    report = _render_report(manifest)
    return manifest, report


def _render_report(manifest: dict) -> str:
    reused = "\n".join(f"- {name}" for name in manifest["reused_files"]) or "- None"
    rebuilt = "\n".join(f"- {name}" for name in manifest["rebuilt_files"]) or "- None"
    warnings = "\n".join(f"- {warning}" for warning in manifest["warnings"]) or "- None"
    return f"""# Incremental Build Report

## Summary

- Previous package: {manifest['previous_package']}
- Previous package hash: {manifest['previous_package_hash']}
- Current package hash: {manifest['current_package_hash']}

## Reused Files

{reused}

## Rebuilt Files

{rebuilt}

## Warnings

{warnings}
"""
