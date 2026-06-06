from __future__ import annotations

from pathlib import Path

from heitang_kb_forge.parser_backends.base import ParserBackendRecord, ParserBackendRun
from heitang_kb_forge.parser_backends.normalize import column_safe_path, normalize_text, source_type


def reimport_corrected_text(corrected_text: Path, command: str) -> tuple[ParserBackendRun, dict]:
    files = _collect_corrected_files(corrected_text)
    records = []
    for path in files:
        text = normalize_text(path.read_text(encoding="utf-8", errors="ignore"))
        records.append(
            ParserBackendRecord(
                source_path=column_safe_path(path),
                source_type=source_type(path) or "txt",
                backend_name="corrected_text",
                backend_version="2.8.0-alpha.1",
                command=command,
                status="success" if text else "empty",
                text=text,
                warnings=[] if text else ["empty_corrected_text"],
                confidence=1.0 if text else 0.0,
                metadata={"corrected_text": True},
            )
        )
    reviewed = bool(records) and all(record.status == "success" for record in records)
    run = ParserBackendRun(
        backend_name="corrected_text",
        backend_version="2.8.0-alpha.1",
        command=command,
        status="success" if reviewed else "warning",
        source_count=len(records),
        records=records,
        warnings=[] if records else ["no_corrected_text_files"],
        kb_trust_status="reviewed_knowledge_base" if reviewed else "draft_knowledge_package",
    )
    diff = {
        "before_after_quality_diff_version": "2.8.0-alpha.1",
        "status": "pass" if reviewed else "warning",
        "before": {"kb_trust_status": "draft_knowledge_package"},
        "after": {"kb_trust_status": run.kb_trust_status, "record_count": len(records)},
        "warnings": run.warnings,
    }
    return run, diff


def _collect_corrected_files(path: Path) -> list[Path]:
    if path.is_file():
        return [path]
    return sorted(item for item in path.rglob("*") if item.is_file() and item.suffix.lower() in {".txt", ".md", ".markdown"})
