from __future__ import annotations

from pathlib import Path

from heitang_kb_forge.parser_backends.base import ParserBackend, ParserBackendRecord
from heitang_kb_forge.parser_backends.normalize import column_safe_path, normalize_text, source_type
from heitang_kb_forge.parsers.docx_parser import parse_docx
from heitang_kb_forge.parsers.hardening import parse_epub, parse_html, parse_zip
from heitang_kb_forge.parsers.image_parser import parse_image
from heitang_kb_forge.parsers.markdown_parser import parse_markdown
from heitang_kb_forge.parsers.pdf_parser import parse_pdf
from heitang_kb_forge.parsers.slide_parser import parse_slide
from heitang_kb_forge.parsers.table_parser import parse_csv, parse_tsv, parse_xlsx
from heitang_kb_forge.parsers.text_parser import parse_text


BUILTIN_PARSERS = {
    ".md": parse_markdown,
    ".markdown": parse_markdown,
    ".txt": parse_text,
    ".html": parse_html,
    ".htm": parse_html,
    ".pdf": parse_pdf,
    ".docx": parse_docx,
    ".csv": parse_csv,
    ".tsv": parse_tsv,
    ".xlsx": parse_xlsx,
    ".epub": parse_epub,
    ".zip": parse_zip,
    ".png": parse_image,
    ".jpg": parse_image,
    ".jpeg": parse_image,
    ".ppt": parse_slide,
    ".pptx": parse_slide,
}


class BuiltinParserBackend(ParserBackend):
    name = "builtin"
    version = "2.8.0-alpha.1"
    description = "KB Forge built-in parsers normalized into the parser backend contract."

    def parse_source(self, path: Path, command: str) -> ParserBackendRecord:
        parser = BUILTIN_PARSERS.get(path.suffix.lower())
        if parser is None:
            return ParserBackendRecord(
                source_path=column_safe_path(path),
                source_type=source_type(path),
                backend_name=self.name,
                backend_version=self.version,
                command=command,
                status="unsupported",
                warnings=[f"unsupported_extension:{path.suffix.lower()}"],
                confidence=0.0,
            )
        try:
            text = normalize_text(parser(path))
        except Exception as exc:
            return ParserBackendRecord(
                source_path=column_safe_path(path),
                source_type=source_type(path),
                backend_name=self.name,
                backend_version=self.version,
                command=command,
                status="failed",
                warnings=[f"parse_failed:{exc}"],
                confidence=0.0,
            )
        warnings = []
        confidence = 0.95
        if not text:
            warnings.append("empty_text")
            confidence = 0.0
        elif path.suffix.lower() in {".png", ".jpg", ".jpeg"}:
            warnings.append("ocr_text_requires_review")
            confidence = 0.7
        return ParserBackendRecord(
            source_path=column_safe_path(path),
            source_type=source_type(path),
            backend_name=self.name,
            backend_version=self.version,
            command=command,
            status="success" if text else "empty",
            text=text,
            warnings=warnings,
            confidence=confidence,
            metadata={"adapter": "builtin"},
        )

