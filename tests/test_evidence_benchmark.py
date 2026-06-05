import json

from heitang_kb_forge.cli import _build_package, V21Options


def test_evidence_benchmark_outputs_are_generated(tmp_path):
    input_dir = tmp_path / "input"
    output = tmp_path / "output"
    input_dir.mkdir()
    (input_dir / "001_note.md").write_text("KB Forge evidence benchmark fixture.", encoding="utf-8")

    _build_package(input_dir, output, "education", "teaching", 1200, 120, v21_options=V21Options(evidence_benchmark=True))

    result = json.loads((output / "evidence_benchmark_result.json").read_text(encoding="utf-8"))
    assert result["status"] == "pass"
    assert (output / "evidence_benchmark_report.md").exists()
