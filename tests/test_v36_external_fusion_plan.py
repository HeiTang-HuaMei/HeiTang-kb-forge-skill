import json
from heitang_kb_forge.audit.fusion_plan import external_fusion_plan


def _report() -> dict:
    return external_fusion_plan()


def test_external_fusion_plan_parses_and_preserves_no_copy_policy():
    report = _report()
    policy = report["no_copy_policy"]

    assert report["external_fusion_plan_version"] == "3.6.0-alpha.1"
    assert policy["external_code_copied"] is False
    assert policy["external_prompts_copied"] is False
    assert policy["external_datasets_copied"] is False
    assert policy["manual_license_review_required_before_reuse"] is True


def test_external_fusion_plan_treats_external_retrieval_as_validation_first():
    report = _report()
    serialized = json.dumps(report)

    assert "Use external sources to validate claims first" in serialized
    assert any("Blindly importing external web results into a KB package" in item for item in report["patterns_to_reject"])
    assert any("Treating external retrieval as unrestricted knowledge expansion" in item for item in report["patterns_to_reject"])


def test_external_fusion_plan_maps_v38_and_v43():
    report = _report()

    assert "external retrieval for knowledge accuracy verification" in report["target_versions"]["v3.8"].lower()
    assert "accuracy status" in report["target_versions"]["v4.3"].lower()
    assert any(item["pattern"] == "claim_level_verification_reports" for item in report["safe_patterns_to_absorb"])


def test_external_fusion_plan_rejects_cloud_pdf_upload_and_raw_pdf_llm_flow():
    report = _report()
    serialized = json.dumps(report)

    assert "local_pdf_to_markdown_preprocessing" in serialized
    assert "Uploading user PDFs to cloud document APIs by default" in serialized
    assert "Sending raw PDFs wholesale to an LLM" in serialized
    assert report["no_copy_policy"]["document_parsing_policy"].startswith("Prefer local parsing")
