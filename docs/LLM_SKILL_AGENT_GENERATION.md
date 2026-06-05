# LLM Skill and Agent Generation

v1.8 can optionally use a mock or configured LLM provider to assist Skill and Agent package generation.

LLM generation is opt-in:

```powershell
python -m heitang_kb_forge.cli generate-skill --package .\tmp_v18_package --output .\tmp_v18_skill_llm --skill-name "Demo Knowledge Skill" --llm --llm-provider mock --llm-skill-generation
python -m heitang_kb_forge.cli generate-agent --package .\tmp_v18_package --skill .\tmp_v18_skill_llm --output .\tmp_v18_agent_llm --agent-name "Demo Knowledge Agent" --llm --llm-provider mock --llm-agent-generation
```

The LLM cannot replace evidence chains and cannot freely invent package scope. If provider setup fails, generation falls back to rule templates. API keys are redacted from call logs.
