from pathlib import Path
import shutil

from heitang_kb_forge.workspace.v19_registry import register_workspace_asset


def import_workspace_asset(workspace: Path, source: Path, asset_type: str, copy: bool = False, tags: list[str] | None = None) -> dict:
    target = source
    if copy:
        target_dir = workspace / f"{asset_type}_packages" / source.name
        if target_dir.exists():
            shutil.rmtree(target_dir)
        shutil.copytree(source, target_dir)
        target = target_dir
    return register_workspace_asset(workspace, target, asset_type, tags or [])
