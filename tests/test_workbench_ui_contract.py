import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
WORKBENCH = ROOT / "web" / "workbench"


def test_workbench_contract_uses_mock_only_scope_and_future_service_boundary():
    contracts = json.loads((WORKBENCH / "contracts.json").read_text(encoding="utf-8"))

    assert contracts["scope"] == "mock-only"
    assert contracts["future_api"]["no_backend_logic"] is True
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


def test_workbench_changed_surface_is_limited_to_allowed_paths():
    contracts = json.loads((WORKBENCH / "contracts.json").read_text(encoding="utf-8"))
    allowed = set(contracts["allowed_paths"])

    assert "web/workbench/" in allowed
    assert "examples/ui_mock_data/" in allowed
    assert "tests/test_workbench_ui_contract.py" in allowed
    assert "docs/WORKBENCH_UI_SPEC.md" in allowed
