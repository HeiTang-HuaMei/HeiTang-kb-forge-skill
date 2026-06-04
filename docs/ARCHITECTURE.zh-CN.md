# 架构

## Skill-first 架构

HeiTang KB Forge 首先是 Agent 知识供应链 Skill。桌面 UI 只是表现层。

```text
Core Skill / Python package
> CLI
> Config / Pipeline
> Agent-callable skill interface
> Desktop UI
```

## v1.6 多模态与 Contract 层

```text
source files
-> text package
-> multimodal_assets.jsonl
-> multimodal_evidence_map.json
-> Contract v2 files
-> contract checker
```

该层用于保留证据、标记需要人工复核的资产，并让输出结构可被后续 Skill / Agent 检查。它不是视觉理解模型，也不会把低置信 fallback 内容声明为原文事实。
