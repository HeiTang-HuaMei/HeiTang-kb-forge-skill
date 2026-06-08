from heitang_kb_forge.pre_v4_p0 import run_rag_quality_metrics_completion
from tests.p0_helpers import make_p0_package, read_json


def test_semantic_chunking_quality_compares_fixed_chunking_and_overlap(tmp_path):
    package = make_p0_package(tmp_path)
    output = tmp_path / "out"

    run_rag_quality_metrics_completion(package, output)
    report = read_json(output / "semantic_chunking_quality_report.json")

    assert report["status"] == "pass"
    assert report["semantic_aware_chunking"] is True
    assert 0.10 <= report["overlap_ratio"] <= 0.20
    assert report["semantic_boundary_preservation"] > report["fixed_token_baseline"]["semantic_boundary_preservation"]
