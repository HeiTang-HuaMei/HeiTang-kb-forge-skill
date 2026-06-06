# Agent and Knowledge Base Answer Policy

## 1. Design Decision

In HeiTang Knowledge Workbench, the knowledge base is not the entire brain of an Agent. It is the trusted evidence layer.

The system must support multiple answer policies instead of hardcoding a single behavior.

Supported policies:

```yaml
answer_policy: strict_grounded | knowledge_first | creative_grounded | open
```

Recommended default:

```yaml
answer_policy: knowledge_first
require_citation_for_domain_facts: true
allow_external_knowledge: true
disclose_external_knowledge: true
refuse_when_no_evidence: configurable
```

## 2. Relationship Between Agent, KB, and LLM

### Agent

The Agent is responsible for:

- understanding the user query
- deciding whether retrieval is needed
- calling retrieval tools
- selecting evidence
- deciding whether the answer is safe
- composing the response
- citing sources
- refusing uncertain answers
- calling document generation or Skill generation tools

### Knowledge Base

The knowledge base is responsible for:

- trusted facts
- source evidence
- domain boundaries
- traceable materials
- hallucination reduction

### LLM

The LLM is responsible for:

- language understanding
- summarization
- formatting
- document generation
- structured generation
- optional general knowledge when allowed

## 3. Answer Policies

### strict_grounded

Use only knowledge-base evidence.

Best for:

- compliance
- legal, medical, financial, or policy content
- textbooks
- customer service
- publisher knowledge services

Rules:

- answer only with KB evidence
- refuse when there is no evidence
- no general model knowledge
- citations are required

### knowledge_first

Use KB first, then optional general model knowledge.

Best for:

- personal knowledge bases
- product manager knowledge
- learning assistants
- internal knowledge assistants
- content operation libraries

Rules:

- retrieve KB first
- answer from KB when evidence exists
- allow model supplement when KB is missing
- clearly label non-KB content

### creative_grounded

Use KB as grounded material for creation.

Best for:

- reports
- slides
- articles
- proposals
- teaching materials

Rules:

- facts must be grounded
- style and structure may be generated
- evidence appendix is required for domain claims

### open

Use KB as optional reference.

Best for:

- brainstorming
- creative tasks
- open-ended discussion

Rules:

- KB is optional reference
- model can use general capabilities
- if user asks about KB facts, KB takes priority

## 4. Default Policy

Default policy should be:

```yaml
answer_policy: knowledge_first
```

This keeps the knowledge base as the trusted source while preserving useful model capability.

## 5. High-Risk Policy

High-risk scenarios must use:

```yaml
answer_policy: strict_grounded
```

Examples:

- compliance
- legal
- medical
- financial
- textbook answer keys
- customer service promises
- internal procedures

## 6. Required Agent Configuration

Knowledge-bound Agent / Skill packages must include answer policy fields.

Example:

```json
{
  "answer_policy": "knowledge_first",
  "knowledge_base_required": true,
  "require_citation_for_domain_facts": true,
  "allow_external_knowledge": true,
  "disclose_external_knowledge": true,
  "refuse_when_no_evidence": false
}
```

Strict mode:

```json
{
  "answer_policy": "strict_grounded",
  "knowledge_base_required": true,
  "require_citation_for_domain_facts": true,
  "allow_external_knowledge": false,
  "refuse_when_no_evidence": true
}
```

## 7. Release Gate Requirements

Future release-readiness checks should verify:

- answer_policy exists
- strict_grounded disables external knowledge
- domain facts require citations
- refusal policy exists
- external knowledge disclosure exists
- answer policy smoke tests exist

## 8. Implementation Roadmap

### v2.9 Knowledge Runtime Loop

- kb-answer --answer-policy
- citation required mode
- low-confidence refusal
- external knowledge disclosure

### v3.1 Knowledge-Bound Agent / Skill Factory

- write answer_policy into Agent / Skill packages
- bind evidence policy
- bind refusal policy
- run answer policy smoke tests

### v3.2 Skill Reverse & Fusion

- detect imported Skill answer_policy
- flag unsafe answer behavior
- rewrite fused Skill answer_policy
