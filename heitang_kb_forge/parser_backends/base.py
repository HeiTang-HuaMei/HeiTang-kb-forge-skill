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

    def to_dict(self) -> dict:
        return {
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


class ParserBackend:
    name = "unknown"
    version = "unknown"
    description = ""

    def is_available(self) -> tuple[bool, str | None]:
        return True, None

    def parse_source(self, path: Path, command: str) -> ParserBackendRecord:
        raise NotImplementedError

