from __future__ import annotations

from typing import Any, Literal

from pydantic import BaseModel, ConfigDict, Field


CapabilitySupport = Literal["supported", "partial", "unsupported", "unknown"]
DependencyStatus = Literal["bundled", "available", "missing", "unknown"]
RuntimeStatus = Literal["ready", "disabled", "skipped", "failed", "unknown"]
IntegrationDecision = Literal["real_integration", "reference_only", "needs_strengthening", "stop_integration"]
AdapterResultStatus = Literal["success", "partial", "skipped", "failed", "empty", "unsupported"]


class SourceTrace(BaseModel):
    model_config = ConfigDict(extra="forbid")

    source_path: str
    source_type: str = "unknown"
    page: int | None = None
    block_id: str | None = None
    command: str = ""


class AdapterError(BaseModel):
    model_config = ConfigDict(extra="forbid")

    code: str
    message: str
    retryable: bool = False
    fallback_reason: str | None = None
    fallback_result: str | None = None
    repair_suggestion: str | None = None


class AdapterCapability(BaseModel):
    model_config = ConfigDict(extra="forbid")

    schema_version: str = "document_backend.capability.v1"
    adapter_id: str
    adapter_name: str
    adapter_version: str
    adapter_type: str
    integration_decision: IntegrationDecision
    dependency_name: str | None = None
    optional_extra: str | None = None
    dependency_status: DependencyStatus
    runtime_status: RuntimeStatus
    supported_inputs: list[str] = Field(default_factory=list)
    validated_inputs: list[str] = Field(default_factory=list)
    supported_outputs: list[str] = Field(default_factory=list)
    ocr_support: CapabilitySupport = "unknown"
    layout_support: CapabilitySupport = "unknown"
    table_support: CapabilitySupport = "unknown"
    figure_support: CapabilitySupport = "unknown"
    formula_support: CapabilitySupport = "unknown"
    reading_order_support: CapabilitySupport = "unknown"
    confidence: float = Field(default=0.0, ge=0.0, le=1.0)
    warnings: list[str] = Field(default_factory=list)
    errors: list[AdapterError] = Field(default_factory=list)
    source_trace: list[SourceTrace] = Field(default_factory=list)
    fallback_reason: str | None = None
    fallback_result: str | None = None
    repair_suggestion: str | None = None


class AdapterResult(AdapterCapability):
    schema_version: str = "document_backend.result.v1"
    status: AdapterResultStatus


class AdapterSmokeReport(BaseModel):
    model_config = ConfigDict(extra="forbid")

    schema_version: str = "document_backend.smoke.v1"
    adapter: AdapterCapability
    status: Literal["pass", "warning", "skipped", "fail"]
    result: AdapterResult | None = None
    warnings: list[str] = Field(default_factory=list)
    errors: list[AdapterError] = Field(default_factory=list)
    repair_suggestion: str | None = None


class DocumentBlock(BaseModel):
    model_config = ConfigDict(extra="forbid")

    block_id: str
    block_type: str
    text: str = ""
    page: int | None = None
    bbox: list[float] | None = None
    reading_order: int | None = None
    confidence: float = Field(default=0.0, ge=0.0, le=1.0)
    source_trace: list[SourceTrace] = Field(default_factory=list)
    metadata: dict[str, Any] = Field(default_factory=dict)


class DocumentUnderstandingResult(BaseModel):
    model_config = ConfigDict(extra="forbid")

    schema_version: str = "document_understanding.result.v1"
    adapter: AdapterCapability
    status: AdapterResultStatus
    source_trace: list[SourceTrace] = Field(default_factory=list)
    blocks: list[DocumentBlock] = Field(default_factory=list)
    layout_map: dict[str, Any] = Field(default_factory=dict)
    table_map: dict[str, Any] = Field(default_factory=dict)
    figure_map: dict[str, Any] = Field(default_factory=dict)
    formula_map: dict[str, Any] = Field(default_factory=dict)
    confidence: float = Field(default=0.0, ge=0.0, le=1.0)
    warnings: list[str] = Field(default_factory=list)
    errors: list[AdapterError] = Field(default_factory=list)
    fallback_reason: str | None = None
    repair_suggestion: str | None = None


def infer_dependency_status(available: bool, reason: str | None, optional_dependency: str | None) -> DependencyStatus:
    if optional_dependency is None:
        return "bundled"
    if available:
        return "available"
    if reason and ("not installed" in reason.lower() or "dependency" in reason.lower()):
        return "missing"
    return "available"


def infer_runtime_status(
    available: bool,
    dependency_status: DependencyStatus,
    integration_decision: IntegrationDecision,
) -> RuntimeStatus:
    if dependency_status == "missing":
        return "skipped"
    if integration_decision != "real_integration":
        return "disabled"
    if available:
        return "ready"
    return "unknown"


def normalized_result_status(status: str) -> AdapterResultStatus:
    return {
        "success": "success",
        "warning": "partial",
        "unavailable": "skipped",
        "disabled": "skipped",
        "failed": "failed",
        "empty": "empty",
        "unsupported": "unsupported",
    }.get(status, "partial")


def make_adapter_result(
    capability: AdapterCapability,
    *,
    status: str,
    confidence: float,
    warnings: list[str],
    source_path: str,
    source_type: str,
    command: str,
    metadata: dict[str, Any],
) -> AdapterResult:
    result_status = normalized_result_status(status)
    error_code = metadata.get("error_code")
    if result_status == "skipped" and not error_code:
        error_code = (
            "optional_runtime_dependency_missing"
            if capability.dependency_status == "missing"
            else "adapter_not_integrated"
        )
    fallback_reason = capability.fallback_reason
    fallback_result = metadata.get("fallback_result") or capability.fallback_result
    repair_suggestion = metadata.get("repair_suggestion") or capability.repair_suggestion
    errors = []
    if error_code:
        errors.append(
            AdapterError(
                code=str(error_code),
                message=warnings[0] if warnings else str(error_code),
                retryable=error_code == "backend_runtime_exception",
                fallback_reason=str(fallback_reason) if fallback_reason else None,
                fallback_result=str(fallback_result) if fallback_result else None,
                repair_suggestion=str(repair_suggestion) if repair_suggestion else None,
            )
        )
    payload = capability.model_dump()
    payload.update(
        {
            "schema_version": "document_backend.result.v1",
            "status": result_status,
            "runtime_status": (
                "failed"
                if result_status == "failed"
                else "skipped"
                if result_status in {"skipped", "unsupported"}
                else capability.runtime_status
            ),
            "confidence": confidence,
            "warnings": warnings,
            "errors": errors,
            "source_trace": [
                SourceTrace(
                    source_path=source_path,
                    source_type=source_type,
                    page=_optional_int(metadata.get("page")),
                    block_id=str(metadata["block_id"]) if metadata.get("block_id") is not None else None,
                    command=command,
                )
            ],
            "fallback_reason": fallback_reason,
            "fallback_result": fallback_result,
            "repair_suggestion": repair_suggestion,
        }
    )
    return AdapterResult.model_validate(payload)


def _optional_int(value: Any) -> int | None:
    if value is None:
        return None
    try:
        return int(value)
    except (TypeError, ValueError):
        return None
