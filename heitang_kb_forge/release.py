from pathlib import Path
import shutil

from heitang_kb_forge.exporters.jsonl_exporter import write_json


def make_release_package(workspace: Path, output: Path, include_demo_outputs: bool = True) -> dict:
    output.mkdir(parents=True, exist_ok=True)
    for name in [
        "workspace_manifest.json",
        "stable_check_result.json",
        "reliability_score.json",
        "studio_run_manifest.json",
        "release_checklist.md",
    ]:
        src = workspace / name
        if src.exists():
            shutil.copyfile(src, output / name)
    manifest = {
        "release_package_version": "2.0",
        "workspace": str(workspace).replace("\\", "/"),
        "include_demo_outputs": include_demo_outputs,
        "files": [path.name for path in output.iterdir()],
    }
    write_json(output / "release_manifest.json", manifest)
    return manifest
