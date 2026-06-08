from heitang_kb_forge.pre_v4_p0.vector_db import ChromaAdapter, run_contract


def test_chroma_adapter_supports_local_contract_operations():
    report = run_contract("chroma")
    readiness = ChromaAdapter().readiness()

    assert report["status"] == "implemented_offline_contract_tested"
    assert report["supports_create_open_collection"] is True
    assert report["supports_upsert"] is True
    assert report["supports_query"] is True
    assert report["metadata_filter_pass"] is True
    assert report["stale_after_delete"]["status"] == "stale"
    assert readiness["provider"] == "chroma"
    assert readiness["status"] in {"implemented_needs_live_acceptance", "implemented_local_live_verified"}
