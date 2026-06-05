from heitang_kb_forge.platform_distribution import SUPPORTED_PLATFORMS, export_platform_package


def test_platform_distribution_exports_all_supported_platforms(tmp_path):
    skill = tmp_path / "skill"
    output = tmp_path / "exports"
    skill.mkdir()
    (skill / "SKILL.md").write_text("# Demo Skill", encoding="utf-8")

    export_platform_package(skill, None, output, "all")

    for platform in SUPPORTED_PLATFORMS:
        assert (output / platform / "platform_manifest.json").exists()
        assert (output / platform / "mock_publish_result.json").exists()

