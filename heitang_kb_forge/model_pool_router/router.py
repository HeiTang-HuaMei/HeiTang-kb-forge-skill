from __future__ import annotations

from pathlib import Path

from heitang_kb_forge.exporters.jsonl_exporter import write_json
from heitang_kb_forge.schemas.model_pool_router_schema import (
    ModelPoolCandidate,
    ModelPoolRoutingReport,
    ModelPoolRoutingRequest,
)


MODEL_POOL_ROUTER_BOUNDARY = {
    "provider_api_call": "not_required",
    "default_network": "forbidden",
    "secrets": "not_required",
    "ui_change": "not_required",
    "runtime_change": "not_required",
    "redis_service_packaging": "forbidden",
    "vector_service_packaging": "forbidden",
}
READY_HEALTH_STATUSES = {"ready", "pass", "healthy", "mock_ready"}


def route_model_pool(
    candidates: list[ModelPoolCandidate | dict],
    request: ModelPoolRoutingRequest | dict,
    output: Path | None = None,
) -> ModelPoolRoutingReport:
    parsed_candidates = [
        candidate if isinstance(candidate, ModelPoolCandidate) else ModelPoolCandidate.model_validate(candidate)
        for candidate in candidates
    ]
    parsed_request = request if isinstance(request, ModelPoolRoutingRequest) else ModelPoolRoutingRequest.model_validate(request)
    failed_checks: list[str] = []
    trace: list[dict] = []
    eligible: list[ModelPoolCandidate] = []
    for candidate in parsed_candidates:
        failures = _candidate_failures(candidate, parsed_request)
        trace.append(
            {
                "model_id": candidate.model_id,
                "provider_id": candidate.provider_id,
                "status": "eligible" if not failures else "skipped",
                "reasons": failures,
            }
        )
        if failures:
            continue
        eligible.append(candidate)

    if not parsed_candidates:
        failed_checks.append("empty_model_pool")
    if parsed_request.preferred_provider_id and not any(
        item.provider_id == parsed_request.preferred_provider_id for item in parsed_candidates
    ):
        failed_checks.append("preferred_provider_not_found")
    if parsed_request.required_capabilities and not any(
        _has_capabilities(item, parsed_request.required_capabilities) for item in parsed_candidates
    ):
        failed_checks.append("required_capability_unavailable")
    if not eligible:
        failed_checks.append("no_eligible_model")

    selected = _select(eligible)
    report = ModelPoolRoutingReport(
        status="passed" if selected and not failed_checks else "failed",
        selected_model_id=selected.model_id if selected else None,
        selected_provider_id=selected.provider_id if selected else None,
        selected_model_name=selected.model_name if selected else None,
        candidate_count=len(parsed_candidates),
        eligible_count=len(eligible),
        failed_checks=failed_checks,
        routing_trace=trace,
        output_files=["model_pool_router_basic_report.json"],
        boundary=MODEL_POOL_ROUTER_BOUNDARY,
    )
    if output:
        output.mkdir(parents=True, exist_ok=True)
        write_json(output / "model_pool_router_basic_report.json", report)
    return report


def _candidate_failures(candidate: ModelPoolCandidate, request: ModelPoolRoutingRequest) -> list[str]:
    failures: list[str] = []
    if not candidate.enabled:
        failures.append("disabled")
    if candidate.health_status not in READY_HEALTH_STATUSES:
        failures.append("health_not_ready")
    if candidate.network_required and not request.allow_network:
        failures.append("network_not_allowed")
    if request.preferred_provider_id and candidate.provider_id != request.preferred_provider_id:
        failures.append("not_preferred_provider")
    if not _has_capabilities(candidate, request.required_capabilities):
        failures.append("missing_required_capability")
    return failures


def _has_capabilities(candidate: ModelPoolCandidate, required: list[str]) -> bool:
    return set(required).issubset(set(candidate.capabilities))


def _select(candidates: list[ModelPoolCandidate]) -> ModelPoolCandidate | None:
    if not candidates:
        return None
    return sorted(candidates, key=lambda item: (item.priority, item.provider_id, item.model_id))[0]
