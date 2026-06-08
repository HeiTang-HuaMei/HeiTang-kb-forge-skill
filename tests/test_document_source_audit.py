from heitang_kb_forge.pre_v4_p0 import run_knowledge_governance_completion
from tests.p0_helpers import make_p0_package, read_json


def test_document_source_audit_records_owner_freshness_and_do_not_ingest(tmp_path):
    package = make_p0_package(tmp_path)
    output = tmp_path / "out"

    run_knowledge_governance_completion(package, output)
    report = read_json(output / "document_source_audit_report.json")

    assert report["status"] == "pass"
    assert report["documents"]
    first = report["documents"][0]
    assert first["document_owner"]
    assert first["maintenance_owner"]
    assert "source_freshness" in first
    assert first["do_not_ingest"] is False
