from heitang_kb_forge.pre_v4_p0 import run_knowledge_governance_completion
from tests.p0_helpers import make_p0_package, read_json


def test_permission_isolation_filters_retrieval_by_metadata_and_allowed_kbs(tmp_path):
    package = make_p0_package(tmp_path)
    output = tmp_path / "out"

    run_knowledge_governance_completion(package, output)
    report = read_json(output / "permission_isolation_report.json")

    assert report["status"] == "pass"
    assert report["metadata_based_retrieval_filter"] is True
    assert report["unauthorized_retrieval_blocked"] is True
    assert report["agent_allowed_kbs"]["child-agent-a"]
    assert report["agent_allowed_kbs"]["child-agent-b"] == []
