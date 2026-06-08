from heitang_kb_forge.pre_v4_p0 import run_memory_completion

from tests.p0_helpers import make_p0_package, read_json


def test_memory_token_budget_prevents_all_history_injection(tmp_path):
    package = make_p0_package(tmp_path)
    output = tmp_path / "out"

    run_memory_completion(package, output)
    report = read_json(output / "memory_token_budget_report.json")

    assert report["status"] == "pass"
    assert report["all_history_injection_prevented"] is True
    assert report["max_context_tokens"] > 0
    assert report["compaction_policy"] == "summarize_then_index"
