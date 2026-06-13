# OpenDataLoader Integration Decision Report

- Status: `pass`
- Decision: `real_integration`
- Current environment: `blocked_by_dependency`
- Dependency status: `missing`
- Runtime status: `skipped`
- Optional extra: `parser-opendataloader`
- Supported inputs: .pdf
- Validated inputs: .pdf
- PDF conversion: `true`
- Markdown/JSON normalization: `true`
- Layout blocks: `partial`
- Tables: `partial`
- Figures: `partial`
- Reading order: `partial`
- Hybrid mode in default smoke: `false`
- Structured skipped when missing: `true`
- Repair: Optional dependency 'opendataloader-pdf' or Java 11+ is not installed. Install the parser-opendataloader extra, ensure Java is on PATH, or use backend=builtin.
