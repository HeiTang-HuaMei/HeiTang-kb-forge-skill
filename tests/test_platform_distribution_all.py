from heitang_kb_forge.platform_distribution import SUPPORTED_PLATFORMS, export_platform_package
from heitang_kb_forge.platform_distribution.platforms import required_files


def test_platform_distribution_exports_all_supported_platforms(tmp_path):
    skill = tmp_path / "skill"
    output = tmp_path / "exports"
    skill.mkdir()
    (skill / "SKILL.md").write_text("# Demo Skill", encoding="utf-8")

    export_platform_package(skill, None, output, "all")

    for platform in SUPPORTED_PLATFORMS:
        platform_output = output / platform
        for file_name in required_files(platform):
            assert (platform_output / file_name).exists()
