from heitang_kb_forge.llm.provider import ProviderSettings, get_provider
from heitang_kb_forge.schemas.evidence_gate_schema import LLMEvidenceValidation


def validate_evidence_with_llm(query: str, evidence_text: str, settings: ProviderSettings) -> LLMEvidenceValidation:
    provider = get_provider(settings)
    response = provider.generate_json(f"Query:\n{query}\nEvidence:\n{evidence_text}", "evidence_validation")
    payload = response.payload
    return LLMEvidenceValidation(
        provider=response.provider_name,
        model=response.model_name,
        status="success",
        supported=bool(payload.get("supported")),
        confidence=float(payload.get("confidence", 0.0)),
        reason=str(payload.get("reason", "")),
    )
