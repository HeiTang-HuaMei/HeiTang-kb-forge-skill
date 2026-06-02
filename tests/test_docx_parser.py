from pathlib import Path

import pytest

from kb_forge.parsers.docx_parser import parse_docx


def test_docx_parser_placeholder_is_explicit():
    path = Path("sample.docx")

    with pytest.raises(NotImplementedError, match="DOCX parsing is reserved for a later version"):
        parse_docx(path)
