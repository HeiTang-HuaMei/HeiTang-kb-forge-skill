from heitang_kb_forge.retrieval.index_builder import build_retrieval_index, build_retrieval_outputs
from tests.v17_helpers import read_json, write_sample_package


def test_retrieval_index_contains_package_assets(tmp_path):
    package = write_sample_package(tmp_path / "package")

    records = build_retrieval_index(package)

    assert {"chunk", "card", "qa_pair", "glossary"}.issubset({record.asset_type for record in records})
    assert all(record.citation for record in records)


def test_retrieval_outputs_write_manifest(tmp_path):
    package = write_sample_package(tmp_path / "package")
    output = tmp_path / "retrieval"

    build_retrieval_outputs(package, output, "HeiTang evidence")

    assert read_json(output / "retrieval_manifest.json")["total_records"] >= 4
    assert (output / "context_pack.md").exists()
