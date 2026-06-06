# Project One-Pager: HeiTang KB Forge Skill

## What it is

HeiTang KB Forge Skill is a local Agent / RAG knowledge supply-chain tool.

It turns multi-format source materials into standardized, auditable, retrievable, evaluable, and exportable knowledge assets for downstream Agents, RAG systems, Skill packages, and demo workflows.

## Problem

Many Agent and RAG projects focus on model calls and chat UI, but the upstream knowledge layer is often weak:

- Documents are not standardized.
- Source evidence is hard to trace.
- Quality checks are inconsistent.
- Knowledge packages are hard to reuse.
- LLM provider access is unsafe or undocumented.
- Demo evidence is difficult to reproduce.

## Solution

HeiTang KB Forge provides a local-first pipeline:

source files → knowledge package → quality gate → evidence / governance → provider security → Agent / Skill export → demo evidence pack.

## Target users

- AI Product Managers building Agent demos.
- Developers preparing RAG / Agent knowledge assets.
- Teams that need auditable local knowledge packages.
- Portfolio projects that need a reproducible end-to-end demo.

## Current version

Current checkpoint: v2.9.0-alpha.1.

Recent milestones:

- v2.5.1: release engineering, CI, CLI convergence.
- v2.6: real LLM provider governance with domestic / international provider registry.
- v2.7: minimal end-to-end portfolio demo.
- v2.8: opt-in parser backend reliability with parse quality, OCR risk, review queue, and trusted KB gate outputs.
- v2.9: opt-in Knowledge Runtime Loop with KB index, query trace, citation trace, cited local answers, low-confidence refusal, retrieval quality, and RAG eval baseline.

## Boundaries

- Default offline / mock.
- No API key stored on disk.
- No default live network call.
- No real platform publishing.
- No SaaS / permissions / multi-tenant system.
- No claim that all providers or runtimes have been live-tested.
- Parser backend mode is opt-in and does not require Docling or Marker by default.
- Draft parser-backed KBs are blocked from Skill, Agent, and platform exports unless explicitly allowed.
- Knowledge runtime mode is opt-in, local, deterministic, and does not call LLM APIs, embedding APIs, vector databases, or external Agent runtimes.

## Value

The project is not a simple file parser. It is a knowledge asset production layer before Agent construction.
