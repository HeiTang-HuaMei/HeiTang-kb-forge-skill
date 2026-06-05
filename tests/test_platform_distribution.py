import json

from heitang_kb_forge.platform_distribution import export_platform_package


def test_platform_distribution_exports_generic_package(tmp_path):
    skill = tmp_path / "skill"
    agent = tmp_path / "agent"
    output = tmp_path / "export"
    skill.mkdir()
    agent.mkdir()
    (skill / "SKILL.md").write_text("# Demo Skill", encoding="utf-8")
    (agent / "agent_profile.yaml").write_text("name: Demo Agent\n", encoding="utf-8")

    export_platform_package(skill, agent, output, "generic")

    manifest = json.loads((output / "platform_manifest.json").read_text(encoding="utf-8"))
    assert manifest["platform"] == "generic"
    assert manifest["real_upload_performed"] is False
    assert (output / "platform_upload_check_result.json").exists()
    assert (output / "mock_publish_result.json").exists()
    assert (output / "install_guide.md").exists()
    assert (output / "upload_guide.md").exists()

