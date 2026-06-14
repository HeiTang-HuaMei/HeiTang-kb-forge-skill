from heitang_kb_forge.campaign_3_closure.review_handoff import _external_project_rows
from heitang_kb_forge.knowledge_lifecycle import write_knowledge_lifecycle_outputs


def _project() -> dict:
    return next(row for row in _external_project_rows() if row["project_name"] == "LLM Wiki v2")


def test_llm_wiki_v2_decision_is_local_capability_fusion_not_vendor_runtime(tmp_path):
    package = tmp_path / "package"
    output = tmp_path / "lifecycle"
    package.mkdir()
    (package / "manifest.json").write_text('{"package_id":"pkg","source_count":1}', encoding="utf-8")
    (package / "chunks.jsonl").write_text(
        '{"chunk_id":"chunk_a","title":"Lifecycle","text":"Knowledge lifecycle keeps source trace.","source_path":"source.md"}\n',
        encoding="utf-8",
    )
    (package / "evidence_map.json").write_text(
        '{"chunks":{"chunk_a":{"source_file":"source.md","evidence_id":"ev_a"}}}',
        encoding="utf-8",
    )
    result = write_knowledge_lifecycle_outputs(package, output)
    report = result["knowledge_lifecycle_report"]

    assert report["status"] == "passed"
    assert report["source_trace_preserved"] is True

    project = _project()
    assert project["integration_status"] == "real_integration"
    assert project["implementation_mode"] == "local_capability_fusion"
    assert project["runtime_dependency_added"] is False
    assert "Campaign 3 Section 5.1" in project["campaign_section"]
    assert "no external runtime copied" in project["current_boundary"]


def test_llm_wiki_v2_public_summary_preserves_future_memory_boundary():
    project = _project()

    assert project["future_target"] == "Campaign 8 future memory store connectors"
    assert project["capability_domain"] == "Memory Separation / Knowledge Lifecycle"


def test_llm_wiki_v2_non_downgrade_public_fields_are_present():
    project = _project()

    assert project["project_name"] == "LLM Wiki v2"
    assert project["tests_added"]
    assert project["evidence_path"]
