import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_check_contract_cli_writes_outputs(tmp_path):
    input_dir = tmp_path / "input"
    package = tmp_path / "package"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("Contract CLI fixture.", encoding="utf-8")
    build = CliRunner().invoke(app, ["build", "--input", str(input_dir), "--output", str(package), "--contract-version", "v2"])
    assert build.exit_code == 0, build.output

    result = CliRunner().invoke(app, ["check-contract", "--package", str(package), "--contract-version", "v2"])

    assert result.exit_code == 0, result.output
    payload = json.loads((package / "contract_check_result.json").read_text(encoding="utf-8"))
    assert payload["status"] == "pass"
    assert (package / "contract_check_report.md").exists()


def test_build_check_contract_detects_multimodal_outputs(tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("Contract build fixture.", encoding="utf-8")
    (input_dir / "mindmap.png").write_bytes(b"fake image")

    result = CliRunner().invoke(
        app,
        ["build", "--input", str(input_dir), "--output", str(output_dir), "--multimodal", "--contract-version", "v2", "--check-contract"],
    )

    assert result.exit_code == 0, result.output
    payload = json.loads((output_dir / "contract_check_result.json").read_text(encoding="utf-8"))
    assert payload["status"] == "pass"
    assert (output_dir / "multimodal_assets.jsonl").exists()
