from __future__ import annotations

import json
from hashlib import sha256
from pathlib import Path
from typing import Any


OCR_PARSER_VERSION = "1.6.2"


def pdf_hash(path: Path) -> str:
    digest = sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def cache_key(*, pdf_digest: str, page_index: int, ocr_lang: str, ocr_scale: float) -> str:
    payload = f"{pdf_digest}:{page_index}:{ocr_lang}:{ocr_scale}:{OCR_PARSER_VERSION}"
    return sha256(payload.encode("utf-8")).hexdigest()


class OCRPageCache:
    def __init__(self, cache_dir: Path, source_pdf: Path, ocr_lang: str, ocr_scale: float) -> None:
        self.pdf_digest = pdf_hash(source_pdf)
        self.ocr_lang = ocr_lang
        self.ocr_scale = ocr_scale
        self.root = cache_dir / self.pdf_digest
        self.root.mkdir(parents=True, exist_ok=True)

    def read(self, page_index: int) -> str | None:
        text_path, meta_path = self._paths(page_index)
        if not text_path.exists() or not meta_path.exists():
            return None
        meta = json.loads(meta_path.read_text(encoding="utf-8"))
        if meta.get("cache_key") != self._key(page_index):
            return None
        return text_path.read_text(encoding="utf-8")

    def write(self, page_index: int, text: str, duration_ms: int) -> dict[str, Any]:
        text_path, meta_path = self._paths(page_index)
        text_path.write_text(text, encoding="utf-8")
        meta = {
            "pdf_hash": self.pdf_digest,
            "page_index": page_index,
            "ocr_lang": self.ocr_lang,
            "ocr_scale": self.ocr_scale,
            "parser_version": OCR_PARSER_VERSION,
            "cache_key": self._key(page_index),
            "duration_ms": duration_ms,
        }
        meta_path.write_text(json.dumps(meta, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        self._write_manifest()
        return meta

    def manifest(self) -> dict[str, Any]:
        pages = sorted(path.name for path in self.root.glob("page_*.txt"))
        return {
            "ocr_cache_manifest_version": "1.6.2",
            "pdf_hash": self.pdf_digest,
            "page_count": len(pages),
            "pages": pages,
        }

    def _write_manifest(self) -> None:
        (self.root / "ocr_cache_manifest.json").write_text(
            json.dumps(self.manifest(), ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )

    def _paths(self, page_index: int) -> tuple[Path, Path]:
        page_no = page_index + 1
        return self.root / f"page_{page_no:03d}.txt", self.root / f"page_{page_no:03d}.meta.json"

    def _key(self, page_index: int) -> str:
        return cache_key(pdf_digest=self.pdf_digest, page_index=page_index, ocr_lang=self.ocr_lang, ocr_scale=self.ocr_scale)
