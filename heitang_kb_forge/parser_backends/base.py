from __future__ import annotations

from dataclasses import dataclass, field
from pathlib import Path


TRUST_STATUSES = {
    "raw_parse_output",
    "draft_knowledge_package",
    "reviewed_knowledge_base",
    "trusted_agent_kb",
}
UNTRUSTED_STATUSES = {"raw_parse_output", "draft_knowledge_package"}
TRUSTED_STATUSES = {"reviewed_knowledge_base", "trusted_agent_kb"}
LEGACY_TRUST_STATUS = "legacy_untracked"


@dataclass
class ParserBackendRecord:
    source_path: str
    source_type: str
    backend_name: str
    backend_version: str
    command: str
    status: str
    text: str = ""
    warnings: list[str] = field(default_factory=list)
    confidence: float = 1.0
    metadata: dict[str, str | int | float | bool | None] = field(default_factory=dict)

    def to_dict(self) -> dict:
        return {
            "source_path": self.source_path,
            "source_type": self.source_type,
            "backend_name": self.backend_name,
            "backend_version": self.backend_version,
            "command": self.command,
            "status": self.status,
            "text": self.text,
            "warnings": self.warnings,
            "confidence": self.confidence,
            "metadata": self.metadata,
        }


@dataclass
class ParserBackendRun:
    backend_name: str
    backend_version: str
    command: str
    status: str
    source_count: int
    records: list[ParserBackendRecord]
    warnings: list[str] = field(default_factory=list)
    kb_trust_status: str = "raw_parse_output"
    error_code: str | None = None
    fallback_result: str | None = None
    repair_suggestion: str | None = None
    audit_trace: str | None = None

    def to_dict(self) -> dict:
        payload = {
            "parser_backend_version": "2.8.0-alpha.1",
            "backend_name": self.backend_name,
            "backend_version": self.backend_version,
            "command": self.command,
            "status": self.status,
            "source_count": self.source_count,
            "success_count": len([record for record in self.records if record.status == "success"]),
            "warning_count": len(self.warnings) + sum(len(record.warnings) for record in self.records),
            "kb_trust_status": self.kb_trust_status,
            "warnings": self.warnings,
            "records": [record.to_dict() for record in self.records],
        }
        if self.error_code is not None:
            payload["error_code"] = self.error_code
        if self.fallback_result is not None:
            payload["fallback_result"] = self.fallback_result
        if self.repair_suggestion is not None:
            payload["repair_suggestion"] = self.repair_suggestion
        if self.audit_trace is not None:
            payload["audit_trace"] = self.audit_trace
        return payload


class ParserBackend:
    name = "unknown"
    version = "unknown"
    description = ""
    supported_extensions: frozenset[str] = frozenset()

    def is_available(self) -> tuple[bool, str | None]:
        return True, None

    def parse_source(self, path: Path, command: str) -> ParserBackendRecord:
        raise NotImplementedError


def failure_metadata(
    backend_id: str,
    error_code: str,
    fallback_result: str = "builtin_available",
    repair_suggestion: str = "Install the optional backend dependency or rerun with backend=builtin.",
    audit_trace: str = "parser_backend_record",
) -> dict[str, str]:
    return {
        "error_code": error_code,
        "fallback_result": fallback_result,
        "repair_suggestion": repair_suggestion,
        "audit_trace": audit_trace,
        "backend_id": backend_id,
    }
