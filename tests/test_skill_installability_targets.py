from tests.structured_skill_helpers import make_structured_skill, read_json


def test_skill_installability_targets_are_reported_for_claude_codex_openclaw(tmp_path):
    _, skill = make_structured_skill(tmp_path)

    report = read_json(skill / "skill_installability_report.json")

    assert report["status"] == "pass"
    for target in ["claude_code", "codex", "openclaw"]:
        assert (skill / f"{target}_skill_compat_report.json").exists()
        assert report["targets"][target]["status"] == "pass"
        assert report["targets"][target]["network_required"] is False
