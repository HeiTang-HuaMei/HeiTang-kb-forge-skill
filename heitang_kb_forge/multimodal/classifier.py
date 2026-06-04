from pathlib import Path


IMAGE_SUFFIXES = {".png", ".jpg", ".jpeg", ".webp", ".bmp", ".tiff", ".tif"}
SLIDE_SUFFIXES = {".ppt", ".pptx"}
ASSET_TYPES = {"image", "screenshot", "chart", "slide", "formula", "diagram", "mindmap", "mixed"}


def classify_asset(path: Path, text: str = "") -> str:
    value = f"{path.stem} {text}".lower()
    if any(token in value for token in ["mindmap", "思维导图"]):
        return "mindmap"
    if any(token in value for token in ["flowchart", "diagram", "流程图"]):
        return "diagram"
    if any(token in value for token in ["chart", "graph", "图表"]):
        return "chart"
    if any(token in value for token in ["formula", "equation", "公式"]):
        return "formula"
    if path.suffix.lower() in SLIDE_SUFFIXES:
        return "slide"
    return "image"
