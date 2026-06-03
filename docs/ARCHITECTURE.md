# Architecture

## Pipeline

```text
source files
-> parser
-> cleaner
-> chunker
-> offline extractor
-> quality report
-> optional LLM
-> optional LLM quality
-> optional RAG export
-> optional embedding / vector export
-> optional Agent Template
-> optional validation / downstream export
```

## Parser Layer

Parsers return plain text. PDF, OCR, DOCX, and table-specific extraction converts structured or visual content into readable text before it enters the existing clean / chunk / extractor pipeline.

The chunk schema is unchanged in v1.0.0.

## Quality And Grounding

The project reduces hallucination risk through source grounding rather than an Agent Runtime:

- `source_path`
- `chunk_id`
- `citation`
- `quality_report.json`
- `llm_quality_report.json`
- `package_validation_report.json`

## Runtime Boundary

Generated Agent Template, RAG, embedding, vector, and downstream files are handoff artifacts. They do not execute tools, deploy agents, write to external vector databases, or call external services by default.
