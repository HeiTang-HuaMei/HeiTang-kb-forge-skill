from heitang_kb_forge.pre_v4_p0.vector_db import QdrantAdapter, run_contract


def test_qdrant_adapter_supports_remote_contract_operations_without_secret_output():
    report = run_contract("qdrant")
    readiness = QdrantAdapter().readiness()

    assert report["status"] == "implemented_offline_contract_tested"
    assert report["supports_metadata_filter"] is True
    assert report["supports_delete_update_by_source_or_package"] is True
    assert report["credential_redaction"] == "env_names_only_no_values"
    assert readiness["provider"] == "qdrant"
    assert readiness["secret_fields_redacted"] is True
