# KB Forge Skill

Use this skill to generate a local, standardized knowledge base package from source documents.

## What V0 Does

- Reads Markdown and TXT files.
- Cleans whitespace and line endings.
- Creates stable semantic-ish text chunks from paragraphs.
- Generates simple knowledge cards, QA pairs, and glossary rows without external LLMs.
- Validates chunks for empty text, duplicate text, and missing required fields.
- Writes UTF-8 JSONL, JSON, and Markdown report outputs.

## Command

```bash
kb-forge build --input ./examples/input --output ./examples/output --domain education --mode teaching
```

PDF and DOCX parser interfaces are present but intentionally not implemented in V0.
