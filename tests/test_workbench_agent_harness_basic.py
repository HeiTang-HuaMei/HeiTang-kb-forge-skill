from heitang_kb_forge.workbench_agent_harness import run_workbench_agent_harness
from tests.v17_helpers import read_json, write_sample_package


def test_workbench_agent_harness_runs_local_retrieve_tool(tmp_path):
    package = write_sample_package(tmp_path / "package", text="Workbench agent harness retrieves local evidence.")
    output = tmp_path / "harness"

    report = run_workbench_agent_harness(
        {
            "agent_name": "Workbench Agent",
            "tool_name": "retrieve_knowledge",
            "package": str(package),
            "query": "local evidence",
            "top_k": 2,
        },
        output,
    )

    result = read_json(output / "tool_result.json")
    trace = read_json(output / "tool_execution_trace.json")
    persisted_report = read_json(output / "workbench_agent_harness_report.json")
    assert report.status == "passed"
    assert report.failed_checks == []
    assert result["status"] == "success"
    assert result["records"]
    assert trace["tool"] == "retrieve_knowledge"
    assert persisted_report["schema_version"] == "workbench_agent_harness.v1"
    assert persisted_report["result_summary"]["record_count"] >= 1
    assert persisted_report["boundary"]["network"] == "not_required"
    assert persisted_report["boundary"]["redis_service_packaging"] == "forbidden"
    assert persisted_report["boundary"]["vector_service_packaging"] == "forbidden"


def test_workbench_agent_harness_rejects_unknown_tool(tmp_path):
    report = run_workbench_agent_harness(
        {"tool_name": "unknown_tool", "package": str(tmp_path / "package"), "query": "local evidence"},
        tmp_path / "harness",
    )

    assert report.status == "failed"
    assert "unknown_tool" in report.failed_checks
    assert (tmp_path / "harness" / "workbench_agent_harness_report.json").exists()
    assert not (tmp_path / "harness" / "tool_result.json").exists()


def test_workbench_agent_harness_rejects_missing_package(tmp_path):
    report = run_workbench_agent_harness(
        {"tool_name": "retrieve_knowledge", "package": str(tmp_path / "missing"), "query": "local evidence"},
        tmp_path / "harness",
    )

    assert report.status == "failed"
    assert report.failed_checks == ["package_not_found"]
    assert (tmp_path / "harness" / "workbench_agent_harness_report.json").exists()
