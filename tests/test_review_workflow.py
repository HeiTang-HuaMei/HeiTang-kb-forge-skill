from heitang_kb_forge.cli import _build_package, V21Options


def test_review_workflow_outputs_are_generated(tmp_path):
    input_dir = tmp_path / "input"
    output = tmp_path / "output"
    input_dir.mkdir()
    (input_dir / "001_note.md").write_text("short", encoding="utf-8")

    _build_package(input_dir, output, "education", "teaching", 1200, 120, v21_options=V21Options(review_workflow=True))

    assert (output / "review_decisions.jsonl").exists()
    assert (output / "curated_chunks.jsonl").exists()
    assert (output / "curated_evidence_map.json").exists()
    assert (output / "review_workflow_report.md").exists()
