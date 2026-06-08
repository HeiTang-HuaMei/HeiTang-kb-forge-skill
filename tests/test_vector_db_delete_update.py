from heitang_kb_forge.pre_v4_p0.vector_db import VECTOR_PROVIDERS, run_contract


def test_all_vector_db_adapters_support_delete_update_contract():
    for provider in VECTOR_PROVIDERS:
        report = run_contract(provider)
        assert report["update"]["status"] == "pass"
        assert report["update"]["updated"] >= 1
        assert report["delete"]["status"] == "pass"
        assert report["delete"]["deleted"] >= 1
