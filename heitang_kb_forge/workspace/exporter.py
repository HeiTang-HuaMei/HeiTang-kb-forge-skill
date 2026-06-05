from pathlib import Path
import json
import shutil

from heitang_kb_forge.exporters.jsonl_exporter import write_json


def export_workspace(workspace: Path, output: Path) -> dict:
    output.mkdir(parents=True, exist_ok=True)
    exported = []
    for name in ["workspace_manifest.json", "registries"]:
        src = workspace / name
        dst = output / name
        if src.is_dir():
            if dst.exists():
                shutil.rmtree(dst)
            shutil.copytree(src, dst)
        elif src.exists():
            shutil.copyfile(src, dst)
        exported.append(name)
    manifest = {
        "export_version": "1.9",
        "workspace": str(workspace).replace("\\", "/"),
        "exported_files": exported,
    }
    write_json(output / "export_manifest.json", manifest)
    return manifest
