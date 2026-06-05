from zipfile import ZipFile

from heitang_kb_forge.parsers.hardening import parse_zip


def test_zip_ingestion_extracts_supported_inner_files(tmp_path):
    path = tmp_path / "sample.zip"
    with ZipFile(path, "w") as archive:
        archive.writestr("001_note.md", "KB Forge ZIP Fixture")
        archive.writestr("image.bin", b"ignored")

    text = parse_zip(path)

    assert "ZIP Source: 001_note.md" in text
    assert "KB Forge ZIP Fixture" in text
