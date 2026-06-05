from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_generate_derived_skill_combines_master_analysis_with_knowledge_package(tmp_path):
    analysis = tmp_path / "analysis"
    package = tmp_path / "package"
    output = tmp_path / "derived"
    analysis.mkdir()
    package.mkdir()
    (analysis / "skill_decomposition.json").write_text(
        '{"workflow_steps":["retrieve evidence","answer with citation"],"boundary_rules":["do not answer outside scope"],"style_features":["concise"]}',
        encoding="utf-8",
    )
    (package / "manifest.json").write_text('{"package_id":"demo_package"}', encoding="utf-8")

    result = CliRunner().invoke(
        app,
        ["generate-derived-skill", "--master-skill", str(analysis), "--knowledge-package", str(package), "--output", str(output)],
    )

    assert result.exit_code == 0, result.output
    assert (output / "SKILL.md").exists()
    assert (output / "knowledge_scope.md").read_text(encoding="utf-8").find(str(package)) >= 0
    assert (output / "derivation_report.md").exists()
    assert (output / "skill_safety_check_result.json").exists()
    assert (output / "skill_similarity_report.md").exists()
    assert (output / "skill_license_report.md").exists()
