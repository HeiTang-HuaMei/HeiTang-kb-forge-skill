# 知识治理

v1.7 新增可选知识治理能力，用于分析已有 HeiTang KB Forge 知识包。

它会生成 package diff、生命周期状态、冲突检测、过期检测、review queue 和治理报告。

```powershell
python -m heitang_kb_forge.cli govern --package .\output --output .\governance_output
```

输出：

* package_diff.json
* package_diff_report.md
* lifecycle_manifest.json
* lifecycle_report.md
* conflict_report.json
* conflict_report.md
* staleness_report.json
* staleness_report.md
* review_queue.jsonl
* review_queue_report.md
* governance_report.md

该层是本地规则能力，不调用 LLM，也不连接向量数据库。
