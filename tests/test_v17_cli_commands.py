import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_v17_cli_commands_generate_expected_outputs(tmp_path):
    input_dir = tmp_path / "input"
    package = tmp_path / "package"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("HeiTang CLI evidence package", encoding="utf-8")
    runner = CliRunner()

    build = runner.invoke(app, ["build", "--input", str(input_dir), "--output", str(package), "--governance", "--retrieval-index"])
    assert build.exit_code == 0, build.output
    assert (package / "governance_report.md").exists()
    assert (package / "retrieval_index.jsonl").exists()

    governance_output = tmp_path / "governance"
    govern = runner.invoke(app, ["govern", "--package", str(package), "--output", str(governance_output)])
    assert govern.exit_code == 0, govern.output
    assert (governance_output / "package_diff.json").exists()

    retrieval_output = tmp_path / "retrieval"
    retrieval = runner.invoke(app, ["build-retrieval-index", "--package", str(package), "--output", str(retrieval_output)])
    assert retrieval.exit_code == 0, retrieval.output
    assert (retrieval_output / "retrieval_manifest.json").exists()

    gate_output = tmp_path / "gate"
    gate = runner.invoke(app, ["evidence-gate", "--package", str(package), "--query", "HeiTang evidence", "--output", str(gate_output)])
    assert gate.exit_code == 0, gate.output
    assert json.loads((gate_output / "evidence_gate_result.json").read_text(encoding="utf-8"))["decision"] == "allow"

    gate_llm = tmp_path / "gate_llm"
    llm = runner.invoke(
        app,
        [
            "evidence-gate",
            "--package",
            str(package),
            "--query",
            "HeiTang evidence",
            "--output",
            str(gate_llm),
            "--llm",
            "--llm-provider",
            "mock",
            "--llm-evidence-validation",
            "--llm-boundary-check",
            "--llm-hallucination-check",
        ],
    )
    assert llm.exit_code == 0, llm.output
    assert (gate_llm / "llm_evidence_validation.json").exists()
