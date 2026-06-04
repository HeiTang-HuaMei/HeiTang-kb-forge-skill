from heitang_kb_forge.contracts.package_contract_v2 import MANIFEST_FIELDS, REQUIRED_FILES


def test_package_contract_v2_defines_required_files_and_manifest_fields():
    assert "manifest.json" in REQUIRED_FILES
    assert "chunks.jsonl" in REQUIRED_FILES
    assert "evidence_map.json" in REQUIRED_FILES
    assert "contract_version" in MANIFEST_FIELDS
    assert "multimodal_status" in MANIFEST_FIELDS
