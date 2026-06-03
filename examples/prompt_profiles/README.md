# Prompt Profile Examples

This directory contains example prompt profiles for future LLM Prompt Profile support.

These files are preparation materials for future prompt-profile-driven LLM extraction.

## Files

### product_manager.yaml

Designed for extracting product-management knowledge assets, such as:

- demand analysis
- user scenarios
- PRD structure
- metrics
- competitor analysis

### shopping_guide.yaml

Designed for extracting shopping-guide knowledge assets, such as:

- product attributes
- selling points
- target users
- comparisons
- recommendation reasons

### education_tutor.yaml

Designed for extracting education-tutor knowledge assets, such as:

- concepts
- explanations
- mistakes
- learning paths
- practice questions

## Current Status

These files are examples only.

They are not wired into the LLM extractor yet. Current LLM extraction is still controlled by existing CLI options:

- --llm
- --llm-provider
- --llm-model
- --llm-cache
- --llm-strict

## Intended Future Usage

A future version may support PowerShell commands such as:

    python -m heitang_kb_forge.cli build --input .\input --output .\output --llm --prompt-profile .\examples\prompt_profiles\product_manager.yaml

## Design Principle

Prompt profiles should guide extraction style and asset preference, but they must not override source grounding.

The extractor should still follow these rules:

- do not invent unsupported facts
- keep outputs grounded in source chunks
- preserve source_path, chunk_id, citation, provider, model, token_usage, and cache_key metadata
- return empty results when source evidence is insufficient
