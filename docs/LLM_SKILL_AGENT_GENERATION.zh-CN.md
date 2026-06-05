# LLM Skill 与 Agent 生成

v1.8 可以可选使用 mock 或已配置的 LLM provider 辅助生成 Skill 和 Agent Package。

LLM 生成必须显式开启：

```powershell
python -m heitang_kb_forge.cli generate-skill --package .\tmp_v18_package --output .\tmp_v18_skill_llm --skill-name "Demo Knowledge Skill" --llm --llm-provider mock --llm-skill-generation
python -m heitang_kb_forge.cli generate-agent --package .\tmp_v18_package --skill .\tmp_v18_skill_llm --output .\tmp_v18_agent_llm --agent-name "Demo Knowledge Agent" --llm --llm-provider mock --llm-agent-generation
```

LLM 不能替代证据链，也不能脱离知识包范围自由发挥。provider 配置失败时会 fallback 到规则模板。API key 会从 call log 中脱敏。
