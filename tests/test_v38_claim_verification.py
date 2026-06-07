from heitang_kb_forge.verification.claim_extractor import extract_claims
from heitang_kb_forge.verification.reporter import run_claim_verification

from tests.v38_helpers import make_package, make_verification_source, read_json


def test_claim_extraction_from_kb_chunks_and_cards(tmp_path):
    package = make_package(tmp_path)

    claims = extract_claims(package)

    assert claims
    assert all(claim["claim_id"].startswith("claim_") for claim in claims)
    assert any("Pricing is 20 dollars" in claim["claim_text"] for claim in claims)


def test_local_verification_source_cross_check_and_trace(tmp_path):
    package = make_package(tmp_path)
    source = make_verification_source(tmp_path)
    output = tmp_path / "verify"

    result = run_claim_verification(package, output, [source])

    assert result["claim_count"] > 0
    assert (output / "verification_retrieval_trace.json").exists()
    assert read_json(output / "claim_verification_report.json")["claims"]
    assert read_json(output / "knowledge_accuracy_report.json")["external_absorption_map_file"] == "v38_external_absorption_map.json"
