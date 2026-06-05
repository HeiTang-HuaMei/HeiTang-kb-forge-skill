from heitang_kb_forge.llm.mock_provider import MockProvider


def test_mock_provider_returns_supported_payload():
    response = MockProvider().generate_json("supported evidence", "evidence_validation")

    assert response.payload["supported"] is True
    assert response.provider_name == "mock"
