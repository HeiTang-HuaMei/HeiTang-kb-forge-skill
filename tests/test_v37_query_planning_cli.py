import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_rewrite_query_command_writes_reports(tmp_path):
    output = tmp_path / "rewrite"

    result = CliRunner().invoke(app, ["rewrite-query", "--query", "summary", "--output", str(output)])

    assert result.exit_code == 0, result.output
    report = _json(output / "query_rewrite_report.json")
    assert report["rewrite_reason"] == "vague_query_grounded_summary"
    assert report["tests_require_real_llm_api_network"] is False
    assert (output / "query_rewrite_trace.json").exists()
    assert (output / "retrieval_plan.json").exists()


def test_plan_retrieval_command_supports_validation_purpose(tmp_path):
    output = tmp_path / "plan"

    result = CliRunner().invoke(
        app,
        ["plan-retrieval", "--query", "pricing evidence", "--purpose", "validation", "--output", str(output)],
    )

    assert result.exit_code == 0, result.output
    plan = _json(output / "retrieval_plan.json")
    assert plan["retrieval_purpose"] == "validation"
    assert plan["refusal_policy"]["external_retrieval"] == "not_implemented_in_v3_7"


def test_plan_retrieval_command_reports_invalid_purpose(tmp_path):
    result = CliRunner().invoke(
        app,
        ["plan-retrieval", "--query", "pricing", "--purpose", "external", "--output", str(tmp_path / "out")],
    )

    assert result.exit_code != 0
    assert "retrieval purpose must be one of" in result.output


def test_eval_query_rewrite_command_writes_eval_report(tmp_path):
    cases = tmp_path / "cases.jsonl"
    output = tmp_path / "eval"
    cases.write_text(
        json.dumps({"case_id": "vague", "query": "summary", "expected_rewrite_contains": "knowledge package"}) + "\n",
        encoding="utf-8",
    )

    result = CliRunner().invoke(app, ["eval-query-rewrite", "--cases", str(cases), "--output", str(output)])

    assert result.exit_code == 0, result.output
    report = _json(output / "query_rewrite_eval_report.json")
    assert report["status"] == "pass"
    assert report["case_count"] == 1
    assert report["tests_require_real_llm_api_network"] is False


def test_allow_llm_rewrite_does_not_call_real_llm(tmp_path):
    output = tmp_path / "rewrite"

    result = CliRunner().invoke(app, ["rewrite-query", "--query", "pricing", "--output", str(output), "--allow-llm-rewrite"])

    assert result.exit_code == 0, result.output
    plan = _json(output / "retrieval_plan.json")
    assert plan["optional_llm_assist_path"] == "reserved_only"
    assert plan["llm_used"] is False
    assert plan["tests_require_real_llm_api_network"] is False


def _json(path):
    return json.loads(path.read_text(encoding="utf-8"))
