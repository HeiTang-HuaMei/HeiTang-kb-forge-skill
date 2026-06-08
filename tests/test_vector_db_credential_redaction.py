from heitang_kb_forge.pre_v4_p0 import run_vector_db_completion

from tests.p0_helpers import read_json


def test_vector_db_reports_never_write_secret_values(tmp_path, monkeypatch):
    monkeypatch.setenv("HEITANG_VECTOR_QDRANT_API_KEY", "secret-vector-key")
    monkeypatch.setenv("HEITANG_VECTOR_MILVUS_TOKEN", "secret-milvus-token")
    monkeypatch.setenv("HEITANG_VECTOR_PINECONE_API_KEY", "secret-pinecone-key")

    run_vector_db_completion(tmp_path)

    assert read_json(tmp_path / "vector_db_credential_redaction_report.json")["secret_values_written"] is False
    serialized = "\n".join(path.read_text(encoding="utf-8") for path in tmp_path.glob("vector_db*.json"))
    assert "secret-vector-key" not in serialized
    assert "secret-milvus-token" not in serialized
    assert "secret-pinecone-key" not in serialized
