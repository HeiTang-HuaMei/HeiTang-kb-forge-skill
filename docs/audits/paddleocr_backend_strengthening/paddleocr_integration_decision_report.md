# PaddleOCR Integration Decision Report

- Status: `pass`
- Decision: `real_integration`
- Current environment: `blocked_by_dependency`
- Dependency status: `missing`
- Runtime status: `skipped`
- Optional extra: `parser-paddleocr`
- Supported inputs: .bmp, .jpeg, .jpg, .pdf, .png, .tif, .tiff
- Validated inputs: .pdf, .png
- Image OCR: `true`
- Scanned PDF page OCR: `true`
- Structured skipped when missing: `true`
- Repair: Optional dependency 'paddleocr' is not installed. Install the parser-paddleocr extra or use backend=builtin.
