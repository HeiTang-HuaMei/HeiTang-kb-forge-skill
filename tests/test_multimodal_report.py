from heitang_kb_forge.multimodal.report import make_multimodal_report
from heitang_kb_forge.multimodal.image_assets import make_image_asset


def test_multimodal_report_handles_empty_and_review_required(tmp_path):
    assert "No multimodal assets found." in make_multimodal_report([])
    image = tmp_path / "chart.png"
    image.write_bytes(b"fake image")
    report = make_multimodal_report([make_image_asset(image)])
    assert "Review required: 1" in report
    assert "chart" in report
