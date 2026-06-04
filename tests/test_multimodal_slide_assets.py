from heitang_kb_forge.multimodal.slide_assets import make_slide_assets


def test_invalid_pptx_generates_fallback_slide_asset(tmp_path):
    deck = tmp_path / "deck.pptx"
    deck.write_bytes(b"not a real pptx")

    assets, chunks = make_slide_assets(deck)

    assert len(assets) == 1
    assert chunks == []
    assert assets[0].asset_type == "slide"
    assert assets[0].review_required is True
    assert assets[0].extraction_method == "fallback"
