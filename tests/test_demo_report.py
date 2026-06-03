from pathlib import Path

from heitang_kb_forge.eval.demo import make_demo_report


def test_demo_report_marks_basic_package_without_rag_agent_as_warning():
    result = make_demo_report(
        package_path=Path("output"),
        domain="education",
        mode="teaching",
        source_count=1,
        chunks=[{"text": "Chunk text", "source_path": "input.md"}],
        cards=[{"title": "Title", "summary": "Summary"}],
        qa_pairs=[{"question": "Question?", "answer": "Answer"}],
        glossary=[{"term": "Term"}],
        quality_report={"quality_score": 80, "quality_level": "good"},
        rag_export_enabled=False,
        agent_template_enabled=False,
        eval_cases=[],
    )

    assert result.demo_manifest.final_status == "warning"
    assert "RAG export is not enabled" in result.demo_manifest.warnings
    assert "Agent Template is not enabled" in result.demo_manifest.warnings
    assert "No eval cases generated" in result.demo_manifest.warnings


def test_demo_report_marks_zero_chunks_as_fail():
    result = make_demo_report(
        package_path=Path("output"),
        domain="education",
        mode="teaching",
        source_count=1,
        chunks=[],
        cards=[{"title": "Title", "summary": "Summary"}],
        qa_pairs=[{"question": "Question?", "answer": "Answer"}],
        glossary=[{"term": "Term"}],
        quality_report={"quality_score": 80, "quality_level": "good"},
        rag_export_enabled=True,
        agent_template_enabled=True,
        eval_cases=[{"required_citation": "input.md#chunk", "source_path": "input.md", "chunk_id": "chunk-1"}],
    )

    assert result.demo_manifest.final_status == "fail"
    assert "chunk_count is 0" in result.demo_manifest.warnings


def test_demo_report_eval_summary_tracks_eval_case_coverage():
    result = make_demo_report(
        package_path=Path("output"),
        domain="education",
        mode="teaching",
        source_count=1,
        chunks=[{"text": "Chunk text", "source_path": "input.md"}],
        cards=[{"title": "Title", "summary": "Summary"}],
        qa_pairs=[{"question": "Question?", "answer": "Answer"}],
        glossary=[{"term": "Term"}],
        quality_report={"quality_score": 90, "quality_level": "excellent"},
        rag_export_enabled=True,
        agent_template_enabled=True,
        eval_cases=[
            {"required_citation": "input.md#chunk", "source_path": "input.md", "chunk_id": "chunk-1"},
            {"required_citation": "", "source_path": "input.md", "chunk_id": ""},
        ],
    )

    assert result.demo_manifest.final_status == "pass"
    assert result.eval_summary.eval_cases_count == 2
    assert result.eval_summary.required_citation_count == 1
    assert result.eval_summary.source_path_coverage == 1.0
    assert result.eval_summary.chunk_id_coverage == 0.5
