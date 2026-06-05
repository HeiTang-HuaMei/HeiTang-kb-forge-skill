from pathlib import Path

from heitang_kb_forge.exporters.jsonl_exporter import write_json
from heitang_kb_forge.workspace_refresh.dependency import dependency_report
from heitang_kb_forge.workspace_refresh.impact import impacted_workspace_assets
from heitang_kb_forge.workspace_refresh.report import render_refresh_impact_report, render_source_change_report
from heitang_kb_forge.workspace_refresh.source_watcher import scan_workspace_sources


def make_workspace_refresh(workspace: Path, output: Path) -> dict:
    output.mkdir(parents=True, exist_ok=True)
    sources = scan_workspace_sources(workspace)
    packages, skills, agents = impacted_workspace_assets(workspace)
    result = {
        "workspace": str(workspace).replace("\\", "/"),
        "changed_sources": len(sources),
        "stale_packages": 0,
        "impacted_packages": packages,
        "impacted_skills": skills,
        "impacted_agents": agents,
    }
    write_json(output / "source_change_report.json", {"sources": sources})
    (output / "source_change_report.md").write_text(render_source_change_report(sources), encoding="utf-8")
    write_json(output / "refresh_plan.json", {"actions": ["revalidate"], "source_count": len(sources)})
    (output / "refresh_impact_report.md").write_text(render_refresh_impact_report(packages, skills, agents), encoding="utf-8")
    (output / "stale_package_report.md").write_text("# Stale Package Report\n\n- Stale packages: 0\n", encoding="utf-8")
    write_json(output / "impacted_packages.json", {"packages": packages})
    write_json(output / "impacted_skills.json", {"skills": skills})
    write_json(output / "impacted_agents.json", {"agents": agents})
    write_json(output / "dependency_impact_report.json", dependency_report(packages, skills, agents))
    (output / "dependency_impact_report.md").write_text(render_refresh_impact_report(packages, skills, agents), encoding="utf-8")
    return result
