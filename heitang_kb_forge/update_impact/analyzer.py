from pathlib import Path

from heitang_kb_forge.exporters.jsonl_exporter import write_json
from heitang_kb_forge.update_impact.agent_impact import find_impacted_agents
from heitang_kb_forge.update_impact.report import render_dependency_impact, render_update_required
from heitang_kb_forge.update_impact.skill_impact import find_impacted_skills


def analyze_update_impact(workspace: Path, package: Path, output: Path) -> dict:
    output.mkdir(parents=True, exist_ok=True)
    package_id = package.name
    impacted_packages = {"packages": [{"package_id": package_id, "package_path": str(package).replace("\\", "/"), "impact_level": "medium"}]}
    impacted_skills = {"skills": find_impacted_skills(workspace, package_id)}
    impacted_agents = {"agents": find_impacted_agents(workspace, impacted_skills["skills"])}
    write_json(output / "impacted_packages.json", impacted_packages)
    write_json(output / "impacted_skills.json", impacted_skills)
    write_json(output / "impacted_agents.json", impacted_agents)
    (output / "update_required_report.md").write_text(render_update_required(impacted_skills, impacted_agents), encoding="utf-8")
    (output / "dependency_impact_report.md").write_text(render_dependency_impact(impacted_packages, impacted_skills, impacted_agents), encoding="utf-8")
    return {"packages": impacted_packages, "skills": impacted_skills, "agents": impacted_agents}
