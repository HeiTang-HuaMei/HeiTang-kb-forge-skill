from pathlib import Path

from heitang_kb_forge.exporters.jsonl_exporter import write_json
from heitang_kb_forge.package_lineage.version_graph import make_version_graph
from .report import render_dependency_report, render_lineage_report


def make_package_lineage(workspace: Path, output: Path) -> dict:
    output.mkdir(parents=True, exist_ok=True)
    graph = make_version_graph(workspace)
    write_json(output / "package_version_graph.json", graph)
    (output / "package_lineage_report.md").write_text(render_lineage_report(graph), encoding="utf-8")
    (output / "package_dependency_report.md").write_text(render_dependency_report(graph), encoding="utf-8")
    return graph
