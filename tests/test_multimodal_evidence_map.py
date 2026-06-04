from heitang_kb_forge.multimodal.evidence import make_multimodal_evidence_map
from heitang_kb_forge.multimodal.image_assets import make_image_asset


def test_multimodal_evidence_map_contains_assets_and_slide_chunks(tmp_path):
    image = tmp_path / "diagram.png"
    image.write_bytes(b"fake image")
    asset = make_image_asset(image)
    chunk = {"chunk_id": "slide_chunk_1", "asset_refs": [asset.asset_id]}

    evidence = make_multimodal_evidence_map([asset], [chunk])

    assert asset.asset_id in evidence["assets"]
    assert evidence["chunks"]["slide_chunk_1"]["asset_refs"] == [asset.asset_id]
