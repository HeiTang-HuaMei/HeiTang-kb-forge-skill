# Post-v4 外部项目路线

v4.0 后排序规则：强化功能优先，加强体验第二，生态拓展后置。也就是：function strengthening first, experience second, ecosystem later。

附加规则：

1. 每版最多吸收 2 个 S/A 方向。
2. 不一次性实现多个 S 级大系统。
3. 外部项目以融合能力为主，不完整搬运。
4. provider、network、external runtime 能力必须要求显式用户配置。
5. 本路线不启动 v4.0、不打 tag、不写 release。

## 建议路线

| 阶段 | 重点 | 边界 |
| --- | --- | --- |
| P2.1 | External Project Verification Baseline + Parser/OCR Multi-Backend Integration | verification baseline closed；Docling / PaddleOCR / Unstructured optional runtime adapters |
| P2.2 | Skill Governance + Book-to-Skill Deepening | andrej-karpathy-skills；skill-prompt-generator；Book-to-Skill / Software-to-Manual-to-Skill |
| P2.3 | Parser/OCR Backend Hardening | MinerU；Marker；Surya；OpenDataLoader；optional runtime adapters acceptance hardening |
| P2.4 | Living Knowledge Base / Memory Lifecycle | LLM Wiki v2；memory lifecycle / confidence / forgetting / decay |
| P2.5 | Auto Wiki + RAG Evaluation | WeKnora；LlamaIndex / RAGAS / DeepEval |
| P2.6 | Industry Template Library + AIGC Book Pipeline | ai-marketing-skills；ai-money-maker-handbook；AIGC Book Content Pipeline |
| P2.7 | n8n Workflow Export Adapter | n8n；workflow export / webhook template；no bundled runtime |
| P2.8 | External Retrieval Provider | AnySearchSkill；last30days-skill；provider_required / network_required |
| P2.9 | Multimodal / Short Drama / Video Skill Pipeline | MMSkills；Jellyfish；story-flicks；seedance2-skill |
| P3.x | Ecosystem & Automation Layer | deeper n8n integration；external automation provider registry；Feishu / Notion / GitHub / Slack / Telegram optional integrations；workflow canvas；BYO cloud / sync |
| P4.x | SaaS / Team / Commercialization | team workspace；permission model；hosted control plane；plugin ecosystem；commercial packaging |
