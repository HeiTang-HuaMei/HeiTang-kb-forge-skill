from heitang_kb_forge.llm.boundary_judge import judge_boundary_with_llm
from heitang_kb_forge.llm.provider import ProviderSettings


def test_llm_boundary_judge_returns_inside_for_supported_prompt():
    result = judge_boundary_with_llm("HeiTang evidence", "HeiTang evidence", ProviderSettings())

    assert result.boundary == "inside"
