# Progress and Observability

v1.6.2 adds opt-in progress events for local industrial runs.

## Commands

```powershell
heitang-kb-forge build --input .\input --output .\output --progress --progress-jsonl
heitang-kb-forge batch --input .\input --output .\output --progress-jsonl
heitang-kb-forge pipeline --config .\examples\configs\kb_forge.build.yaml --progress-jsonl
```

## Output

`--progress-jsonl` writes `progress_events.jsonl` under the package output directory.

Each event includes:

- `event_id`
- `timestamp`
- `stage`
- `status`
- `message`
- `current_file`
- `current_file_index`
- `total_files`
- `current_page`
- `total_pages`
- `duration_ms`
- `warning`
- `error`
- `output_path`
- `metadata`

## Stages

Progress events cover source scan, parsing, PDF text extraction, PDF preflight, OCR pages, OCR cache hits/writes, cleaning, chunking, offline asset generation, quality report generation, RAG export, Agent Template generation, performance report generation, batch items, and completion.

## Boundaries

Progress is observability only. It does not replace CLI behavior, config execution, pipeline execution, output contracts, or Agent-callable Skill usage.
