from heitang_kb_forge.llm.evidence_validator import validate_evidence_with_llm
from heitang_kb_forge.llm.provider import ProviderSettings


def test_llm_evidence_validator_uses_mock_provider():
    result = validate_evidence_with_llm("HeiTang evidence", "HeiTang evidence", ProviderSettings())

    assert result.supported is True
    assert result.status == "success"
