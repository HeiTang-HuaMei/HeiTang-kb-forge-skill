from heitang_kb_forge.pre_v4_p0 import run_agent_runtime_completion

from tests.p0_helpers import make_p0_package


def test_kb_bound_agent_runtime_proof_allows_own_kb_and_denies_other_kb(tmp_path):
    package = make_p0_package(tmp_path)
    report = run_agent_runtime_completion(package, tmp_path / "out")

    assert report["status"] == "pass"
    assert report["kb_bound_agent_can_access_own_kb"] is True
    assert report["unauthorized_kb_access_denied"] is True
    assert report["allowed_kbs_not_empty"] is True
    assert report["local_deterministic_runtime_without_llm"] is True
