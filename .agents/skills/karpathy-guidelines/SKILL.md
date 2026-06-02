---
name: karpathy-guidelines
description: Use when writing, reviewing, debugging, or refactoring code to reduce common LLM coding mistakes. Enforces thinking before coding, simplicity, surgical changes, and verifiable success criteria.
---

# Karpathy Guidelines

Behavioral guidelines to reduce common LLM coding mistakes.

## 1. Think Before Coding

Do not assume. Do not hide confusion. Surface tradeoffs.

Before implementing:

* State assumptions explicitly.
* If uncertain, ask.
* If multiple interpretations exist, present them instead of choosing silently.
* If a simpler approach exists, say so.
* If something is unclear, stop and ask.

## 2. Simplicity First

Use the minimum code that solves the problem.

Rules:

* No features beyond what was asked.
* No abstractions for single-use code.
* No flexibility or configurability that was not requested.
* No error handling for unrealistic scenarios.
* If 200 lines could be 50, simplify.

## 3. Surgical Changes

Touch only what is necessary.

Rules:

* Do not improve adjacent code, comments, or formatting.
* Do not refactor unrelated code.
* Match existing style.
* Mention unrelated dead code, but do not delete it.
* Remove only imports, variables, functions, or files made unused by your changes.

Every changed line should trace directly to the user request.

## 4. Goal-Driven Execution

Define success criteria and verify them.

For implementation tasks:

* Define a short plan before editing.
* Each step should include a validation method.
* If fixing a bug, reproduce it first when practical.
* If adding validation, add or update tests.
* If refactoring, ensure behavior is unchanged.

After editing, report:

* Files changed
* Validation run
* Remaining risks
