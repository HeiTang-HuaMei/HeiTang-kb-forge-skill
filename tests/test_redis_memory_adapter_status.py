from heitang_kb_forge.pre_v4_p0 import run_memory_completion

from tests.p0_helpers import make_p0_package, read_json


def test_redis_memory_adapter_status_is_truthful_without_required_service(tmp_path):
    package = make_p0_package(tmp_path)
    output = tmp_path / "out"

    run_memory_completion(package, output)
    report = read_json(output / "redis_memory_adapter_status_report.json")

    assert report["adapter_config_status"] == "implemented"
    assert report["status"] == "implemented_needs_live_acceptance"
    assert report["service_verified"] is False
