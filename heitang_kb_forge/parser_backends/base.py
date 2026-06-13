from __future__ import annotations

from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

from heitang_kb_forge.parser_backends.document_backend_contract import (
    AdapterCapability,
    AdapterError,
    CapabilitySupport,
    IntegrationDecision,
    infer_dependency_status,
    infer_runtime_status,
    make_adapter_result,
)


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
    adapter_contract: dict[str, Any] = field(default_factory=dict)

    def to_dict(self) -> dict:
        payload = {
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
        if self.adapter_contract:
            capability = AdapterCapability.model_validate(self.adapter_contract)
            payload["adapter_result"] = make_adapter_result(
                capability,
                status=self.status,
                confidence=self.confidence,
                warnings=self.warnings,
                source_path=self.source_path,
                source_type=self.source_type,
                command=self.command,
                metadata=self.metadata,
            ).model_dump(mode="json")
        return payload


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
    adapter_contract: dict[str, Any] = field(default_factory=dict)

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
        if self.adapter_contract:
            payload["adapter_contract"] = self.adapter_contract
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
    adapter_type = "document_parser"
    optional_dependency: str | None = None
    optional_extra: str | None = None
    integration_decision: IntegrationDecision = "needs_strengthening"
    validated_extensions: frozenset[str] = frozenset()
    supported_outputs: tuple[str, ...] = ("normalized_text",)
    ocr_support: CapabilitySupport = "unsupported"
    layout_support: CapabilitySupport = "unsupported"
    table_support: CapabilitySupport = "unsupported"
    figure_support: CapabilitySupport = "unsupported"
    formula_support: CapabilitySupport = "unsupported"
    reading_order_support: CapabilitySupport = "unsupported"

    def is_available(self) -> tuple[bool, str | None]:
        return True, None

    def parse_source(self, path: Path, command: str) -> ParserBackendRecord:
        raise NotImplementedError

    def capability_contract(self) -> AdapterCapability:
        available, reason = self.is_available()
        dependency_status = infer_dependency_status(available, reason, self.optional_dependency)
        runtime_status = infer_runtime_status(available, dependency_status, self.integration_decision)
        warnings = [reason] if reason else []
        fallback_reason = reason if not available else None
        fallback_result = "builtin_available" if not available and self.name != "builtin" else None
        repair_suggestion = reason if not available else None
        errors = []
        if dependency_status == "missing":
            errors.append(
                AdapterError(
                    code="optional_runtime_dependency_missing",
                    message=reason or "Optional backend dependency is not installed.",
                    fallback_reason=fallback_reason,
                    fallback_result=fallback_result,
                    repair_suggestion=repair_suggestion,
                )
            )
        elif runtime_status == "disabled":
            errors.append(
                AdapterError(
                    code="adapter_not_integrated",
                    message=reason or "The adapter is registered but not enabled for live parsing.",
                    fallback_reason=fallback_reason,
                    fallback_result=fallback_result,
                    repair_suggestion=repair_suggestion,
                )
            )
        return AdapterCapability(
            adapter_id=self.name,
            adapter_name=self.name,
            adapter_version=self.version,
            adapter_type=self.adapter_type,
            integration_decision=self.integration_decision,
            dependency_name=self.optional_dependency,
            optional_extra=self.optional_extra,
            dependency_status=dependency_status,
            runtime_status=runtime_status,
            supported_inputs=sorted(self.supported_extensions),
            validated_inputs=sorted(self.validated_extensions),
            supported_outputs=list(self.supported_outputs),
            ocr_support=self.ocr_support,
            layout_support=self.layout_support,
            table_support=self.table_support,
            figure_support=self.figure_support,
            formula_support=self.formula_support,
            reading_order_support=self.reading_order_support,
            confidence=1.0 if available else 0.0,
            warnings=warnings,
            errors=errors,
            fallback_reason=fallback_reason,
            fallback_result=fallback_result,
            repair_suggestion=repair_suggestion,
        )


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


def skipped_record_from_contract(
    backend: ParserBackend,
    path: Path,
    command: str,
    contract: dict[str, Any],
    *,
    warning: str,
    error_code: str,
) -> ParserBackendRecord:
    return ParserBackendRecord(
        source_path=str(path).replace("\\", "/"),
        source_type=path.suffix.lower().lstrip(".") or "unknown",
        backend_name=backend.name,
        backend_version=backend.version,
        command=command,
        status="disabled" if error_code == "adapter_not_integrated" else "unavailable",
        warnings=[warning],
        confidence=0.0,
        metadata={
            "adapter": backend.name,
            "runtime_invoked": False,
            **failure_metadata(
                backend.name,
                error_code,
                fallback_result=contract.get("fallback_result") or "builtin_available",
                repair_suggestion=contract.get("repair_suggestion")
                or "Use a real integrated backend or rerun with backend=builtin.",
            ),
        },
        adapter_contract=contract,
    )
