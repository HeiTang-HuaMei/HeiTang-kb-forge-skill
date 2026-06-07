from heitang_kb_forge.memory_lifecycle import write_memory_lifecycle_outputs
from tests.v39_helpers import read_json


def test_memory_lifecycle_report_includes_required_classes_and_compaction(tmp_path):
    write_memory_lifecycle_outputs(tmp_path)

    report = read_json(tmp_path / "memory_lifecycle_report.json")
    classes = {item["name"] for item in report["memory_classes"]}
    assert {
        "session_log",
        "short_term_memory",
        "summary_memory",
        "long_term_memory",
        "memory_candidates",
        "memory_index",
        "retention_policy",
        "compaction_policy",
        "token_budget_policy",
    }.issubset(classes)
    assert read_json(tmp_path / "memory_compaction_plan.json")["raw_session_log_injection_allowed"] is False
    assert (tmp_path / "memory_lifecycle_report.md").exists()
