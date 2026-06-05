from heitang_kb_forge.skill.manifest import make_skill_manifest, render_skill_manifest_yaml
from tests.v17_helpers import write_sample_package


def test_skill_manifest_contains_source_package_id(tmp_path):
    package = write_sample_package(tmp_path / "package")

    manifest = make_skill_manifest(package, "Demo Skill", "generic")
    yaml_text = render_skill_manifest_yaml(manifest)

    assert manifest.skill_id == "demo-skill"
    assert "source_package_id:" in yaml_text
