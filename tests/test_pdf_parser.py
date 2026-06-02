from pathlib import Path

import pytest

from kb_forge.parsers.pdf_parser import parse_pdf


def test_pdf_parser_placeholder_is_explicit():
    path = Path("sample.pdf")

    with pytest.raises(NotImplementedError, match="PDF parsing is reserved for a later version"):
        parse_pdf(path)
