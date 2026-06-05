from heitang_kb_forge.evidence_gate.gate import run_evidence_gate
from tests.v17_helpers import read_json, write_sample_package


def test_evidence_gate_allows_supported_query(tmp_path):
    package = write_sample_package(tmp_path / "package")
    output = tmp_path / "gate"

    result = run_evidence_gate(package, output, "HeiTang evidence")

    assert result.decision == "allow"
    assert read_json(output / "evidence_gate_result.json")["decision"] == "allow"
