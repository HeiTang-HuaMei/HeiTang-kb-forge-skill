# Backend Capability Boundaries

- Docling, PaddleOCR, and Unstructured are real optional local runtime adapters.
- They are dependency-gated, not bundled, not default Core parsing, and not static Workbench executable controls.
- Unstructured stable surface for v4.1.0 is `.md/.txt`; PDF/DOCX/image extras are future hardening.

## builtin

- Best-effort OCR/image extraction still requires review.
- Not a replacement for optional layout/OCR runtimes.

## docling

- P2.1 live acceptance proves Docling runtime invocation on Markdown/TXT samples only.
- Docling adapter declares broader document extensions, but PDF/DOCX/HTML/PPTX must be revalidated before stable claims.
- Docling is not bundled and is not default Core parsing.

## paddleocr

- P2.1 live acceptance proves OCR runtime invocation on a PNG sample.
- PDF/TIFF/JPEG support remains adapter-declared but not universally stable for this release.
- PaddleOCR and model files are not bundled in the default install.

## unstructured

- Stable P2.1 surface is explicitly limited to .md/.txt.
- PDF/DOCX/image extras are future hardening and are not claimed stable in v4.1.0.
- Unstructured is not bundled and is not default Core parsing.
