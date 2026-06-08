from heitang_kb_forge.pre_v4_p0 import run_vector_db_completion
from heitang_kb_forge.pre_v4_p0.vector_db import FORBIDDEN_PROVIDER_STATUS, VECTOR_PROVIDERS
from tests.p0_helpers import read_json


def test_vector_db_completion_writes_adapter_matrix_without_forbidden_statuses(tmp_path):
    report = run_vector_db_completion(tmp_path)

    assert report["status"] == "pass"
    assert set(report["provider_statuses"]) == set(VECTOR_PROVIDERS)
    assert not set(report["provider_statuses"].values()).intersection(FORBIDDEN_PROVIDER_STATUS)

    matrix = read_json(tmp_path / "vector_db_adapter_matrix.json")
    assert {item["provider"] for item in matrix["providers"]} == set(VECTOR_PROVIDERS)
    for item in matrix["providers"]:
        assert item["offline_contract_status"] == "implemented_offline_contract_tested"
        assert item["supports_upsert"] is True
        assert item["supports_query"] is True
        assert item["supports_metadata_filter"] is True
        assert item["supports_delete_update_by_source_or_package"] is True
        assert item["supports_stale_index_detection"] is True


def test_vector_db_reports_cover_redaction_filter_update_delete_and_errors(tmp_path):
    run_vector_db_completion(tmp_path)

    assert read_json(tmp_path / "vector_db_credential_redaction_report.json")["secret_values_written"] is False
    assert read_json(tmp_path / "vector_db_metadata_filter_report.json")["status"] == "pass"
    assert read_json(tmp_path / "vector_db_delete_update_report.json")["status"] == "pass"
    errors = read_json(tmp_path / "vector_db_error_taxonomy_report.json")
    assert errors["status"] == "pass"
    assert {item["error_id"] for item in errors["errors"]} >= {
        "vector_provider_env_missing",
        "vector_client_missing",
        "vector_live_acceptance_not_run",
    }
