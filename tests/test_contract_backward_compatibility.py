from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_contract_v2_is_opt_in_for_default_build(tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("Backward compatibility fixture.", encoding="utf-8")

    result = CliRunner().invoke(app, ["build", "--input", str(input_dir), "--output", str(output_dir)])

    assert result.exit_code == 0, result.output
    assert not (output_dir / "evidence_map.json").exists()
    assert not (output_dir / "contract_check_result.json").exists()
