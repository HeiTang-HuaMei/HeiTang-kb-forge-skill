import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_default_build_does_not_emit_multimodal_outputs(tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("Default build fixture.", encoding="utf-8")

    result = CliRunner().invoke(app, ["build", "--input", str(input_dir), "--output", str(output_dir)])

    assert result.exit_code == 0, result.output
    assert not (output_dir / "multimodal_assets.jsonl").exists()
    assert not (output_dir / "multimodal_evidence_map.json").exists()


def test_build_multimodal_emits_assets_evidence_and_report(tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("Multimodal build fixture.", encoding="utf-8")
    (input_dir / "diagram_image.webp").write_bytes(b"fake image")

    result = CliRunner().invoke(app, ["build", "--input", str(input_dir), "--output", str(output_dir), "--multimodal"])

    assert result.exit_code == 0, result.output
    assert (output_dir / "multimodal_assets.jsonl").exists()
    assert (output_dir / "multimodal_evidence_map.json").exists()
    assert (output_dir / "multimodal_report.md").exists()
    assets = [json.loads(line) for line in (output_dir / "multimodal_assets.jsonl").read_text(encoding="utf-8").splitlines()]
    assert assets
    assert assets[0]["review_required"] is True
    assert assets[0]["extraction_method"] == "fallback"
