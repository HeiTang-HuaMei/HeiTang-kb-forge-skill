from heitang_kb_forge.retrieval.context_pack import make_context_pack
from tests.v17_helpers import write_sample_package


def test_context_pack_contains_selected_records(tmp_path):
    package = write_sample_package(tmp_path / "package")
    records = [{"retrieval_id": "r1", "asset_type": "chunk", "text": "HeiTang evidence", "keywords": ["heitang", "evidence"]}]

    pack, markdown = make_context_pack(package, records, "HeiTang")

    assert pack["selected_count"] == 1
    assert "Context Pack" in markdown
