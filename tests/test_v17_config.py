import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_v17_run_config_generates_governance_retrieval_and_evidence_outputs(tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    config_path = tmp_path / "kb_forge.v17.yaml"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("HeiTang governance retrieval evidence package", encoding="utf-8")
    config_path.write_text(
        f"""
task: build
input: {input_dir.as_posix()}
output: {output_dir.as_posix()}
domain: education
mode: teaching
governance:
  enabled: true
retrieval:
  enabled: true
  query: HeiTang evidence
evidence_gate:
  enabled: true
  query: HeiTang evidence
llm:
  enabled: true
  provider: mock
  model: mock-model
  evidence_validation: true
  boundary_check: true
  hallucination_check: true
  call_log: true
""",
        encoding="utf-8",
    )

    result = CliRunner().invoke(app, ["run", "--config", str(config_path)])

    assert result.exit_code == 0, result.output
    for file_name in [
        "governance_report.md",
        "retrieval_index.jsonl",
        "evidence_gate_result.json",
        "llm_evidence_validation.json",
        "llm_boundary_judgment.json",
        "llm_hallucination_check.json",
        "llm_call_log.jsonl",
    ]:
        assert (output_dir / file_name).exists()
    manifest = json.loads((output_dir / "manifest.json").read_text(encoding="utf-8"))
    assert manifest["governance_enabled"] is True
    assert manifest["retrieval_index_enabled"] is True
    assert manifest["evidence_gate_enabled"] is True
