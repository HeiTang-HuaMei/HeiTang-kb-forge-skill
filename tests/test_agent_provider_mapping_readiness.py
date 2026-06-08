from heitang_kb_forge.pre_v4_p0 import run_agent_runtime_completion

from tests.p0_helpers import make_p0_package, read_json


def test_agent_provider_mapping_readiness_is_local_without_llm_requirement(tmp_path):
    package = make_p0_package(tmp_path)
    output = tmp_path / "out"

    run_agent_runtime_completion(package, output)
    report = read_json(output / "agent_provider_mapping_readiness_report.json")

    assert report["status"] == "pass"
    assert report["per_agent_provider_profile"]["llm_required"] is False
    assert report["per_agent_provider_profile"]["network_required"] is False
