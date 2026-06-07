# HeiTang Knowledge Workbench Version Plan

## Baseline

Current repository status:

- v2.5.1: release engineering and CLI convergence
- v2.6.0-alpha.1: provider governance and mock/live boundary
- v2.7.0-alpha.1: minimal end-to-end demo
- v2.8.0-alpha.1: parser backend and knowledge reliability checkpoint
- v2.9.0-alpha.1: local Knowledge Runtime Loop checkpoint
- portfolio documentation
- Agent / KB answer policy documentation

Current product position:

HeiTang KB Forge Core is the knowledge supply-chain core Skill. It is not the full Workbench product.

## Final Product Direction

HeiTang Knowledge Workbench will support:

- multiple knowledge bases
- multiple Agents
- multi-model routing
- multi-Agent workflows
- isolated Agent memory
- workflow shared memory
- knowledge asset production
- grounded KB Q&A
- document generation
- knowledge-bound Agent / Skill generation
- external Skill reverse engineering and fusion
- local Workbench UI

## Version Roadmap

### v2.8 Parser Backend & Knowledge Reliability

Solve parser reliability.

Deliver:

- Docling optional backend
- Marker optional backend
- parse compare
- parse quality gate
- review queue
- corrected text re-import
- before/after quality diff

### v2.9 Knowledge Runtime Loop

Solve KB usage.

Deliver:

- kb-index
- kb-query
- kb-answer
- citations
- low-confidence refusal
- query trace
- RAG eval baseline

### v3.0 Document Generation Loop

Solve file generation.

Deliver:

- Markdown
- DOCX
- PDF
- PPTX
- templates
- citations
- export validation

### v3.1 Agent / Skill Factory

Solve two first-class Agent creation modes: KB-bound Agents and standalone Agents.

Deliver:

- `mode: kb_bound`
- `mode: standalone`
- Agent / Skill generation
- KB binding for KB-bound Agents
- retrieval binding for KB-bound Agents
- standalone Agent package generation without requiring a KB
- capabilities, tools, memory, output contract, answer policy, refusal policy, and eval cases for standalone Agents
- provider binding
- answer policy
- smoke test report
- validation report

### v3.2 Multi-KB & Multi-Agent Orchestration

Solve multi-KB and multi-Agent workflows across both KB-bound and standalone Agents.

Deliver:

- multi-KB registry
- agent registry
- `mode: kb_bound | standalone` in agent registry
- model routing
- route KB questions to trusted KB-bound Agents
- route planning/process/coach tasks to standalone Agents
- workflow definition
- orchestrator agent
- handoff protocol
- memory isolation
- workflow shared memory
- trace report

### v3.3 Skill Reverse & Fusion

Solve external Skill analysis and fusion.

Deliver:

- import Skill
- analyze Skill
- capability map
- prompt pattern map
- fusion plan
- fused Skill
- validation report

### v3.4 Local Knowledge Workbench UI

Solve productization.

Deliver:

- local UI
- upload
- job queue
- progress dashboard
- KB browser
- review queue
- query UI
- doc generation UI
- Agent/Skill UI
- memory viewer
- export center

### v3.5 Product Hardening & Installer

Solve installability and stability.

Deliver:

- installer
- doctor
- retry
- resume
- backup / restore
- demo mode
- release candidate checklist
