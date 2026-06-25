from heitang_kb_forge.model_pool_router import route_model_pool
from tests.v17_helpers import read_json


def test_model_pool_router_selects_best_offline_candidate(tmp_path):
    report = route_model_pool(
        [
            {
                "model_id": "mock_general",
                "provider_id": "mock_default",
                "provider_type": "mock",
                "model_name": "mock-model",
                "capabilities": ["chat", "reasoning"],
                "priority": 20,
            },
            {
                "model_id": "mock_fast",
                "provider_id": "mock_default",
                "provider_type": "mock",
                "model_name": "mock-fast",
                "capabilities": ["chat", "reasoning"],
                "priority": 10,
            },
        ],
        {"task_type": "answer", "required_capabilities": ["chat"], "allow_network": False},
        tmp_path,
    )

    persisted = read_json(tmp_path / "model_pool_router_basic_report.json")
    assert report.status == "passed"
    assert report.selected_model_id == "mock_fast"
    assert report.failed_checks == []
    assert persisted["schema_version"] == "model_pool_router_basic.v1"
    assert persisted["boundary"]["default_network"] == "forbidden"
    assert persisted["boundary"]["provider_api_call"] == "not_required"


def test_model_pool_router_respects_preferred_provider():
    report = route_model_pool(
        [
            {
                "model_id": "mock_general",
                "provider_id": "mock_default",
                "capabilities": ["chat"],
                "priority": 1,
            },
            {
                "model_id": "local_stub_reasoner",
                "provider_id": "local_stub",
                "provider_type": "local_stub",
                "capabilities": ["chat"],
                "priority": 99,
            },
        ],
        {"task_type": "answer", "required_capabilities": ["chat"], "preferred_provider_id": "local_stub"},
    )

    assert report.status == "passed"
    assert report.selected_provider_id == "local_stub"
    assert report.routing_trace[0]["status"] == "skipped"
    assert "not_preferred_provider" in report.routing_trace[0]["reasons"]


def test_model_pool_router_blocks_network_candidate_by_default():
    report = route_model_pool(
        [
            {
                "model_id": "external_model",
                "provider_id": "external",
                "provider_type": "openai_compatible",
                "capabilities": ["chat"],
                "network_required": True,
                "priority": 1,
            }
        ],
        {"task_type": "answer", "required_capabilities": ["chat"], "allow_network": False},
    )

    assert report.status == "failed"
    assert report.selected_model_id is None
    assert "no_eligible_model" in report.failed_checks
    assert "network_not_allowed" in report.routing_trace[0]["reasons"]


def test_model_pool_router_reports_missing_capability():
    report = route_model_pool(
        [
            {
                "model_id": "mock_text",
                "provider_id": "mock_default",
                "capabilities": ["chat"],
            }
        ],
        {"task_type": "vision_check", "required_capabilities": ["vision"], "allow_network": False},
    )

    assert report.status == "failed"
    assert report.selected_model_id is None
    assert "required_capability_unavailable" in report.failed_checks
    assert "missing_required_capability" in report.routing_trace[0]["reasons"]
