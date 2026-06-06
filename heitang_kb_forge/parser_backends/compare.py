from __future__ import annotations

from pathlib import Path

from heitang_kb_forge.parser_backends.registry import parse_sources_with_backend


def compare_backends(input_path: Path, backend_names: list[str], command: str) -> dict:
    runs = [parse_sources_with_backend(input_path, name, command) for name in backend_names]
    by_source: dict[str, list[dict]] = {}
    for run in runs:
        for record in run.records:
            by_source.setdefault(record.source_path, []).append(record.to_dict())

    differences = []
    for source_path, records in sorted(by_source.items()):
        texts = {record["backend_name"]: record.get("text", "") for record in records}
        lengths = {name: len(text) for name, text in texts.items()}
        statuses = {record["backend_name"]: record.get("status") for record in records}
        if len(set(texts.values())) > 1 or len(set(statuses.values())) > 1:
            differences.append(
                {
                    "source_path": source_path,
                    "statuses": statuses,
                    "text_lengths": lengths,
                    "summary": f"status={statuses}; text_lengths={lengths}",
                }
            )
    unavailable = [run.backend_name for run in runs if run.status == "unavailable"]
    return {
        "parse_compare_version": "2.8.0-alpha.1",
        "status": "warning" if differences or unavailable else "pass",
        "backends": [run.backend_name for run in runs],
        "source_count": len(by_source),
        "unavailable_backends": unavailable,
        "differences": differences,
        "runs": [run.to_dict() for run in runs],
    }

