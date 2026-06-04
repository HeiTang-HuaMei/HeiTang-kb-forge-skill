from pathlib import Path

from heitang_kb_forge.multimodal.classifier import classify_asset


def test_chart_and_mindmap_filename_classification():
    assert classify_asset(Path("sales_chart.png")) == "chart"
    assert classify_asset(Path("流程图.png")) == "diagram"
    assert classify_asset(Path("思维导图.jpg")) == "mindmap"
