from __future__ import annotations

from datetime import datetime, timezone
from uuid import uuid4

from pydantic import BaseModel, Field


STAGES = {
    "scan_sources",
    "parse_source",
    "extract_pdf_text",
    "extract_pdf_table",
    "ocr_pdf",
    "ocr_page",
    "clean_text",
    "chunk_text",
    "build_assets",
    "quality_report",
    "rag_export",
    "agent_template",
    "validation",
    "quality_gate",
    "risk_labels",
    "retrieval_eval",
    "write_outputs",
    "done",
    "failed",
    "batch_started",
    "batch_item_started",
    "batch_item_success",
    "batch_item_failed",
    "batch_done",
}

STATUSES = {"started", "running", "success", "warning", "failed", "skipped"}


class ProgressEvent(BaseModel):
    event_id: str = Field(default_factory=lambda: f"evt_{uuid4().hex[:12]}")
    timestamp: str = Field(default_factory=lambda: datetime.now(timezone.utc).isoformat())
    stage: str
    status: str
    message: str
    current_file: str | None = None
    current_file_index: int | None = None
    total_files: int | None = None
    current_page: int | None = None
    total_pages: int | None = None
    duration_ms: int | None = None
    warning: str | None = None
    error: str | None = None
    output_path: str | None = None
