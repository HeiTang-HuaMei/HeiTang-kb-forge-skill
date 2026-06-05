from heitang_kb_forge.governance.review_queue import make_governance_review_queue
from tests.v17_helpers import write_sample_package


def test_review_queue_collects_conflicts_and_stale_chunks(tmp_path):
    package = write_sample_package(tmp_path / "package")

    queue = make_governance_review_queue(
        package,
        {"conflicts": [{"chunk_ids": ["chunk_1"]}]},
        {"stale_chunk_ids": ["chunk_1"]},
    )

    assert {item["reason"] for item in queue} == {"conflict_detected", "stale_content"}
