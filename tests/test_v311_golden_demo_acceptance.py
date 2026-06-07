import json

from heitang_kb_forge.golden_demo_acceptance import V311_GOLDEN_DEMO_OUTPUT_FILES, run_golden_demo_acceptance
from heitang_kb_forge.exporters.jsonl_exporter import write_json


def test_golden_demo_acceptance_writes_required_reports(tmp_path):
    package = _package(tmp_path)

    result = run_golden_demo_acceptance(package, tmp_path / "acceptance", sample_root=package, require_v37=False, require_v38=False, require_v39=False, require_v310=False)

    assert result["status"] == "pass"
    for name in V311_GOLDEN_DEMO_OUTPUT_FILES:
        assert (tmp_path / "acceptance" / name).exists(), name
    openability = _json(tmp_path / "acceptance" / "artifact_openability_report.json")
    assert openability["checked_artifact_count"] >= 6
    assert openability["status"] == "pass"
    assert result["tests_require_real_llm_api_network"] is False


def test_golden_demo_acceptance_detects_missing_required_prior_stage(tmp_path):
    package = _package(tmp_path)

    result = run_golden_demo_acceptance(package, tmp_path / "acceptance", sample_root=package, require_v37=True, require_v38=False, require_v39=False, require_v310=False)

    realism = _json(tmp_path / "acceptance" / "smoke_realism_report.json")
    assert result["status"] == "fail"
    assert realism["status"] == "fail"
    assert realism["checks"][0]["name"] == "v37_query_planning"


def _package(tmp_path):
    package = tmp_path / "package"
    package.mkdir()
    write_json(package / "manifest.json", {"package_id": "package", "domain": "general", "source_count": 1, "chunk_count": 1})
    write_json(package / "quality_report.json", {"status": "pass"})
    for name in ["chunks.jsonl", "cards.jsonl", "qa_pairs.jsonl", "glossary.jsonl"]:
        (package / name).write_text(json.dumps({"id": "x", "text": "Golden demo evidence."}) + "\n", encoding="utf-8")
    return package


def _json(path):
    return json.loads(path.read_text(encoding="utf-8"))
