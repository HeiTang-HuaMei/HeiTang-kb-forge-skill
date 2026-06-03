from pathlib import Path

import pytest

from heitang_kb_forge.llm.prompt_profile import load_prompt_profile, prompt_profile_hash


def test_load_product_manager_prompt_profile():
    profile, profile_hash = load_prompt_profile(Path("examples/prompt_profiles/product_manager.yaml"))

    assert profile.profile_name == "product_manager"
    assert profile.language == "zh-CN"
    assert "metrics" in profile.focus
    assert profile.preferred_outputs["cards"] is True
    assert profile.extraction_rules
    assert profile_hash == prompt_profile_hash(profile)


def test_prompt_profile_missing_file_has_clear_error(tmp_path):
    with pytest.raises(FileNotFoundError, match="Prompt profile not found"):
        load_prompt_profile(tmp_path / "missing.yaml")


def test_prompt_profile_invalid_yaml_has_clear_error(tmp_path):
    path = tmp_path / "invalid.yaml"
    path.write_text("profile_name: [", encoding="utf-8")

    with pytest.raises(ValueError, match="Failed to parse prompt profile"):
        load_prompt_profile(path)


def test_prompt_profile_rejects_non_mapping(tmp_path):
    path = tmp_path / "list.yaml"
    path.write_text("- item\n", encoding="utf-8")

    with pytest.raises(ValueError, match="Prompt profile must contain a mapping/object"):
        load_prompt_profile(path)


def test_prompt_profile_requires_profile_name(tmp_path):
    path = tmp_path / "missing_name.yaml"
    path.write_text("language: zh-CN\n", encoding="utf-8")

    with pytest.raises(ValueError, match="Prompt profile field 'profile_name' is required"):
        load_prompt_profile(path)


def test_prompt_profile_requires_preferred_outputs_mapping(tmp_path):
    path = tmp_path / "bad_outputs.yaml"
    path.write_text(
        """
profile_name: bad
preferred_outputs:
  - cards
""",
        encoding="utf-8",
    )

    with pytest.raises(ValueError, match="preferred_outputs.*mapping/object"):
        load_prompt_profile(path)


def test_prompt_profile_requires_extraction_rules_list(tmp_path):
    path = tmp_path / "bad_rules.yaml"
    path.write_text(
        """
profile_name: bad
extraction_rules:
  grounded: true
""",
        encoding="utf-8",
    )

    with pytest.raises(ValueError, match="extraction_rules.*list"):
        load_prompt_profile(path)


def test_prompt_profile_hash_is_stable():
    first, first_hash = load_prompt_profile(Path("examples/prompt_profiles/product_manager.yaml"))
    second, second_hash = load_prompt_profile(Path("examples/prompt_profiles/product_manager.yaml"))

    assert first == second
    assert first_hash == second_hash
