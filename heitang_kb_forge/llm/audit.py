from pathlib import Path
import json

from heitang_kb_forge.exporters.jsonl_exporter import write_jsonl
from heitang_kb_forge.schemas.llm_audit_schema import LLMCallAuditRecord


def import_llm_call_logs(workspace: Path, source_log: Path) -> list[dict]:
    records = []
    if source_log.exists():
        for index, line in enumerate(source_log.read_text(encoding="utf-8").splitlines(), start=1):
            if not line.strip():
                continue
            payload = json.loads(line)
            records.append(
                LLMCallAuditRecord(
                    call_id=f"call_{index}",
                    workspace_id=workspace.name,
                    provider_id=payload.get("provider"),
                    task=payload.get("task", "other"),
                    status=payload.get("status", "success"),
                    input_summary="redacted",
                    output_summary="redacted",
                ).model_dump(mode="json")
            )
    audit_path = workspace / "registries" / "llm_call_audit.jsonl"
    existing = _read_jsonl(audit_path)
    write_jsonl(audit_path, existing + records)
    return records


def _read_jsonl(path: Path) -> list[dict]:
    if not path.exists():
        return []
    return [json.loads(line) for line in path.read_text(encoding="utf-8").splitlines() if line.strip()]
