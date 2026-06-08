from heitang_kb_forge.pre_v4_p0.vector_db import PineconeAdapter, run_contract


def test_pinecone_adapter_supports_contract_update_delete_and_redaction():
    report = run_contract("pinecone")
    readiness = PineconeAdapter().readiness()

    assert report["status"] == "implemented_offline_contract_tested"
    assert report["update"]["updated"] >= 1
    assert report["delete"]["deleted"] >= 1
    assert report["credential_redaction"] == "env_names_only_no_values"
    assert readiness["provider"] == "pinecone"
    assert "HEITANG_VECTOR_PINECONE_API_KEY" in readiness["required_env"]
