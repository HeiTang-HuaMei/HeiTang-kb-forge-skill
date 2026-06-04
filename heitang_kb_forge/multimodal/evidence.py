from heitang_kb_forge.schemas.multimodal_schema import MultimodalAsset


def make_multimodal_evidence_map(assets: list[MultimodalAsset], slide_chunks: list[dict]) -> dict:
    return {
        "assets": {
            asset.asset_id: {
                "source_file": asset.source_file,
                "page_number": asset.page_number,
                "slide_number": asset.slide_number,
                "bbox": asset.bbox,
                "evidence_refs": asset.evidence_refs,
                "extraction_method": asset.extraction_method,
                "review_required": asset.review_required,
            }
            for asset in assets
        },
        "chunks": {chunk["chunk_id"]: {"asset_refs": chunk.get("asset_refs", [])} for chunk in slide_chunks},
    }
