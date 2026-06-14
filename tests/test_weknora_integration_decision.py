import json
from pathlib import Path

from heitang_kb_forge.auto_wiki import write_auto_wiki_outputs
from heitang_kb_forge.campaign_3_closure.review_handoff import _external_project_rows


def _project() -> dict:
    return next(row for row in _external_project_rows() if row["project_name"] == "WeKnora")


def _write_package(package: Path) -> None:
    package.mkdir(parents=True)
    (package / "manifest.json").write_text(
        json.dumps({"package_id": "pkg_auto_wiki", "source_count": 1, "chunk_count": 1}),
        encoding="utf-8",
    )
    (package / "chunks.jsonl").write_text(
        json.dumps(
            {
                "chunk_id": "chunk_a",
                "title": "Auto Wiki",
                "text": "Auto wiki preserves graph and RAG trace.",
                "source_path": "source.md",
            }
        )
        + "\n",
        encoding="utf-8",
    )


def test_weknora_decision_is_local_capability_fusion_not_vendor_runtime(tmp_path):
    package = tmp_path / "package"
    output = tmp_path / "auto_wiki"
    _write_package(package)

    result = write_auto_wiki_outputs(package, output)
    project = _project()

    assert result["status"] == "passed"
    report = result["weknora_capability_fusion_report"]
    assert report["integration_mode"] == "capability_fusion"
    assert report["vendor_runtime_integrated"] is False
    assert report["external_code_copied"] is False
    assert report["source_trace_preserved"] is True
    assert project["integration_status"] == "real_integration"
    assert project["implementation_mode"] == "local_capability_fusion"
    assert project["runtime_dependency_added"] is False


def test_weknora_public_project_row_preserves_boundary():
    project = _project()

    assert project["capability_domain"] == "Auto Wiki / local KG synthesis"
    assert "no WeKnora runtime" in project["current_boundary"]
    assert project["future_target"] == "Post-4.0 knowledge graph planning"


def test_weknora_non_downgrade_public_fields_are_present():
    project = _project()

    assert project["project_name"] == "WeKnora"
    assert project["tests_added"]
    assert project["evidence_path"]
