from __future__ import annotations

import zipfile
from pathlib import Path


def validate_exports(files: dict[str, Path]) -> dict:
    results = {}
    for fmt, path in files.items():
        results[fmt] = _validate_file(fmt, path)
    status = "pass" if all(item["status"] == "pass" for item in results.values()) else "fail"
    return {"export_validation_version": "3.0.0-alpha.1", "status": status, "files": results}


def _validate_file(fmt: str, path: Path) -> dict:
    if not path.exists() or path.stat().st_size == 0:
        return {"status": "fail", "path": str(path), "reason": "missing_or_empty"}
    if fmt == "md":
        text = path.read_text(encoding="utf-8", errors="ignore")
        ok = "## Source Evidence Appendix" in text and "[" in text
        return {"status": "pass" if ok else "fail", "path": str(path), "bytes": path.stat().st_size}
    if fmt == "pdf":
        header = path.read_bytes()[:8]
        return {"status": "pass" if header.startswith(b"%PDF-") else "fail", "path": str(path), "bytes": path.stat().st_size}
    if fmt == "docx":
        return _validate_zip(path, {"[Content_Types].xml", "word/document.xml"})
    if fmt == "pptx":
        return _validate_zip(path, {"[Content_Types].xml", "ppt/presentation.xml", "ppt/slides/slide1.xml"})
    return {"status": "fail", "path": str(path), "reason": f"unknown_format:{fmt}"}


def _validate_zip(path: Path, required: set[str]) -> dict:
    try:
        with zipfile.ZipFile(path) as archive:
            names = set(archive.namelist())
    except zipfile.BadZipFile:
        return {"status": "fail", "path": str(path), "reason": "invalid_zip"}
    missing = sorted(required - names)
    return {
        "status": "pass" if not missing else "fail",
        "path": str(path),
        "bytes": path.stat().st_size,
        "missing": missing,
    }
