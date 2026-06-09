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

Current checkpoint: v4.0.0 stable release.

Recent milestones:

- v2.5.1: release engineering, CI, CLI convergence.
- v2.6: real LLM provider governance with domestic / international provider registry.
- v2.7: minimal end-to-end portfolio demo.
- P1: final gate evidence, external project registry visibility, and S/A contract inclusion visibility.

## Boundaries

- Default offline / mock.
- No API key stored on disk.
- No default live network call.
- No real platform publishing.
- No SaaS / permissions / multi-tenant system.
- No claim that all providers or runtimes have been live-tested.

## Value

The project is not a simple file parser. It is a knowledge asset production layer before Agent construction.
