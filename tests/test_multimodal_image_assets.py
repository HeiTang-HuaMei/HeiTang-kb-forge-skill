from heitang_kb_forge.multimodal.image_assets import make_image_asset


def test_image_file_generates_review_required_asset(tmp_path):
    image_path = tmp_path / "example.png"
    image_path.write_bytes(b"fake image")

    asset = make_image_asset(image_path)

    assert asset.asset_type == "image"
    assert asset.source_file.endswith("example.png")
    assert asset.confidence == "low"
    assert asset.review_required is True
