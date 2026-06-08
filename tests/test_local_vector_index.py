from heitang_kb_forge.pre_v4_p0 import run_rag_index_completion

from tests.p0_helpers import make_p0_package, read_json


def test_local_vector_index_report_proves_queryable_local_json_index(tmp_path):
    package = make_p0_package(tmp_path)
    output = tmp_path / "out"

    run_rag_index_completion(package, output)
    report = read_json(output / "local_vector_index_report.json")

    assert report["status"] == "pass"
    assert report["deterministic_vector_fallback"] is True
    assert report["real_embedding_optional_config_ready"] is True
