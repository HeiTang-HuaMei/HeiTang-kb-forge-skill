from heitang_kb_forge.llm.provider import ProviderSettings, get_provider
from heitang_kb_forge.schemas.evidence_gate_schema import LLMBoundaryJudgment


def judge_boundary_with_llm(query: str, evidence_text: str, settings: ProviderSettings) -> LLMBoundaryJudgment:
    provider = get_provider(settings)
    response = provider.generate_json(f"Boundary query:\n{query}\nEvidence:\n{evidence_text}", "boundary")
    payload = response.payload
    return LLMBoundaryJudgment(
        provider=response.provider_name,
        model=response.model_name,
        status="success",
        boundary=str(payload.get("boundary", "unclear")),
        reason=str(payload.get("reason", "")),
    )
