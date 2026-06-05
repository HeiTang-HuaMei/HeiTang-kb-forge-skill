from heitang_kb_forge.governance.lifecycle import make_lifecycle_manifest
from tests.v17_helpers import write_sample_package


def test_lifecycle_manifest_counts_stale_chunks(tmp_path):
    package = write_sample_package(tmp_path / "package")

    manifest = make_lifecycle_manifest(package, {"chunk_1"})

    assert manifest.stale_count == 1
    assert manifest.review_required_count == 1
