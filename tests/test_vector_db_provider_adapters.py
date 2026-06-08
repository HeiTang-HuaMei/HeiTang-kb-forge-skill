from heitang_kb_forge.pre_v4_p0.vector_db import (
    ChromaAdapter,
    MilvusAdapter,
    PineconeAdapter,
    QdrantAdapter,
    run_contract,
)


def test_chroma_adapter_contract_is_implemented_without_live_service():
    report = run_contract("chroma")

    assert isinstance(ChromaAdapter().readiness(), dict)
    assert report["status"] == "implemented_offline_contract_tested"
    assert report["metadata_filter_pass"] is True
    assert report["stale_before_delete"]["status"] == "fresh"
    assert report["stale_after_delete"]["status"] == "stale"


def test_qdrant_adapter_contract_is_implemented_without_live_service():
    report = run_contract("qdrant")

    assert isinstance(QdrantAdapter().readiness(), dict)
    assert report["status"] == "implemented_offline_contract_tested"
    assert report["supports_delete_update_by_source_or_package"] is True


def test_milvus_adapter_contract_is_implemented_without_live_service():
    report = run_contract("milvus")

    assert isinstance(MilvusAdapter().readiness(), dict)
    assert report["status"] == "implemented_offline_contract_tested"
    assert report["supports_metadata_filter"] is True


def test_pinecone_adapter_contract_is_implemented_without_live_service():
    report = run_contract("pinecone")

    assert isinstance(PineconeAdapter().readiness(), dict)
    assert report["status"] == "implemented_offline_contract_tested"
    assert report["credential_redaction"] == "env_names_only_no_values"
