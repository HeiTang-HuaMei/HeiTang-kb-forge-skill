# Interview Talk Track

## 30-second version

I built HeiTang KB Forge Skill, an Agent knowledge supply-chain tool. It turns PDF, DOCX, Markdown, tables, images, and other source materials into standardized, auditable, retrievable, and exportable knowledge packages. The goal is to provide a reliable upstream knowledge layer for RAG Agents, recommendation Agents, education Agents, and product-manager Agents.

## 1-minute version

The project started from one problem: many Agent projects fail not only because of the model, but because the knowledge entering the model is not standardized or governed.

HeiTang KB Forge solves this upstream layer. It supports document ingestion, knowledge package generation, quality gates, evidence tracking, LLM provider governance, Agent / Skill export, and a reproducible demo-e2e workflow.

By v2.7, the project can run a local offline demo: build a knowledge package, run quality checks, run provider security checks, perform mock LLM quality assistance, export Agent / Skill packages, and generate a portfolio demo report with an evidence pack.

## 3-minute version

HeiTang KB Forge is positioned as an Agent knowledge supply-chain base, not just a RAG demo or document parser.

The product problem is that enterprises and individual builders often have many documents, but before these documents enter RAG or Agent systems, they lack standardization, traceability, evaluation, and reusable packaging. This causes hallucination risk, poor retrieval quality, and low maintainability.

The solution is a local-first CLI skill. It converts multi-format materials into standard knowledge assets. The system includes quality gates, evidence maps, provider governance, release readiness, and export packages for downstream Agent / Skill use.

The most important design boundary is safety. The default path is offline and mock. Real LLM usage is optional, API keys are environment-only, and outputs must avoid leaking secrets.

The current v2.7 version adds a minimal end-to-end demo. It can generate a portfolio report and evidence pack, which makes the project easier to show in interviews or GitHub.

## Common questions

### Why did you build this?

Because Agent quality depends heavily on upstream knowledge quality. I wanted to build the missing layer between raw documents and downstream Agents.

### How is it different from a normal RAG project?

A normal RAG project often focuses on retrieval and answer generation. HeiTang KB Forge focuses on producing governed knowledge assets before RAG: parsing, quality, evidence, governance, provider safety, export, and demo evidence.

### What is the product value?

It lowers the cost of building reliable Agents by standardizing the knowledge preparation process.

### What is the technical boundary?

It is a local CLI / Skill project. It does not claim SaaS, real platform publishing, or production runtime compatibility by default.

### What would you do next?

I would turn the minimal demo into a clearer product workflow, then selectively add real runtime compatibility checks and domain Skill templates.
