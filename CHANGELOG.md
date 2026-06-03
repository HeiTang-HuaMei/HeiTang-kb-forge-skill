# Changelog

## v0.2.1

- Added `--merge-same-sequence` for batch.
- Added same-sequence multi-file merge.
- Added group-level output directories like `output/001/`.
- Added `merge_same_sequence` and `total_groups` in `batch_manifest.json`.
- Added `source_paths` and `source_count` for merge items.
- Added `Group Source Files` section in `batch_report.md`.
- Preserved default batch behavior.
- Preserved `build` behavior.
- Tests passed: 14 passed.

## v0.2.0

- Added `batch` command.
- Added numbered file batch processing.
- Added independent package output per source file.
- Added `batch_manifest.json`.
- Added `batch_report.md`.
- Added per-file failure isolation.
- Preserved existing `build` behavior.
- Tests passed: 12 passed.
