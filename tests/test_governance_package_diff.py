from heitang_kb_forge.governance.package_diff import make_package_diff
from tests.v17_helpers import write_sample_package


def test_package_diff_detects_changed_chunks(tmp_path):
    old = write_sample_package(tmp_path / "old", "Old supported content.")
    new = write_sample_package(tmp_path / "new", "New supported content.")

    diff = make_package_diff(new, old)

    assert diff.changed == ["chunk_1"]
    assert diff.added == []
