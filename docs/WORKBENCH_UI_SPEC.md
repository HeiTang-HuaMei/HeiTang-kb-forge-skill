# HeiTang Knowledge Workbench UI Spec

Status: UI-v0.1 through UI-v0.5 prototype plus v4.1.0 Parser/OCR evidence sync and v4.1.1 validation governance. This spec defines a fixture-backed product surface and reserves runtime Core integration for explicit bridge/service layers.

## Scope

- Build a web-first Knowledge Workbench prototype with static HTML, CSS, and JavaScript.
- Provide a Flutter scaffold under `web/workbench/flutter_app/` for Windows desktop, Web/PWA, Android, and iOS targets.
- Use only `examples/ui_mock_data/*.json` as data sources.
- Keep parser, RAG, document generation, agent orchestration, and memory runtime logic out of scope.
- Display P2.1 parser backend matrix evidence from copied Core fixtures without executing parser/OCR runtimes.
- Reserve future API replacement at `web/workbench/src/mockService.js`.
- Do not import Core pipeline modules from Flutter UI scaffold files.

## Design System

- Visual style: minimal black, white, and gray.
- Brand: `黑糖 HeiTang` must be visible in the shell.
- Brand assets: black cat head and black tiger head SVG assets must exist under `web/workbench/flutter_app/assets/brand/`.
- Layout: fixed desktop sidebar, sticky topbar, card grids, compact tables, and soft bordered panels.
- Controls: rounded buttons, segmented language switcher, icon theme toggle, form fields, status pills, and progress bars.
- Typography: system sans-serif, neutral hierarchy, no decorative display treatment.
- Theme: light and dark mode via CSS variables and `body[data-theme]`.
- Density: operational dashboard layout with clear spacing and no colorful clutter.

## Navigation

1. Dashboard
2. File upload
3. Job progress
4. Knowledge base list
5. Knowledge base detail
6. Review queue
7. Corrected text editor
8. KB query
9. Document generation
10. Agent / Skill management
11. Multi-agent workflow
12. Memory scope viewer
13. Settings
14. Export center

## Page Contracts

### Dashboard

Shows summary metrics for knowledge bases, trusted/draft state, agents, review risks, current jobs, and provider readiness.

Mock sources: `knowledge_bases.json`, `agents.json`, `jobs.json`, `review_queue.json`, `provider_status.json`, `parser_backends/parser_backend_matrix.json`.

### File Upload

Shows a mock dropzone and parser readiness. Upload actions are visual only and must not call parser backends.

Mock sources: `parser_backend_status.json`, `parser_backends/parser_backend_matrix.json`, `jobs.json`.

Parser backend matrix display rules:

- Builtin: preserved fallback.
- Docling: real runtime integrated, optional dependency gated, stable surface limited to release evidence.
- PaddleOCR: real runtime integrated, optional dependency gated, stable PNG OCR evidence.
- Unstructured: real runtime integrated, optional dependency gated, stable `.md/.txt` surface only.
- Static Web and Flutter Workbench surfaces must not display parser/OCR runtime execution controls.
- Flutter renders the matrix as dashboard summary cards, boundary callouts, a data table, backend detail panels, and audit evidence rows.

### Job Progress

Shows ingestion, review, and export jobs with stage status and progress.

Mock sources: `jobs.json`.

### Knowledge Base List

Shows multiple knowledge bases, including draft and trusted status, bound agents, answer policy, and chunk counts.

Mock sources: `knowledge_bases.json`, `agents.json`.

### Knowledge Base Detail

Shows one KB contract with documents, chunks, trust state, parser backend, answer policy, and bound agents.

Mock sources: `knowledge_bases.json`, `agents.json`.

### Review Queue

Shows risk-labelled review items with source, reason, status, and assignee context.

Mock sources: `review_queue.json`, `knowledge_bases.json`.

### Corrected Text Editor

Shows a mock editor for corrected text and review actions. The editor writes no runtime state.

Mock sources: `review_queue.json`.

### KB Query

Shows a mock grounded query response with citation tags and answer policy context.

Mock sources: `knowledge_bases.json`, `answer_policies.json`.

### Document Generation

Shows generated document drafts, citation counts, agent ownership, and preview/export readiness.

Mock sources: `generated_docs.json`, `agents.json`, `knowledge_bases.json`.

### Agent / Skill Management

Shows agent status, model provider, tools, KB binding, answer policy, and private memory scope.

Mock sources: `agents.json`, `knowledge_bases.json`, `provider_status.json`.

### Multi-Agent Workflow

Shows workflow steps, workflow shared memory, participating agents, and handoff trace.

Mock sources: `workflows.json`, `agents.json`, `memory_scopes.json`.

### Memory Scope Viewer

Shows agent-private memory and workflow-shared memory isolation.

Mock sources: `memory_scopes.json`, `agents.json`, `workflows.json`.

### Settings

Shows provider status, parser backend status, answer policy, and memory policy as mock configuration.

Mock sources: `provider_status.json`, `parser_backend_status.json`, `parser_backends/parser_backend_matrix.json`, `answer_policies.json`.

### Export Center

Shows export package items and generated-document exports.

Mock sources: `generated_docs.json`.

## Mock Data Contract

The UI consumes these files only:

- `knowledge_bases.json`
- `agents.json`
- `workflows.json`
- `memory_scopes.json`
- `jobs.json`
- `review_queue.json`
- `generated_docs.json`
- `provider_status.json`
- `parser_backend_status.json`
- `parser_backends/parser_backend_matrix.json`
- `answer_policies.json`

Required concepts:

- Multiple knowledge bases, with both `draft` and `trusted` status.
- Multiple agents, including Agent-to-KB binding.
- Different model providers and model status.
- Answer policy modes.
- Parser backend status derived from Core v4.1.0 evidence, including install mode, stable surface, evidence path, known limitations, and no static executable claim.
- Review queue risks.
- Generated documents and export items.
- Multi-agent workflow, workflow shared memory, handoff trace.
- Agent private memory isolation.

## Future API Integration

`web/workbench/src/mockService.js` is the reserved service boundary. Future Core integration should replace JSON fetches with API calls that return the same view-model fields:

- `knowledgeBases`
- `agents`
- `workflows`
- `memoryScopes`
- `jobs`
- `reviewItems`
- `generatedDocs`
- `exportItems`
- `providers`
- `parserBackends`
- `parserBackendMatrix`
- `answerPolicies`
- `memoryPolicies`

No page should import parser, RAG, document generation, agent orchestration, or memory runtime modules directly.
