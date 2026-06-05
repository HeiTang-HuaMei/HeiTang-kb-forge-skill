from heitang_kb_forge.cli import _build_package, V21Options


def test_llm_quality_assist_uses_mock_fallback_without_network(tmp_path):
    input_dir = tmp_path / "input"
    output = tmp_path / "output"
    input_dir.mkdir()
    (input_dir / "001_note.md").write_text("short", encoding="utf-8")

    _build_package(input_dir, output, "education", "teaching", 1200, 120, v21_options=V21Options(llm_quality_assist=True, review_workflow=True))

    report = (output / "llm_quality_assist_report.md").read_text(encoding="utf-8")
    assert "Provider: mock/fallback" in report
    assert (output / "llm_review_suggestions.jsonl").exists()
