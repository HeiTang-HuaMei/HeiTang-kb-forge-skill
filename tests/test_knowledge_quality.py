import json

from heitang_kb_forge.cli import _build_package
from heitang_kb_forge.cli import V21Options


def test_knowledge_quality_outputs_are_generated(tmp_path):
    input_dir = tmp_path / "input"
    output = tmp_path / "output"
    input_dir.mkdir()
    (input_dir / "001_note.md").write_text("KB Forge quality fixture with enough content for scoring.", encoding="utf-8")

    _build_package(input_dir, output, "education", "teaching", 1200, 120, v21_options=V21Options(quality_score=True, input_coverage=True, parser_hardening=True))

    report = json.loads((output / "knowledge_quality_report.json").read_text(encoding="utf-8"))
    assert report["overall_score"] >= 0
    assert (output / "source_inventory_enhanced.json").exists()
    assert (output / "parser_hardening_report.md").exists()
