import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
MOCK_DATA = ROOT / "examples" / "ui_mock_data" / "external"
FLUTTER_ASSETS = ROOT / "web" / "workbench" / "flutter_app" / "assets" / "external"
CONTRACTS = ROOT / "web" / "workbench" / "contracts.json"
CORE_COMMIT = "c30f8adcadfedb30cb974eb62cc02a38c35a5158"
CORE_CI_RUN_ID = "27221946149"


def _json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def _registry() -> dict:
    return _json(MOCK_DATA / "external_capability_registry_fixture.json")


def test_external_capability_fixture_and_flutter_asset_match():
    fixture = MOCK_DATA / "external_capability_registry_fixture.json"
    asset = FLUTTER_ASSETS / "external_capability_registry.json"
    matrix_fixture = MOCK_DATA / "s_a_contract_inclusion_matrix_fixture.json"
    matrix_asset = FLUTTER_ASSETS / "s_a_contract_inclusion_matrix.json"

    assert asset.exists()
    assert matrix_asset.exists()
    assert _json(asset) == _json(fixture)
    assert _json(matrix_asset) == _json(matrix_fixture)


def test_external_capability_source_is_declared_without_changing_p1_readiness():
    contracts = _json(CONTRACTS)

    assert contracts["external_capability_source"]["core_commit"] == CORE_COMMIT
    assert contracts["external_capability_source"]["core_ci_run_id"] == CORE_CI_RUN_ID
    assert contracts["release_boundary"]["ready_for_v4_rc"] is True
    assert contracts["release_boundary"]["not_v4_0_release"] is True
    assert contracts["release_boundary"]["not_v4_0_workbench_rc"] is True


def test_external_capability_registry_counts_and_release_boundary():
    registry = _registry()

    assert registry["rating_counts"] == {"S": 7, "A": 16}
    assert registry["external_project_count"] == 23
    assert registry["internal_capability_anchor_count"] == 8
    assert registry["release_boundary"]["p1_gate_changed"] is False
    assert registry["release_boundary"]["v4_0_started"] is False
    assert registry["release_boundary"]["external_features_implemented"] is False
    assert registry["release_boundary"]["planned_adapters_marked_ready"] is False
    assert registry["release_boundary"]["provider_network_api_ready"] is False


def test_external_projects_are_not_ready_installed_or_local_executable():
    for project in _registry()["projects"]:
        assert project["implemented"] is False
        assert project["ready"] is False
        assert project["local_ready"] is False
        assert project["executable_action"] is False
        assert project["can_execute_locally_before_v4"] is False
        assert project["ui_visibility"] == "visible_boundary_only"


def test_provider_and_runtime_boundaries_are_visible():
    projects = {project["project_id"]: project for project in _registry()["projects"]}

    assert "external_runtime_required" in projects["n8n"]["blocked_reasons"]
    assert projects["n8n"]["requires_external_runtime"] is True
    assert "provider_required" in projects["anysearchskill"]["contract_status"]
    assert projects["anysearchskill"]["requires_api_key"] is True
    assert projects["anysearchskill"]["requires_network"] is True
    assert "future_adapter" in projects["llm_wiki_v2"]["contract_status"]
    assert "future_adapter" in projects["weknora"]["contract_status"]
