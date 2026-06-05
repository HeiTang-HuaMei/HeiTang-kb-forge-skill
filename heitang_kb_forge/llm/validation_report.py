from heitang_kb_forge.schemas.evidence_gate_schema import (
    LLMBoundaryJudgment,
    LLMEvidenceValidation,
    LLMHallucinationCheck,
)


def render_llm_evidence_report(result: LLMEvidenceValidation) -> str:
    return f"""# LLM Evidence Validation Report

- Provider: {result.provider}
- Model: {result.model}
- Supported: {result.supported}
- Confidence: {result.confidence}
- Reason: {result.reason}
"""


def summarize_llm_checks(
    evidence: LLMEvidenceValidation | None,
    boundary: LLMBoundaryJudgment | None,
    hallucination: LLMHallucinationCheck | None,
) -> dict:
    return {
        "evidence_supported": evidence.supported if evidence else None,
        "boundary": boundary.boundary if boundary else None,
        "hallucination_risk": hallucination.risk_level if hallucination else None,
    }
