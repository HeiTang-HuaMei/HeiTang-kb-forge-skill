# kb-forge-skill V1 Parser Plan

## V1 Goal

Add lightweight PDF and DOCX text extraction while preserving the V0 CLI build flow and output contract.

## Supported Scope

V1 parser work should support text-based PDF and DOCX files only.

The parser output should be plain text suitable for the existing cleaner, chunker, validator, and exporters.

## Non-Scope

V1 should not include:

* OCR for scanned PDFs or images
* Complex table structure reconstruction
* Image content parsing
* External LLM extraction
* Vector database integration
* CLI flow redesign

## Recommended Dependencies

Prefer small, well-maintained parsing libraries:

* PDF: `pypdf` for text-based PDF extraction
* DOCX: `python-docx` for paragraph-oriented DOCX text extraction

Keep these dependencies optional or clearly documented until the implementation is added.

## Test Strategy

Start with parser-level tests before changing the CLI flow:

* Preserve V0 behavior while parser placeholders remain.
* Add fixture files only when real parsing is implemented.
* Cover text extraction from simple text-based PDF files.
* Cover paragraph extraction from simple DOCX files.
* Cover unsupported or empty documents with clear errors or empty-text handling.
* Keep the existing output contract test passing for Markdown/TXT input.

Run the full test suite after parser changes:

* python -m pytest
