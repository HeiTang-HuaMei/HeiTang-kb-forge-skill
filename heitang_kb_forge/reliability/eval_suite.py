from heitang_kb_forge.schemas.reliability_eval_schema import (
    ReliabilityEvalDimension,
    ReliabilityEvalInput,
    ReliabilityEvalReport,
)


def run_reliability_eval(payload: ReliabilityEvalInput | dict) -> ReliabilityEvalReport:
    data = payload if isinstance(payload, ReliabilityEvalInput) else ReliabilityEvalInput.model_validate(payload)
    dimensions = [
        _dimension(
            "evidence_graph",
            data.evidence_graph_status == "evidence_graph_basic_completed_needs_owner_review"
            and data.evidence_graph_entity_count > 0,
            f"status={data.evidence_graph_status}; entity_count={data.evidence_graph_entity_count}",
        ),
        _dimension(
            "gap_analysis",
            data.gap_status == "gap_analysis_completed_needs_owner_review" and data.gap_count >= 0,
            f"status={data.gap_status}; gap_count={data.gap_count}",
        ),
        _dimension(
            "citation_verification",
            data.citation_status == "citation_verification_completed_needs_owner_review"
            and data.citation_coverage >= data.minimum_citation_coverage,
            f"status={data.citation_status}; coverage={data.citation_coverage}; threshold={data.minimum_citation_coverage}",
        ),
    ]
    blockers = [dimension.dimension for dimension in dimensions if dimension.status == "fail"]
    warnings = [dimension.dimension for dimension in dimensions if dimension.status == "partial"]
    overall_score = round(sum(dimension.score for dimension in dimensions) / len(dimensions))
    status = "pass" if not blockers and not warnings else ("needs_attention" if not blockers else "fail")
    return ReliabilityEvalReport(
        status=status,
        overall_score=overall_score,
        available_for_next_gate=status == "pass",
        dimensions=dimensions,
        blockers=blockers,
        warnings=warnings,
        summary=f"{status} with overall_score={overall_score}.",
    )


def _dimension(dimension: str, passed: bool, reason: str) -> ReliabilityEvalDimension:
    return ReliabilityEvalDimension(
        dimension=dimension,
        status="pass" if passed else "fail",
        score=100 if passed else 0,
        reason=reason,
    )
