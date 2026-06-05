from heitang_kb_forge.prompt_profiles.registry import add_prompt_profile, list_prompt_profiles


def test_prompt_profile_registry_adds_profile(tmp_path):
    workspace = tmp_path / "workspace"
    rules = tmp_path / "rules.yaml"
    rules.write_text("rules: []", encoding="utf-8")

    add_prompt_profile(workspace, "skill_default", "skill_generation", rules)
    registry = list_prompt_profiles(workspace)

    assert registry["profiles"][0]["profile_id"] == "skill_default"
