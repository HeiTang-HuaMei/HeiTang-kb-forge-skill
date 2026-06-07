from heitang_kb_forge.retrieval.quality import multi_query_recall, run_retrieval_quality
from heitang_kb_forge.retrieval.index_builder import build_retrieval_index

from tests.v38_helpers import make_package, read_json


def test_multi_query_recall_uses_v37_query_variants_and_dedups(tmp_path):
    package = make_package(tmp_path)
    plan = read_json(package / "retrieval_plan.json")
    records = [record.model_dump(mode="json") for record in build_retrieval_index(package)]

    trace = multi_query_recall(records, plan, max_candidates=20)

    assert trace["variant_count"] >= len(plan["query_variants"])
    assert trace["candidate_count"] >= 2
    identities = [
        f"{item['source_path']}|{item['chunk_id']}|{item['retrieval_id']}"
        for item in trace["merged_candidates"]
    ]
    assert len(identities) == len(set(identities))
    assert trace["tests_require_real_llm_api_network"] is False


def test_run_retrieval_quality_writes_all_core_reports(tmp_path):
    package = make_package(tmp_path)
    output = tmp_path / "quality"

    report = run_retrieval_quality(package, output)

    assert report["v37_retrieval_plan_consumed"] is True
    assert report["external_absorption_map_file"] == "v38_external_absorption_map.json"
    assert read_json(output / "knowledge_accuracy_report.json")["external_absorption_map_file"] == "v38_external_absorption_map.json"
    for name in report["output_files"]:
        assert (output / name).exists()
