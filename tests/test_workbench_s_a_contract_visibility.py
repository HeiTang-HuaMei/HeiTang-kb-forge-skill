import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
WORKBENCH = ROOT / "web" / "workbench"
CONTRACTS = WORKBENCH / "contracts.json"
REGISTRY = ROOT / "examples" / "ui_mock_data" / "external" / "external_capability_registry_fixture.json"
FLUTTER_LIB = WORKBENCH / "flutter_app" / "lib"


def _json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def _flutter_shell_sources() -> str:
    return "\n".join(
        [
            (FLUTTER_LIB / "main.dart").read_text(encoding="utf-8"),
            (FLUTTER_LIB / "app" / "workbench_pages.dart").read_text(encoding="utf-8"),
            (FLUTTER_LIB / "app" / "workbench_sidebar.dart").read_text(encoding="utf-8"),
            (FLUTTER_LIB / "shared" / "product_components.dart").read_text(encoding="utf-8"),
        ]
    )


def test_external_capability_sources_are_registered_for_existing_pages_only():
    contracts = _json(CONTRACTS)
    route_ids = {page["id"] for page in contracts["pages"]}

    assert "external_capability_registry" in contracts["mock_data_files"]
    assert "s_a_contract_inclusion_matrix" in contracts["mock_data_files"]
    assert "externalCapabilities" in contracts["future_api"]["reserved_resources"]
    assert "sAContractInclusionMatrix" in contracts["future_api"]["reserved_resources"]
    assert "external-capability" not in route_ids
    for page_id in [
        "dashboard",
        "operation-gate",
        "capability-matrix",
        "retrieval-verification",
        "vector-hub-provider-storage",
        "skill-factory",
        "memory-center",
        "reports-audit",
        "template-library",
    ]:
        page = next(page for page in contracts["pages"] if page["id"] == page_id)
        assert "external_capability_registry" in page["mock_sources"]
        assert "s_a_contract_inclusion_matrix" in page["mock_sources"]


def test_web_mock_service_loads_external_capabilities_without_runtime_calls():
    service = (WORKBENCH / "src" / "mockService.js").read_text(encoding="utf-8")
    app = (WORKBENCH / "src" / "app.js").read_text(encoding="utf-8")

    assert "external/external_capability_registry_fixture.json" in service
    assert "external/s_a_contract_inclusion_matrix_fixture.json" in service
    assert "externalCapabilityPanel" in app
    assert "Visibility only" in app
    assert "data-blocked-reason" in app
    assert "external-capability-run" not in app
    assert "AnySearchSkill API callable" not in app


def test_flutter_surface_mentions_boundary_not_run_or_installed_claims():
    flutter_sources = _flutter_shell_sources()
    bridge = (WORKBENCH / "flutter_app" / "lib" / "core_bridge" / "local_core_bridge.dart").read_text(encoding="utf-8")

    assert "assets/external/external_capability_registry.json" in flutter_sources
    assert "Provider" in flutter_sources
    assert "OCR" in flutter_sources
    assert "Parser" in flutter_sources
    assert "Authorization protected" in flutter_sources
    assert "S/A external capabilities" not in flutter_sources
    assert "hot-swap" not in flutter_sources.lower()
    assert "plugin project" not in flutter_sources.lower()
    assert "external project" not in flutter_sources.lower()
    assert "anysearchskill" not in bridge.lower()
    assert "weknora" not in bridge.lower()
    assert "n8n" not in bridge.lower()


def test_special_project_boundaries_are_not_silent():
    projects = {project["project_id"]: project for project in _json(REGISTRY)["projects"]}

    assert projects["n8n"]["can_execute_locally_before_v4"] is False
    assert "external_runtime_required" in projects["n8n"]["blocked_reasons"]
    assert projects["anysearchskill"]["can_execute_locally_before_v4"] is False
    assert "provider_adapter" in projects["anysearchskill"]["contract_status"]
    assert "needs_strengthening" in projects["anysearchskill"]["contract_status"]
    assert "ui_configuration_pending" in projects["anysearchskill"]["blocked_reasons"]
    assert "network_required" in projects["anysearchskill"]["blocked_reasons"]
    assert projects["anysearchskill"]["requires_api_key"] is False
    assert projects["anysearchskill"]["requires_network"] is True
    assert projects["llm_wiki_v2"]["can_execute_locally_before_v4"] is False
    assert projects["llm_wiki_v2"]["executable_action"] is False
    assert "runtime_not_bundled" in projects["llm_wiki_v2"]["contract_status"]
    assert "ui_visibility_only" in projects["llm_wiki_v2"]["blocked_reasons"]
    assert projects["weknora"]["can_execute_locally_before_v4"] is False
    assert projects["weknora"]["executable_action"] is False
    assert "runtime_not_bundled" in projects["weknora"]["contract_status"]
    assert "ui_visibility_only" in projects["weknora"]["blocked_reasons"]
