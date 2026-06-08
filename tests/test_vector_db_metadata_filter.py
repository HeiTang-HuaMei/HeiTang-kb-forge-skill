from heitang_kb_forge.pre_v4_p0.vector_db import VECTOR_PROVIDERS, run_contract


def test_all_vector_db_adapters_enforce_metadata_filter_contract():
    for provider in VECTOR_PROVIDERS:
        report = run_contract(provider)
        assert report["metadata_filter_pass"] is True
        assert report["metadata_filter_returned"] >= 1
