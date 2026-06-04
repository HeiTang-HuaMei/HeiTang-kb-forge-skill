# Knowledge Package Contract v2

Contract v2 让知识包结构可以被下游 Skill、RAG pipeline 和 Agent workflow 检查。

## 构建时启用

```powershell
heitang-kb-forge build --input .\input --output .\output --contract-version v2 --check-contract
```

## 检查已有知识包

```powershell
heitang-kb-forge check-contract --package .\output --contract-version v2
```

## Contract 输出

- `evidence_map.json`
- `source_inventory.json`
- `quality_report.md`
- `contract_check_result.json`
- `contract_check_report.md`

## 状态含义

- `pass`：必需文件存在，核心结构可读取。
- `warning`：部分可选 v2 字段不完整，但知识包可读取。
- `fail`：必需文件缺失，或核心 JSON / JSONL 文件不可读取。

Contract v2 是 opt-in，不强制旧知识包迁移。
