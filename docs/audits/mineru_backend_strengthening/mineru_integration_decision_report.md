# MinerU Integration Decision Report

- Status: `pass`
- Decision: `real_integration`
- Current environment: `blocked_by_dependency`
- Dependency status: `missing`
- Runtime status: `skipped`
- Optional extra: `parser-mineru`
- Supported inputs: .bmp, .docx, .jpeg, .jpg, .pdf, .png, .pptx, .tif, .tiff, .xlsx
- Validated inputs: .pdf, .png
- PDF parse: `true`
- Layout blocks: `true`
- Reading order: `true`
- Table / figure / formula metadata: `partial / partial / partial`
- Markdown/JSON normalization: `true`
- Structured skipped when missing: `true`
- Repair: Optional dependency 'mineru' is not installed. Install the parser-mineru extra or use backend=builtin.
