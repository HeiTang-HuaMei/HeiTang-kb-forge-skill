from __future__ import annotations

import json
from pathlib import Path

from heitang_kb_forge.multi_source_ingestion import run_multi_source_ingestion


def make_multi_source_run(tmp_path: Path, *, ingestion_mode: str = "opencli_bridge") -> Path:
    source = tmp_path / "sources.json"
    source.write_text(
        json.dumps(
            {
                "items": [
                    {
                        "source_id": "thread-1-a",
                        "source_type": "x_thread_export",
                        "thread_id": "thread-1",
                        "order_index": 1,
                        "created_at": "2026-01-01T00:00:00Z",
                        "text": "Local-first knowledge should preserve source citations and privacy.",
                    },
                    {
                        "source_id": "thread-1-b",
                        "source_type": "blog_article",
                        "thread_id": "thread-1",
                        "order_index": 2,
                        "created_at": "2026-01-02T00:00:00Z",
                        "text": "Guide Skill creation should normalize viewpoints before agent-bound knowledge.",
                    },
                    {
                        "source_id": "note-1",
                        "source_type": "local_note",
                        "thread_id": "note-1",
                        "order_index": 1,
                        "created_at": "2026-01-03T00:00:00Z",
                        "text": "OpenCLI bridge imports local files only and stores no cookies sessions or tokens.",
                    },
                    {
                        "source_id": "note-1-duplicate",
                        "source_type": "local_note",
                        "thread_id": "note-1",
                        "order_index": 2,
                        "created_at": "2026-01-04T00:00:00Z",
                        "text": "OpenCLI bridge imports local files only and stores no cookies sessions or tokens.",
                    },
                ]
            },
            ensure_ascii=False,
        ),
        encoding="utf-8",
    )
    output = tmp_path / "out"
    run_multi_source_ingestion([source], output, ingestion_mode=ingestion_mode)
    return output


def read_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))
