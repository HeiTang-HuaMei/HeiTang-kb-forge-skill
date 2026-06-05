from heitang_kb_forge.llm.hallucination_checker import check_hallucination_with_llm
from heitang_kb_forge.llm.provider import ProviderSettings


def test_llm_hallucination_checker_returns_low_risk_for_supported_prompt():
    result = check_hallucination_with_llm("HeiTang evidence", "HeiTang evidence", ProviderSettings())

    assert result.risk_level == "low"
