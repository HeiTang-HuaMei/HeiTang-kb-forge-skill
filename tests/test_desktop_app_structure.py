import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DESKTOP = ROOT / "desktop" / "tauri"


def test_tauri_desktop_scaffold_files_exist():
    for path in [
        DESKTOP / "package.json",
        DESKTOP / "tsconfig.json",
        DESKTOP / "vite.config.ts",
        DESKTOP / "index.html",
        DESKTOP / "src" / "App.tsx",
        DESKTOP / "src" / "main.tsx",
        DESKTOP / "src" / "i18n.ts",
        DESKTOP / "src-tauri" / "Cargo.toml",
        DESKTOP / "src-tauri" / "tauri.conf.json",
        DESKTOP / "src-tauri" / "src" / "main.rs",
    ]:
        assert path.exists(), path


def test_tauri_desktop_uses_tauri_react_and_not_electron():
    package = json.loads((DESKTOP / "package.json").read_text(encoding="utf-8"))
    dependencies = package["dependencies"] | package["devDependencies"]

    assert "@tauri-apps/api" in dependencies
    assert "@tauri-apps/cli" in dependencies
    assert "react" in dependencies
    assert "vite" in dependencies
    assert "electron" not in dependencies
    assert package["scripts"]["build"].startswith("vite build")
    assert package["scripts"]["tauri:build"] == "tauri build"
    assert package["scripts"]["typecheck"] == "tsc --noEmit"


def test_tauri_backend_wraps_local_cli_only():
    main_rs = (DESKTOP / "src-tauri" / "src" / "main.rs").read_text(encoding="utf-8")

    assert "Command::new(\"heitang-kb-forge\")" in main_rs
    assert "run_kb_forge" in main_rs
    assert "build" in main_rs
    assert "batch" in main_rs
    assert "pipeline" in main_rs


def test_desktop_components_exist():
    for name in [
        "Sidebar.tsx",
        "TopBar.tsx",
        "StatusCard.tsx",
        "CommandPreview.tsx",
        "RunLog.tsx",
        "FileList.tsx",
        "JsonViewer.tsx",
        "MarkdownPanel.tsx",
        "EmptyState.tsx",
        "Badge.tsx",
        "FormRow.tsx",
        "SectionCard.tsx",
        "PathInput.tsx",
        "ToggleOption.tsx",
    ]:
        assert (DESKTOP / "src" / "components" / name).exists(), name


def test_desktop_pages_exist():
    for name in [
        "Dashboard.tsx",
        "BuildPackage.tsx",
        "BatchProcessing.tsx",
        "Workspace.tsx",
        "LifecycleUpdate.tsx",
        "QualityGate.tsx",
        "PackageDetail.tsx",
        "AskRuntime.tsx",
        "PublishExport.tsx",
        "PlanningReadiness.tsx",
        "Settings.tsx",
    ]:
        assert (DESKTOP / "src" / "pages" / name).exists(), name
