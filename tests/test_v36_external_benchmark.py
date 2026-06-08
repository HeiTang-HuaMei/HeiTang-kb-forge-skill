import json
from heitang_kb_forge.audit.external_benchmark import external_project_benchmark_report


def _report() -> dict:
    return external_project_benchmark_report()


def test_external_benchmark_report_parses_and_has_mandatory_targets():
    report = _report()
    urls = {project["repo_url"] for project in report["projects"]}

    assert report["benchmark_version"] == "3.6.0-alpha.1"
    assert len(report["projects"]) >= 10
    assert "https://github.com/rohitg00/agentmemory" in urls
    assert "https://github.com/multica-ai/andrej-karpathy-skills" in urls
    assert "https://github.com/mvanhorn/last30days-skill" in urls
    assert "https://github.com/rtk-ai/rtk" in urls
    assert "https://litedoc.xyz" in urls


def test_external_benchmark_project_fields_are_complete():
    required = {
        "project_name",
        "repo_url",
        "license",
        "primary_problem_solved",
        "architecture_pattern",
        "reusable_capability",
        "unsafe_or_unsuitable_parts",
        "dependency_runtime_risk",
        "local_first_compatibility",
        "windows_compatibility",
        "requires_network_or_cloud",
        "code_or_prompt_reuse_safe",
        "recommendation",
        "mapped_heitang_module",
        "mapped_future_version",
    }

    for project in _report()["projects"]:
        assert required.issubset(project)
        assert project["code_or_prompt_reuse_safe"] == "patterns_only_no_code_or_prompt_copy"


def test_agent_memory_and_claim_verification_benchmarks_are_present():
    report = _report()
    by_url = {project["repo_url"]: project for project in report["projects"]}
    project_names = {project["project_name"] for project in report["projects"]}

    assert "agentmemory" == by_url["https://github.com/rohitg00/agentmemory"]["project_name"]
    assert {"RAGAS", "FActScore", "FEVER"}.issubset(project_names)
    assert "claim_verification" in report["benchmark_summary"]["coverage"]
    assert "retrieval_based_verification" in report["benchmark_summary"]["coverage"]


def test_local_pdf_parsing_and_token_reduction_benchmarks_are_present():
    report = _report()
    project_names = {project["project_name"] for project in report["projects"]}
    by_name = {project["project_name"]: project for project in report["projects"]}

    assert {"LiteDoc", "PaddleOCR", "MinerU", "Marker", "Docling"}.issubset(project_names)
    assert "client-side local PDF to Markdown" in by_name["LiteDoc"]["primary_problem_solved"]
    assert by_name["LiteDoc"]["requires_network_or_cloud"] == "no_for_document_processing_after_page_load"
    assert "local_pdf_to_markdown" in report["benchmark_summary"]["coverage"]
    assert "pdf_token_reduction" in report["benchmark_summary"]["coverage"]


def test_external_benchmark_is_static_and_has_no_ui_dependency():
    report = _report()
    serialized = json.dumps(report)

    assert report["network_required_for_tests"] is False
    assert report["benchmark_summary"]["ui_repo_dependency"] is False
    assert "kb-forge-skill-ui" not in serialized
