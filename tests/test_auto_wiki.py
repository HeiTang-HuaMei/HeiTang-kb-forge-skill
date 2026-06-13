import json
from pathlib import Path

from typer.testing import CliRunner

from heitang_kb_forge.auto_wiki import write_auto_wiki_outputs
from heitang_kb_forge.cli import app


def _json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8-sig"))


def _jsonl(path: Path) -> list[dict]:
    return [json.loads(line) for line in path.read_text(encoding="utf-8-sig").splitlines() if line.strip()]


def _write_package(package: Path) -> None:
    package.mkdir(parents=True)
    (package / "manifest.json").write_text(
        json.dumps({"package_id": "pkg_auto_wiki", "source_count": 1, "chunk_count": 2}),
        encoding="utf-8",
    )
    chunks = [
        {
            "chunk_id": "chunk_a",
            "title": "Evidence workflow",
            "text": "Evidence workflow keeps source trace and retrieval citation.",
            "source_path": "source_a.md",
        },
        {
            "chunk_id": "chunk_b",
            "title": "RAG trace",
            "text": "RAG trace records selected chunks and source files.",
            "source_path": "source_b.md",
        },
    ]
    (package / "chunks.jsonl").write_text("\n".join(json.dumps(item) for item in chunks) + "\n", encoding="utf-8")
    (package / "cards.jsonl").write_text(
        "\n".join(
            [
                json.dumps(
                    {
                        "card_id": "card_a",
                        "chunk_id": "chunk_a",
                        "title": "Evidence workflow",
                        "summary": "Evidence workflow keeps source trace.",
                        "source_path": "source_a.md",
                        "citation": "source_a.md#chunk=chunk_a",
                        "tags": ["evidence", "workflow"],
                    }
                ),
                json.dumps(
                    {
                        "card_id": "card_b",
                        "chunk_id": "chunk_b",
                        "title": "RAG trace",
                        "summary": "RAG trace records selected chunks.",
                        "source_path": "source_b.md",
                        "citation": "source_b.md#chunk=chunk_b",
                        "tags": ["rag", "trace"],
                    }
                ),
            ]
        )
        + "\n",
        encoding="utf-8",
    )
    (package / "glossary.jsonl").write_text(
        json.dumps(
            {
                "term": "Source Trace",
                "definition": "Trace back to source files.",
                "source_path": "source_a.md",
                "chunk_id": "chunk_a",
                "citation": "source_a.md#chunk=chunk_a",
            }
        )
        + "\n",
        encoding="utf-8",
    )
    (package / "evidence_map.json").write_text(
        json.dumps(
            {
                "chunks": {
                    "chunk_a": {"source_file": "source_a.md", "evidence_id": "ev_a"},
                    "chunk_b": {"source_file": "source_b.md", "evidence_id": "ev_b"},
                }
            }
        ),
        encoding="utf-8",
    )
    (package / "retrieval_trace.json").write_text(
        json.dumps({"query": "source trace", "route": "summary", "selected_ids": ["chunk_a", "chunk_b"]}),
        encoding="utf-8",
    )


def test_auto_wiki_outputs_pages_graph_rag_and_visual_trace(tmp_path):
    package = tmp_path / "package"
    output = tmp_path / "auto_wiki"
    _write_package(package)

    result = write_auto_wiki_outputs(package, output, query="source trace")

    assert result["status"] == "passed"
    report = _json(output / "weknora_capability_fusion_report.json")
    graph = _json(output / "knowledge_graph_snapshot.json")
    rag = _json(output / "rag_trace_summary.json")
    visual = _json(output / "visual_trace_manifest.json")
    pages = _jsonl(output / "auto_wiki_pages.jsonl")

    assert report["integration_mode"] == "capability_fusion"
    assert report["vendor_runtime_integrated"] is False
    assert report["external_code_copied"] is False
    assert report["llm_required"] is False
    assert report["network_required"] is False
    assert report["external_runtime_required"] is False
    assert len(pages) == 2
    assert graph["entity_count"] >= 2
    assert rag["source_trace_preserved"] is True
    assert visual["visual_trace_available"] is True
    assert (output / "weknora_capability_fusion_report.md").exists()


def test_build_auto_wiki_cli_reads_knowledge_package(tmp_path):
    package = tmp_path / "package"
    output = tmp_path / "auto_wiki"
    _write_package(package)

    result = CliRunner().invoke(
        app,
        [
            "build-auto-wiki",
            "--knowledge-package",
            str(package),
            "--output",
            str(output),
            "--query",
            "source trace",
        ],
    )

    assert result.exit_code == 0, result.output
    report = _json(output / "weknora_capability_fusion_report.json")
    assert report["status"] == "passed"
    assert report["auto_wiki_page_count"] == 2
    assert report["source_trace_preserved"] is True
    assert report["not_goal_complete"] is True
