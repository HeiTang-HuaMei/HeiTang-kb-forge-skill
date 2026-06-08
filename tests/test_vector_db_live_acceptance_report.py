from heitang_kb_forge.pre_v4_p0 import run_vector_db_completion

from tests.p0_helpers import read_json


def test_vector_db_live_acceptance_report_is_truthful_without_provider_env(tmp_path, monkeypatch):
    for name in [
        "HEITANG_VECTOR_CHROMA_PATH",
        "HEITANG_VECTOR_QDRANT_URL",
        "HEITANG_VECTOR_QDRANT_API_KEY",
        "HEITANG_VECTOR_MILVUS_URI",
        "HEITANG_VECTOR_MILVUS_TOKEN",
        "HEITANG_VECTOR_PINECONE_API_KEY",
        "HEITANG_VECTOR_PINECONE_INDEX",
        "HEITANG_VECTOR_PINECONE_HOST",
        "HEITANG_VECTOR_PINECONE_ENVIRONMENT",
    ]:
        monkeypatch.delenv(name, raising=False)

    report = run_vector_db_completion(tmp_path)
    live = read_json(tmp_path / "vector_db_live_acceptance_report.json")

    assert report["status"] == "pass"
    assert live["status"] == "needs_live_acceptance"
    assert all(item["live_verified"] is False for item in live["providers"])
    assert live["tests_require_real_llm_api_network"] is False
