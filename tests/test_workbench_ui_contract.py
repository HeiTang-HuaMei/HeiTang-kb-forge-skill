import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
WORKBENCH = ROOT / "web" / "workbench"
CORE_COMMIT = "f5fa13bb11211abb0bcecaccd845e545a2dacad3"
CORE_STABLE_COMMIT = "0217e54b162871e7c40c31ff3d0cc72e8ba78f06"
PARSER_RUNTIME_BASELINE_COMMIT = "576a62075dc1ecbe00388bb0569fd1fc767be7cb"


def test_workbench_contract_exposes_desktop_core_bridge_without_full_operation_claim():
    contracts = json.loads((WORKBENCH / "contracts.json").read_text(encoding="utf-8"))

    assert contracts["scope"] == "p2.1-v4.1.0-parser-backend-evidence-sync"
    assert contracts["core_contract_source"]["core_commit"] == CORE_COMMIT
    assert contracts["future_api"]["no_backend_logic"] is False
    assert contracts["future_api"]["current_backend_logic"] == "desktop local Core CLI bridge contract plus copied P1-RWF-V2, P1 final gate, S/A boundary, and P2.1 parser backend evidence consumption; web still does not execute local CLI or parser/OCR runtimes"
    parser_source = contracts["parser_backend_source"]
    assert parser_source["core_runtime_baseline_commit"] == PARSER_RUNTIME_BASELINE_COMMIT
    assert parser_source["release_version"] == "v4.1.0"
    assert parser_source["matrix_fixture"] == "examples/ui_mock_data/parser_backends/parser_backend_matrix.json"
    assert parser_source["flutter_asset"] == "web/workbench/flutter_app/assets/parser_backends/parser_backend_matrix.json"
    assert "no parser/OCR runtime execution controls" in parser_source["policy"]
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
        "parserBackendMatrix",
        "answerPolicies",
        "memoryPolicies",
    }
    assert contracts["flutter"]["project_root"] == "web/workbench/flutter_app"
    assert contracts["flutter"]["desktop"] == "windows"
    assert set(contracts["flutter"]["targets"]) == {"windows", "web", "android", "ios"}
    assert contracts["flutter"]["scaffold_only_when_flutter_cli_missing"] is True
    assert contracts["brand"]["name"] == "黑糖 HeiTang"
    assert contracts["theme"]["default_visual_style"] == "black / white / gray premium Windows desktop workbench"
    assert contracts["theme"]["modes"] == ["light", "dark"]
    assert contracts["theme"]["not_macos_shell"] is True
    assert contracts["theme"]["state_colors_only_for"] == ["success", "warning", "error", "running", "blocked"]
    assert contracts["i18n"]["locales"] == ["zh-CN", "en-US"]
    assert contracts["release_boundary"]["supports_light_dark_mode"] is True
    assert contracts["release_boundary"]["supports_zh_cn_en_us_switch"] is True
    assert contracts["release_boundary"]["not_v4_0_release"] is False
    assert contracts["release_boundary"]["not_v4_0_workbench_rc"] is False
    assert contracts["release_boundary"]["stable_release"] == "v4.0.0"
    assert contracts["release_boundary"]["current_release_line"] == "v4.1.0"
    assert contracts["release_boundary"]["release_candidate"] == "v4.1.0"
    assert contracts["release_boundary"]["release_candidate_tag_created"] is False
    assert contracts["release_boundary"]["release_candidate_release_created"] is False
    assert contracts["release_boundary"]["core_stable_commit"] == CORE_STABLE_COMMIT
    assert contracts["release_boundary"]["ready_for_v4_rc"] is True
    assert contracts["release_boundary"]["not_full_operation_yet"] is False
    assert contracts["pwa"]["static_web_manifest"] == "web/workbench/manifest.webmanifest"
    assert contracts["pwa"]["flutter_web_manifest"] == "web/workbench/flutter_app/web/manifest.json"


def test_readme_states_workbench_visual_and_release_boundary():
    readme = (ROOT / "README.md").read_text(encoding="utf-8")

    assert "black / white / gray premium Windows desktop workbench" in readme
    assert "light / dark mode" in readme
    assert "zh-CN / en-US language switch" in readme
    assert "v4.1.0 P2.1 Parser/OCR Workbench sync" in readme
    assert "v4.0.0` tag remains untouched" in readme
    assert CORE_STABLE_COMMIT in readme
    assert "P1 final gate re-run evidence UI consumption pass" in readme
    assert CORE_COMMIT in readme
    assert PARSER_RUNTIME_BASELINE_COMMIT in readme
    assert "Unstructured is optional dependency gated with stable `.md/.txt` surface only" in readme
    assert "does not expose parser/OCR runtime execution controls" in readme
    assert "ready_for_v4_rc=true" in readme
    assert "not_v4_0_workbench_rc" in readme


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
    assert "ready_for_v4_rc=true" in readme
    assert "p1_full_operation_gate_status: ready_for_v4_rc" in readme
    assert "v4.1.0 Workbench evidence sync" in readme
    assert "historical `v4.0.0` tag remains untouched" in readme
    assert "assets/parser_backends/parser_backend_matrix.json" in readme
    assert "Unstructured is displayed with stable `.md/.txt` surface only" in readme
    assert "Web does not execute the local Core CLI" in readme


def test_workbench_pages_reference_existing_mock_sources():
    contracts = json.loads((WORKBENCH / "contracts.json").read_text(encoding="utf-8"))
    mock_sources = contracts["mock_data_files"]

    for page in contracts["pages"]:
        assert page["mock_sources"]
        assert "p1_core_contracts" in page["mock_sources"]
        for source in page["mock_sources"]:
            assert source in mock_sources
            assert (ROOT / mock_sources[source]).exists()
    for source in [
        "p1_real_workflow_v2_matrix",
        "p1_real_workflow_v2_action_results",
        "p1_real_workflow_v2_artifact_assertions",
        "p1_real_workflow_v2_user_paths",
        "p1_real_workflow_v2_gate_report",
        "parser_backend_matrix",
    ]:
        assert source in mock_sources
        assert (ROOT / mock_sources[source]).exists()
    for page in contracts["pages"]:
        if page["id"] in {
            "dashboard",
            "operation-gate",
            "capability-matrix",
            "import-parsing",
            "artifact-management",
            "error-repair-center",
            "reports-audit",
        }:
            assert "parser_backend_matrix" in page["mock_sources"]


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
    import_lines = [
        line.strip()
        for path in text_files
        for line in path.read_text(encoding="utf-8", errors="ignore").splitlines()
        if line.strip().startswith("import ")
    ]

    for forbidden in [
        "cli_runtime",
        "parser_backends",
        "knowledge_runtime",
        "from heitang_kb_forge",
        "import heitang_kb_forge",
        "orchestration",
        "memory_runtime",
    ]:
        assert all(forbidden not in line for line in import_lines)


def test_workbench_changed_surface_is_limited_to_allowed_paths():
    contracts = json.loads((WORKBENCH / "contracts.json").read_text(encoding="utf-8"))
    allowed = set(contracts["allowed_paths"])

    assert "web/workbench/" in allowed
    assert "examples/ui_mock_data/" in allowed
    assert "docs/audits/core_ui_acceptance/" in allowed
    assert "tests/test_workbench_ui_contract.py" in allowed
    assert "tests/test_workbench_p1_contract_alignment.py" in allowed
    assert "docs/WORKBENCH_UI_SPEC.md" in allowed
