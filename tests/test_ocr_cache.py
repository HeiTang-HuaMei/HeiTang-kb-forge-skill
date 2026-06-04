from heitang_kb_forge.ocr.cache import OCRPageCache, cache_key, pdf_hash


def test_ocr_page_cache_reads_written_page(tmp_path):
    pdf_path = tmp_path / "sample.pdf"
    pdf_path.write_bytes(b"%PDF-1.4 cache fixture")
    cache = OCRPageCache(tmp_path / "cache", pdf_path, "eng", 1.5)

    cache.write(0, "Cached OCR text", 123)

    assert cache.read(0) == "Cached OCR text"
    manifest = cache.manifest()
    assert manifest["page_count"] == 1
    assert manifest["pages"] == ["page_001.txt"]


def test_ocr_cache_key_changes_with_options(tmp_path):
    pdf_path = tmp_path / "sample.pdf"
    pdf_path.write_bytes(b"%PDF-1.4 cache fixture")
    digest = pdf_hash(pdf_path)

    assert cache_key(pdf_digest=digest, page_index=0, ocr_lang="eng", ocr_scale=1.5) != cache_key(
        pdf_digest=digest,
        page_index=1,
        ocr_lang="eng",
        ocr_scale=1.5,
    )
