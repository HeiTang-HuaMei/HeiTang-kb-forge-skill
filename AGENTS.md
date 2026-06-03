# Codex Project Rules

## Working Principles

For all non-trivial coding tasks, follow these four principles:

1. Think before coding.
2. Prefer simplicity.
3. Make surgical changes only.
4. Execute toward verifiable goals.

## Required Behavior

Before editing:

* Restate the goal briefly.
* State assumptions and ambiguities.
* Propose the smallest safe plan.
* Ask if the task is unclear.

While editing:

* Modify only the files required by the task.
* Do not refactor unrelated code.
* Do not add features that were not requested.
* Match the existing project style.
* Remove only code made obsolete by the current change.

After editing:

* Run the narrowest relevant validation when practical.
* Report changed files, validation run, and remaining risks.

## Project Constraints

This project is HeiTang KB Forge Skill.

MVP scope:

* Markdown parsing
* TXT parsing
* Cleaning
* Chunking
* JSONL export
* Manifest export
* Ingest report
* Basic tests

Do not implement yet:

* Vector database integration
* External LLM calls
* Web UI
* Agent orchestration
* Full PDF/DOCX parsing beyond clear placeholders

## Validation Commands

For parser/chunker/validator changes, prefer:

pytest tests/test_chunker.py
pytest tests/test_validator.py

For CLI changes, verify:

heitang-kb-forge build --input ./examples/input --output ./examples/output --domain education --mode teaching
