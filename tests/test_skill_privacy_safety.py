from tests.structured_skill_helpers import make_structured_skill, read_json


def test_skill_privacy_safety_boundary_blocks_hidden_upload_and_raw_text_claims(tmp_path):
    _, skill = make_structured_skill(tmp_path)

    report = read_json(skill / "skill_privacy_safety_report.json")
    boundary = (skill / "safety_boundary.md").read_text(encoding="utf-8")

    assert report["status"] == "pass"
    assert report["hidden_upload"] is False
    assert report["local_first_default"] is True
    assert report["raw_source_text_copied_wholesale"] is False
    assert report["api_keys_committed"] is False
    assert "Do not upload source files" in boundary
    assert "real LLM/API/network" in boundary
