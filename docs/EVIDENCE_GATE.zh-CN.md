# 证据门

v1.7 新增可选 Evidence Gate，用于判断问题是否被知识包证据支持。

```powershell
python -m heitang_kb_forge.cli evidence-gate --package .\output --query "这个知识包主要讲什么？" --output .\gate_output
```

决策：

* allow
* refuse
* needs_review

输出：

* evidence_gate_result.json
* evidence_gate_report.md

Evidence Gate 是本地证据优先能力。可选 mock LLM 校验可用于测试，不需要联网。
