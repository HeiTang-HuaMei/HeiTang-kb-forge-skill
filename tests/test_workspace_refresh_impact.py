import json

from heitang_kb_forge.workspace_refresh import make_workspace_refresh


def test_workspace_refresh_reports_impacted_assets(tmp_path):
    workspace = tmp_path / "workspace"
    (workspace / "skill_a").mkdir(parents=True)
    (workspace / "skill_a" / "SKILL.md").write_text("# Skill", encoding="utf-8")

    make_workspace_refresh(workspace, tmp_path / "out")

    impacted = json.loads((tmp_path / "out" / "impacted_skills.json").read_text(encoding="utf-8"))
    assert impacted["skills"][0]["skill_id"] == "skill_a"

