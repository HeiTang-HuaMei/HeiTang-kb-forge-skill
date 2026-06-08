from heitang_kb_forge.pre_v4_p0 import run_memory_completion

from tests.p0_helpers import make_p0_package


def test_memory_architecture_completion_proves_short_and_long_term_layers(tmp_path):
    package = make_p0_package(tmp_path)
    report = run_memory_completion(package, tmp_path / "out")

    assert report["status"] == "pass"
    assert report["short_term_session_memory"] is True
    assert report["long_term_summary"] is True
    assert report["long_term_vector_memory"] is True
    assert report["no_all_history_injection"] is True
