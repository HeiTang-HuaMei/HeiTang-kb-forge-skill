# Parser Backend Matrix

- Release: v4.1.0
- Runtime baseline commit: `576a62075dc1ecbe00388bb0569fd1fc767be7cb`
- Default heavy dependencies bundled: `false`
- Default Core parser changed: `false`

| Backend | Dependency mode | Acceptance dependency | Runtime invoked | Stable surface | Status |
| --- | --- | --- | --- | --- | --- |
| builtin | default | true | true | .md, .txt | builtin_passed |
| docling | optional_extra | true | true | .md, .txt | real_runtime_integrated |
| paddleocr | optional_extra | true | true | .png | real_runtime_integrated |
| unstructured | optional_extra | true | true | .md, .txt | real_runtime_integrated |
