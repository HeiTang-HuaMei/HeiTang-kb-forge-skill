from heitang_kb_forge.llm.provider import ProviderSettings, get_provider
from heitang_kb_forge.schemas.evidence_gate_schema import LLMHallucinationCheck


def check_hallucination_with_llm(query: str, evidence_text: str, settings: ProviderSettings) -> LLMHallucinationCheck:
    provider = get_provider(settings)
    response = provider.generate_json(f"Hallucination check:\n{query}\nEvidence:\n{evidence_text}", "hallucination")
    payload = response.payload
    return LLMHallucinationCheck(
        provider=response.provider_name,
        model=response.model_name,
        status="success",
        risk_level=str(payload.get("risk_level", "unknown")),
        reason=str(payload.get("reason", "")),
    )
