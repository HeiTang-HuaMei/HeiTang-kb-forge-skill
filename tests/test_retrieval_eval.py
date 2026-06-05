import json

from heitang_kb_forge.cli import _build_package, V21Options


def test_retrieval_eval_outputs_are_generated(tmp_path):
    input_dir = tmp_path / "input"
    output = tmp_path / "output"
    input_dir.mkdir()
    (input_dir / "001_note.md").write_text("KB Forge retrieval eval fixture.", encoding="utf-8")

    _build_package(input_dir, output, "education", "teaching", 1200, 120, v21_options=V21Options(retrieval_eval=True))

    result = json.loads((output / "retrieval_eval_result.json").read_text(encoding="utf-8"))
    assert result["case_count"] >= 1
    assert (output / "retrieval_eval_cases.jsonl").exists()
