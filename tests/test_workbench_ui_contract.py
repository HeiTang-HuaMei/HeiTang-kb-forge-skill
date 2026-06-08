import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
WORKBENCH = ROOT / "web" / "workbench"


def test_workbench_contract_exposes_desktop_core_bridge_without_full_operation_claim():
    contracts = json.loads((WORKBENCH / "contracts.json").read_text(encoding="utf-8"))

    assert contracts["scope"] == "mock-plus-desktop-core-bridge-contract"
    assert contracts["future_api"]["no_backend_logic"] is False
    assert contracts["future_api"]["current_backend_logic"] == "desktop local Core CLI bridge contract only; page workflows are not wired end to end yet"
    bridge = contracts["local_core_bridge"]
    assert bridge["status"] == "bridge_contract_tested"
    assert bridge["desktop_runtime"] == "allowlisted_core_cli_process_bridge"
    assert bridge["web_runtime"] == "unsupported_for_local_cli_execution"
    assert bridge["desktop_bridge_only"] is True
    assert bridge["not_full_operation_yet"] is True
    assert bridge["not_v4_0_workbench_rc"] is True
    assert bridge["security"]["run_in_shell"] is False
    assert bridge["security"]["allowlisted_actions_only"] is True
    assert bridge["security"]["rejects_secret_environment"] is True
    assert "mockService.js" in contracts["future_api"]["boundary"]
    assert set(contracts["future_api"]["reserved_resources"]) >= {
        "knowledgeBases",
        "agents",
        "workflows",
        "memoryScopes",
        "jobs",
        "reviewItems",
        "generatedDocs",
        "exportItems",
        "providers",
        "parserBackends",
        "answerPolicies",
        "memoryPolicies",
    }
    assert contracts["flutter"]["project_root"] == "web/workbench/flutter_app"
    assert contracts["flutter"]["desktop"] == "windows"
    assert set(contracts["flutter"]["targets"]) == {"windows", "web", "android", "ios"}
    assert contracts["flutter"]["scaffold_only_when_flutter_cli_missing"] is True
    assert contracts["brand"]["name"] == "黑糖 HeiTang"
    assert contracts["pwa"]["static_web_manifest"] == "web/workbench/manifest.webmanifest"
    assert contracts["pwa"]["flutter_web_manifest"] == "web/workbench/flutter_app/web/manifest.json"


def test_flutter_project_scaffold_has_standard_entry_files():
    flutter_root = WORKBENCH / "flutter_app"
    pubspec = (flutter_root / "pubspec.yaml").read_text(encoding="utf-8")
    gitignore = (flutter_root / ".gitignore").read_text(encoding="utf-8")
    readme = (flutter_root / "README.md").read_text(encoding="utf-8")

    assert (flutter_root / ".metadata").exists()
    assert (flutter_root / ".gitignore").exists()
    assert (flutter_root / "analysis_options.yaml").exists()
    assert (flutter_root / "lib" / "main.dart").exists()
    assert (flutter_root / "pubspec.lock").exists()
    assert (flutter_root / "test" / "widget_test.dart").exists()
    assert "name: heitang_workbench" in pubspec
    assert "flutter_lints" in pubspec
    assert ".dart_tool/" in gitignore
    assert "build/" in gitignore
    assert "android/local.properties" in gitignore
    assert "flutter run -d windows" in readme
    assert "flutter run -d chrome" in readme
    assert "not_full_operation_yet: true" in readme
    assert "not the v4.0 Workbench RC" in readme
    assert "Web does not execute the local Core CLI" in readme


def test_workbench_pages_reference_existing_mock_sources():
    contracts = json.loads((WORKBENCH / "contracts.json").read_text(encoding="utf-8"))
    mock_sources = contracts["mock_data_files"]

    for page in contracts["pages"]:
        assert page["mock_sources"]
        for source in page["mock_sources"]:
            assert source in mock_sources
            assert (ROOT / mock_sources[source]).exists()


def test_mock_service_is_the_only_data_loading_boundary():
    service = (WORKBENCH / "src" / "mockService.js").read_text(encoding="utf-8")
    app = (WORKBENCH / "src" / "app.js").read_text(encoding="utf-8")

    assert "examples/ui_mock_data" in service
    assert "fetch(" in service
    assert "loadWorkbenchData" in service
    assert 'from "./mockService.js"' in app

    forbidden_core_imports = [
        "cli_runtime",
        "parser_backends",
        "knowledge_runtime",
        "document_generation",
        "agent_factory",
        "orchestration",
        "memory_runtime",
        "heitang_kb_forge",
    ]
    import_lines = [
        line.strip()
        for line in (service + app).splitlines()
        if line.strip().startswith("import ")
    ]
    for forbidden in forbidden_core_imports:
        assert all(forbidden not in line for line in import_lines)


def test_flutter_scaffold_does_not_import_core_modules():
    flutter_files = list((WORKBENCH / "flutter_app").rglob("*"))
    text_files = [
        path
        for path in flutter_files
        if path.is_file() and path.suffix in {".dart", ".yaml", ".gradle", ".kt", ".swift", ".cpp", ".txt", ".md", ".plist"}
        and "core_bridge" not in path.parts
    ]
    combined = "\n".join(path.read_text(encoding="utf-8", errors="ignore") for path in text_files)

    for forbidden in [
        "cli_runtime",
        "parser_backends",
        "knowledge_runtime",
        "document_generation",
        "agent_factory",
        "orchestration",
        "memory_runtime",
        "heitang_kb_forge",
    ]:
        assert forbidden not in combined


def test_workbench_changed_surface_is_limited_to_allowed_paths():
    contracts = json.loads((WORKBENCH / "contracts.json").read_text(encoding="utf-8"))
    allowed = set(contracts["allowed_paths"])

    assert "web/workbench/" in allowed
    assert "examples/ui_mock_data/" in allowed
    assert "tests/test_workbench_ui_contract.py" in allowed
    assert "docs/WORKBENCH_UI_SPEC.md" in allowed
